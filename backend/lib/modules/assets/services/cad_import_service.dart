import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/cad_import_job.dart';
import '../models/floor.dart';
import '../repositories/building_repository.dart';
import '../repositories/cad_import_job_repository.dart';
import '../repositories/floor_repository.dart';
import '../repositories/unit_repository.dart';

/// CadImportService — 楼栋级 DXF 上传 + 异步切分 + 楼层匹配的核心服务。
///
/// 流程：
///   1. 上传 DXF → 落盘 cad/{buildingId}/{jobId}.dxf
///   2. 创建 cad_import_jobs 记录（status='uploaded'）
///   3. 立即返回任务 ID，后台异步运行 `python3 split_dxf_by_floor.py`
///   4. 切分输出 SVG → 自动匹配 floors 表 → 已匹配 SVG 复制到 floors/{buildingId}/{floorId}.svg
///   5. 创建 floor_plans 记录并设为 current；未匹配 SVG 写入 unmatched_svgs
///
/// 安全约束：
///   - 仅接收 .dxf 扩展名（不接收 DWG，方案决议见 PROJECT_PLAN Day 14）
///   - 所有文件路径在 _fileStoragePath 沙箱内，禁止 `..` 穿越
///   - 切分脚本进程隔离，超时 5 分钟兜底
class CadImportService {
  final Pool _db;
  final String _fileStoragePath;
  /// 切分脚本绝对路径，由部署环境注入（容器内默认 /app/scripts/split_dxf_by_floor.py）
  final String _splitScriptPath;
  /// 热区标注脚本绝对路径，由部署环境注入（容器内默认 /app/scripts/annotate_hotzone.py）
  final String _annotateScriptPath;
  /// Python 解释器路径，默认 python3
  final String _pythonExecutable;
  /// PostgreSQL 连接串，切分脚本写入 floor_maps.candidates 时使用
  final String _databaseUrl;

  CadImportService(
    this._db,
    this._fileStoragePath, {
    String? splitScriptPath,
    String? annotateScriptPath,
    String? pythonExecutable,
    String? databaseUrl,
  })  : _splitScriptPath =
            splitScriptPath ?? '/app/scripts/split_dxf_by_floor.py',
        _annotateScriptPath =
            annotateScriptPath ?? '/app/scripts/annotate_hotzone.py',
        _pythonExecutable = pythonExecutable ?? 'python3',
        _databaseUrl = databaseUrl ?? '';

  // ─── 公开 API ──────────────────────────────────────────────────────────

  /// 上传 DXF 并启动异步切分任务，立即返回任务记录。
  ///
  /// 校验：
  ///   - 楼栋必须存在
  ///   - 文件扩展名必须是 .dxf（大小写不敏感）
  ///   - 文件大小由 Controller 上层 multipart parser + AppConfig.maxUploadSizeMb 限制
  Future<CadImportJob> uploadDxf({
    required String buildingId,
    required List<int> fileBytes,
    required String originalFilename,
    String? createdBy,
  }) async {
    // 校验楼栋存在
    final building = await BuildingRepository(_db).findById(buildingId);
    if (building == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }

    // 校验扩展名
    final ext = p.extension(originalFilename).toLowerCase();
    if (ext != '.dxf') {
      throw const ValidationException(
          'INVALID_CAD_FILE', '只接受 .dxf 格式文件，请先在 CAD 软件中另存为 DXF 后再上传');
    }

    // 校验文件头（magic bytes）：DXF 是纯文本格式，含非打印控制字符则判定为二进制（如 DWG）
    _validateDxfMagic(fileBytes);

    // 创建任务记录（先得到 jobId 才能确定 dxf_path 命名）
    // 用临时 dxf_path 占位，落盘后立即更新
    final repo = CadImportJobRepository(_db);
    final tmpJob = await repo.create(
      buildingId: buildingId,
      dxfPath: 'pending',
      prefix: _derivePrefix(originalFilename, building.name),
      createdBy: createdBy,
    );

    // DXF 落盘：cad/{buildingId}/{jobId}.dxf
    final dxfRel = _joinRel(['cad', buildingId, '${tmpJob.id}.dxf']);
    final dxfAbs = _resolveSafe(dxfRel);
    await Directory(p.dirname(dxfAbs)).create(recursive: true);
    await File(dxfAbs).writeAsBytes(Uint8List.fromList(fileBytes));

    // 用真实 dxf_path 更新任务（仍在 uploaded 状态）
    await _db.execute(
      Sql.named('UPDATE cad_import_jobs SET dxf_path = @path WHERE id = @id'),
      parameters: {'id': tmpJob.id, 'path': dxfRel},
    );

    // 异步启动切分（fire-and-forget）
    unawaited(_runSplit(tmpJob.id));

    // 返回最新任务记录
    return (await repo.findById(tmpJob.id))!;
  }

  /// 查询任务状态（轮询接口）
  Future<CadImportJob> getJob(String id) async {
    final job = await CadImportJobRepository(_db).findById(id);
    if (job == null) {
      throw const NotFoundException('CAD_IMPORT_JOB_NOT_FOUND', '导入任务不存在');
    }
    return job;
  }

  /// 管理员手动将一个 unmatched SVG 指派到具体楼层。
  /// 校验：楼层必须属于同一栋楼；SVG 文件必须位于该任务的 unmatched_svgs 列表中。
  Future<CadImportJob> assignUnmatched(
    String jobId, {
    required String svgLabel,
    required String floorId,
  }) async {
    final repo = CadImportJobRepository(_db);
    final job = await repo.findById(jobId);
    if (job == null) {
      throw const NotFoundException('CAD_IMPORT_JOB_NOT_FOUND', '导入任务不存在');
    }
    if (job.status != 'done') {
      throw const ValidationException(
          'CAD_IMPORT_JOB_NOT_DONE', '仅当任务已完成切分后才能手动指派楼层');
    }

    // 楼层必须存在且属于同一栋楼
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    if (floor.buildingId != job.buildingId) {
      throw const ValidationException(
          'FLOOR_BUILDING_MISMATCH', '楼层不属于该任务对应的楼栋');
    }

    // 找到对应未匹配 SVG
    final target = job.unmatchedSvgs
        .where((e) => e.label == svgLabel)
        .toList(growable: false);
    if (target.isEmpty) {
      throw const NotFoundException(
          'UNMATCHED_SVG_NOT_FOUND', '指定的 SVG 文件不在未匹配列表中');
    }
    final svg = target.first;

    // 复制 SVG 到正式路径并创建 floor_plan
    await _attachSvgToFloor(
      tmpRel: svg.tmpPath,
      floor: floor,
      versionLabel: '导入指派 - ${svg.label}',
      uploadedBy: job.createdBy,
    );

    // 从 unmatched_svgs 中移除
    final remaining = job.unmatchedSvgs
        .where((e) => e.label != svgLabel)
        .toList(growable: false);
    await repo.updateAssignments(
      jobId,
      matchedCount: job.matchedCount + 1,
      unmatchedSvgs: remaining,
    );

    return (await repo.findById(jobId))!;
  }

  // ─── 异步切分主流程 ───────────────────────────────────────────────────

  /// 后台执行切分；任何异常都将状态置为 failed 并记录原因，绝不向上层抛出
  Future<void> _runSplit(String jobId) async {
    final repo = CadImportJobRepository(_db);
    try {
      final job = await repo.findById(jobId);
      if (job == null) return;

      await repo.updateStatus(jobId, 'splitting');

      // 输出目录：cad/{buildingId}/jobs/{jobId}/
      final outRel =
          _joinRel(['cad', job.buildingId, 'jobs', jobId]);
      final outAbs = _resolveSafe(outRel);
      await Directory(outAbs).create(recursive: true);

      final dxfAbs = _resolveSafe(job.dxfPath);

      // 构建切分参数：始终附带 --extract-structures，有 DB URL 时写入 floor_maps.candidates
      final splitArgs = <String>[
        _splitScriptPath,
        dxfAbs,
        outAbs,
        '--prefix',
        job.prefix,
        '--extract-structures',
      ];
      if (_databaseUrl.isNotEmpty) {
        splitArgs.addAll(['--db-url', _databaseUrl]);
      }

      final result = await Process.run(
        _pythonExecutable,
        splitArgs,
        runInShell: false,
      ).timeout(const Duration(minutes: 8));

      if (result.exitCode != 0) {
        await repo.updateResult(
          jobId,
          status: 'failed',
          matchedCount: 0,
          unmatchedSvgs: const [],
          errorMessage:
              'split_dxf 退出码 ${result.exitCode}: ${_truncate(result.stderr.toString())}',
        );
        return;
      }

      // 热区标注：在切分输出目录运行 annotate_hotzone.py
      // 失败时仅记录警告，不阻断主流程（SVG 不带热区也可用）
      if (await File(_annotateScriptPath).exists()) {
        final annotateResult = await Process.run(
          _pythonExecutable,
          [
            _annotateScriptPath,
            dxfAbs,
            outAbs,
            '--prefix',
            job.prefix,
          ],
          runInShell: false,
        ).timeout(const Duration(minutes: 3));
        if (annotateResult.exitCode != 0) {
          // 标注失败不阻断切分结果处理，仅记录日志
          print('[CadImportService] 热区标注警告 (jobId=$jobId): '
              '${_truncate(annotateResult.stderr.toString())}');
        }
      } else {
        // 脚本文件不存在（本地开发未设置 ANNOTATE_SCRIPT_PATH）：跳过标注
        // 后果：JSON units 为空 → 各楼层不自动创建 Unit 记录
        // 解决：在 .env 中设置 ANNOTATE_SCRIPT_PATH 指向本地脚本路径
        print('[CadImportService] 跳过热区标注：'
            'ANNOTATE_SCRIPT_PATH=$_annotateScriptPath 文件不存在。'
            '如需自动创建房间，请在 .env 中配置正确的脚本路径。');
      }

      // 扫描输出 SVG 并尝试匹配
      final svgFiles = await Directory(outAbs)
          .list()
          .where((e) => e is File && e.path.toLowerCase().endsWith('.svg'))
          .cast<File>()
          .toList();

      if (svgFiles.isEmpty) {
        await repo.updateResult(
          jobId,
          status: 'failed',
          matchedCount: 0,
          unmatchedSvgs: const [],
          errorMessage: '切分脚本未生成任何 SVG，请检查 DXF 内容是否包含「X 层平面图」标题文字',
        );
        return;
      }

      final floors = await FloorRepository(_db)
          .findAll(buildingId: job.buildingId);

      var matched = 0;
      final unmatched = <UnmatchedSvg>[];

      for (final svg in svgFiles) {
        final filename = p.basename(svg.path);
        final label = _extractLabel(filename, job.prefix);
        if (label == null) {
          // 文件名不符合 <prefix>_<label>.svg 格式，按未匹配处理
          unmatched.add(UnmatchedSvg(
            label: p.basenameWithoutExtension(filename),
            tmpPath: p.join(outRel, filename),
          ));
          continue;
        }

        final targets = _matchFloors(label, floors);
        if (targets.isEmpty) {
          unmatched.add(UnmatchedSvg(
            label: label,
            tmpPath: p.join(outRel, filename),
          ));
          continue;
        }

        // 已匹配：复制 SVG 到每个楼层正式路径并创建 floor_plan
        final svgBytes = await svg.readAsBytes();
        // 查找同名 .json 骨架文件（Python 脚本生成的元数据）
        final jsonSibling = File('${p.withoutExtension(svg.path)}.json');
        final hasJson = await jsonSibling.exists();
        // 版本标签含导入时间，方便在版本历史中区分多次重复导入
        final ts = job.createdAt.toLocal();
        final tsStr =
            '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
        for (final floor in targets) {
          await _writeAndAttach(
            floor: floor,
            svgBytes: svgBytes,
            versionLabel: '自动导入 - $label ($tsStr)',
            uploadedBy: job.createdBy,
            jsonSiblingFile: hasJson ? jsonSibling : null,
          );
          matched++;
        }
      }

      await repo.updateResult(
        jobId,
        status: 'done',
        matchedCount: matched,
        unmatchedSvgs: unmatched,
      );
    } on TimeoutException {
      await repo.updateResult(
        jobId,
        status: 'failed',
        matchedCount: 0,
        unmatchedSvgs: const [],
        errorMessage: '切分超时（>5 分钟），请检查 DXF 文件是否过大或损坏',
      );
    } catch (e) {
      await repo.updateResult(
        jobId,
        status: 'failed',
        matchedCount: 0,
        unmatchedSvgs: const [],
        errorMessage: _truncate(e.toString()),
      );
    }
  }

  // ─── 辅助：路径处理 ─────────────────────────────────────────────────────

  /// 将相对路径解析到 _fileStoragePath 内的绝对路径，禁止 `..` 穿越
  String _resolveSafe(String relPath) {
    final normalized = p.normalize(relPath);
    if (p.isAbsolute(normalized) ||
        normalized.startsWith('..') ||
        normalized.contains('${p.separator}..${p.separator}')) {
      throw const ValidationException('INVALID_FILE_PATH', '非法文件路径');
    }
    final abs = p.normalize(p.join(_fileStoragePath, normalized));
    if (!p.isWithin(_fileStoragePath, abs)) {
      throw const ValidationException('INVALID_FILE_PATH', '非法文件路径');
    }
    return abs;
  }

  /// 拼接相对路径，保持正斜杠分隔（与 DB 中存储格式一致）
  String _joinRel(List<String> parts) =>
      parts.where((e) => e.isNotEmpty).join('/');

  /// 校验 DXF magic bytes：DXF 为纯文本（ASCII/UTF-8），二进制文件（DWG 等）将被拒绝。
  ///
  /// 规则：
  ///   1. 前 512 字节不得含非打印控制字符（允许 TAB/LF/CR）
  ///   2. 前 512 字节内必须出现 "SECTION" 关键字（DXF 结构标志）
  void _validateDxfMagic(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const ValidationException('INVALID_CAD_FILE', '文件为空');
    }
    final header = bytes.length > 512 ? bytes.sublist(0, 512) : bytes;
    // 允许 TAB(9) LF(10) CR(13)，其余 < 32 的控制字符及 DEL(127) 视为二进制标志
    final nonPrintCount = header
        .where((b) =>
            b < 9 || b == 11 || b == 12 || (b > 13 && b < 32) || b == 127)
        .length;
    if (nonPrintCount > 0) {
      throw const ValidationException(
          'INVALID_CAD_FILE',
          'DXF 文件为纯文本格式，检测到二进制内容（请勿上传 DWG 格式，应另存为 DXF 后重新上传）');
    }
    // DXF 结构校验：前 512 字节内必须出现 SECTION 关键字
    final headerStr = String.fromCharCodes(header);
    if (!headerStr.contains('SECTION')) {
      throw const ValidationException(
          'INVALID_CAD_FILE', '文件内容不符合 DXF 格式（缺少 SECTION 结构标记，请确认文件为标准 DXF）');
    }
  }

  // ─── 辅助：文件名 / 楼层匹配 ─────────────────────────────────────────────

  /// 从原始上传文件名推断 SVG 输出前缀（去掉扩展名 + 非法字符替换）
  String _derivePrefix(String filename, String fallback) {
    var base = p.basenameWithoutExtension(filename).trim();
    if (base.isEmpty) base = fallback;
    base = base.replaceAll(RegExp(r'[\s/\\]+'), '_');
    if (base.length > 80) base = base.substring(0, 80);
    return base;
  }

  /// 从切分输出文件名 `<prefix>_<label>.svg` 提取 label，匹配失败返回 null
  String? _extractLabel(String filename, String prefix) {
    final base = p.basenameWithoutExtension(filename);
    final expected = '${prefix}_';
    if (!base.startsWith(expected)) return null;
    final label = base.substring(expected.length);
    return label.isEmpty ? null : label;
  }

  /// 将 label 解析为目标楼层列表
  ///
  /// 规则（从严到宽）：
  ///   1. 整体匹配 floor_name（如 `屋顶`、`M层`、`F-1`）
  ///   2. 整体匹配 `F\d+` → floor_number = N
  ///   3. 整体匹配 `B\d+` → floor_number = -N（地下层）
  ///   4. 多楼层合并：按 `-` 拆分，每段必须能解析为单一楼层号；任何一段失败则整体不匹配
  List<Floor> _matchFloors(String label, List<Floor> floors) {
    // Step 1: 直接命名匹配
    final byName = floors.where((f) => f.floorName == label).toList();
    if (byName.isNotEmpty) return byName;

    // Step 2/3: 单段楼层号匹配
    final single = _parseFloorNumber(label);
    if (single != null) {
      return floors.where((f) => f.floorNumber == single).toList();
    }

    // Step 4: 多楼层合并（F6-F8-F10）
    if (label.contains('-')) {
      final parts = label.split('-');
      final numbers = <int>[];
      for (final part in parts) {
        final n = _parseFloorNumber(part);
        if (n == null) return const [];
        numbers.add(n);
      }
      return floors.where((f) => numbers.contains(f.floorNumber)).toList();
    }
    return const [];
  }

  /// 将 `F11` / `B1` 等单段标识解析为 floor_number（返回 null 表示无法解析）
  int? _parseFloorNumber(String token) {
    final upper = token.toUpperCase();
    final mF = RegExp(r'^F(\d+)$').firstMatch(upper);
    if (mF != null) return int.parse(mF.group(1)!);
    final mB = RegExp(r'^B(\d+)$').firstMatch(upper);
    if (mB != null) return -int.parse(mB.group(1)!);
    return null;
  }

  // ─── 辅助：写入 floor_plan ────────────────────────────────────────────

  /// 已知 SVG 内容字节流，写入楼层正式路径并创建 floor_plan 记录（设为 current）。
  /// 若提供 [jsonSiblingFile]，匹配成功后回写 floor_id / building_id / svg_version。
  Future<void> _writeAndAttach({
    required Floor floor,
    required List<int> svgBytes,
    required String versionLabel,
    String? uploadedBy,
    File? jsonSiblingFile,
  }) async {
    final svgRel = _joinRel(['floors', floor.buildingId, '${floor.id}.svg']);
    final svgAbs = _resolveSafe(svgRel);
    await Directory(p.dirname(svgAbs)).create(recursive: true);
    await File(svgAbs).writeAsBytes(Uint8List.fromList(svgBytes));

    final repo = FloorRepository(_db);
    final plan = await repo.createPlan(
      floorId: floor.id,
      versionLabel: versionLabel,
      svgPath: svgRel,
      isCurrent: false,
      uploadedBy: uploadedBy,
    );
    await repo.setCurrentPlan(plan.id);

    // 回写 JSON 骨架：填入真实 floor_id / building_id / svg_version，并提取 units 数据
    if (jsonSiblingFile != null) {
      try {
        final raw = await jsonSiblingFile.readAsString();
        final meta = jsonDecode(raw) as Map<String, dynamic>;
        meta['floor_id'] = floor.id;
        meta['building_id'] = floor.buildingId;
        meta['svg_version'] = plan.id;
        final jsonRel = _joinRel(['floors', floor.buildingId, '${floor.id}.json']);
        final jsonAbs = _resolveSafe(jsonRel);
        await File(jsonAbs).writeAsString(
          const JsonEncoder.withIndent('  ').convert(meta),
        );

        // 从 JSON units 数组自动创建楼层房间记录
        final rawUnits = meta['units'];
        if (rawUnits is List && rawUnits.isNotEmpty) {
          final building =
              await BuildingRepository(_db).findById(floor.buildingId);
          if (building != null) {
            final created = await _createUnitsFromJsonData(
              floor: floor,
              propertyType: building.propertyType,
              units: rawUnits,
            );
            print(
              '[CadImportService] 楼层 ${floor.id}（${floor.floorName}）'
              '新增 $created 个 Unit（共 ${rawUnits.length} 条，已有编号自动跳过/回填面积）',
            );
          }
        }
      } catch (_) {
        // JSON 处理失败不阻断主流程
      }
    }
  }

  /// 给定临时路径下的 SVG，复制到楼层正式路径并创建 floor_plan。
  /// 同时尝试读取同名 .json 兄弟文件，存在时触发 Unit 自动创建。
  Future<void> _attachSvgToFloor({
    required String tmpRel,
    required Floor floor,
    required String versionLabel,
    String? uploadedBy,
  }) async {
    final tmpAbs = _resolveSafe(tmpRel);
    final tmpFile = File(tmpAbs);
    if (!await tmpFile.exists()) {
      throw const NotFoundException(
          'UNMATCHED_SVG_FILE_LOST', '原始 SVG 文件不存在或已被清理');
    }
    final bytes = await tmpFile.readAsBytes();
    // 查找与 SVG 同名的 JSON 骨架文件（annotate_hotzone.py 生成）
    final jsonSibling = File('${p.withoutExtension(tmpAbs)}.json');
    await _writeAndAttach(
      floor: floor,
      svgBytes: bytes,
      versionLabel: versionLabel,
      uploadedBy: uploadedBy,
      jsonSiblingFile: await jsonSibling.exists() ? jsonSibling : null,
    );
  }

  // ─── 辅助：DXF Unit 自动创建 ─────────────────────────────────────────

  /// 从 annotate_hotzone.py 生成的 JSON units 数组批量创建 Unit 记录。
  ///
  /// 策略：按 (building_id, unit_number) 查重，仅补充新增，跳过已有编号（保护现有数据）。
  ///
  /// unit_number 由当前楼层的真实 floorNumber 重新推导，而非直接使用 JSON 的 unit_id：
  ///   - 多楼层共用同一 SVG 时（如 F20-F22），annotate_hotzone.py 会将前缀拼接为 "2022"，
  ///     导致 unit_id 为 "2022-01"，逐楼层分别创建时必须替换为各自的编号（"20-01"/"22-01"）。
  ///   - unit_id 格式：<floor_prefix>-<room_seq> 或纯 <room_seq>（无楼层前缀时）。
  ///   - 推导规则：取 unit_id 首个连字符后的 room_seq，前缀替换为 floor.floorNumber：
  ///       正楼层 → "<floorNumber>-<room_seq>"
  ///       地下层 → "B<abs(floorNumber)>-<room_seq>"
  ///
  /// 单条异常隔离：单个 unit 创建失败不中断整批。
  ///
  /// 返回实际创建的数量。
  Future<int> _createUnitsFromJsonData({
    required Floor floor,
    required String propertyType,
    required List<dynamic> units,
  }) async {
    // 多楼层共用 SVG 时，JSON 的 floor_prefix 可能包含多个楼层号（如 "2022"），
    // 必须按当前楼层 floorNumber 重新生成 unit_number。
    String deriveUnitNumber(String rawUnitId) {
      final dashIdx = rawUnitId.indexOf('-');
      // 首个连字符后为 room_seq（若无连字符则整体作为 room_seq）
      final roomSeq =
          dashIdx >= 0 ? rawUnitId.substring(dashIdx + 1) : rawUnitId;
      final floorPrefix = floor.floorNumber < 0
          ? 'B${floor.floorNumber.abs()}'
          : '${floor.floorNumber}';
      return '$floorPrefix-$roomSeq';
    }

    // 过滤有效 unit 条目
    final unitMaps = units
        .whereType<Map<String, dynamic>>()
        .where((u) => (u['unit_id'] as String? ?? '').trim().isNotEmpty)
        .toList(growable: false);

    if (unitMaps.isEmpty) return 0;

    // 候选 unit_number 基于当前楼层真实编号（而非 JSON 原始 unit_id）
    final candidates = unitMaps
        .map((u) => deriveUnitNumber((u['unit_id'] as String).trim()))
        .toList(growable: false);

    final unitRepo = UnitRepository(_db);
    // 查重：获取已存在的 unit_number 集合
    final existing = await unitRepo.findExistingUnitNumbers(
      floor.buildingId,
      candidates,
    );

    var created = 0;
    var updated = 0; // 已存在但 gross_area 为 null → 本次回填
    for (final u in unitMaps) {
      final rawUnitId = (u['unit_id'] as String).trim();
      final unitNumber = deriveUnitNumber(rawUnitId);

      // 从 JSON 提取面积（gross_area 口径）
      final areaRaw = u['area_m2'];
      final grossArea = areaRaw is num ? areaRaw.toDouble() : null;

      if (existing.contains(unitNumber)) {
        // 已存在：仅在面积有值且数据库当前为 null 时回填（保护手动修正的非空值）
        if (grossArea != null) {
          try {
            final rows = await unitRepo.updateGrossAreaIfNull(
              floor.buildingId,
              unitNumber,
              grossArea,
            );
            updated += rows;
          } catch (e) {
            print(
              '[CadImportService] gross_area 回填失败（unitNumber=$unitNumber）：$e',
            );
          }
        }
        continue;
      }

      try {
        // 构建 ext_fields：保存房间名称与 SVG 热区坐标，供楼层地图交互使用
        final extFields = <String, dynamic>{};
        final roomName = u['room_name'] as String? ?? '';
        if (roomName.isNotEmpty) extFields['room_name'] = roomName;
        final hotspot = u['hotspot'];
        if (hotspot != null) extFields['hotspot'] = hotspot;

        await unitRepo.create(
          floorId: floor.id,
          buildingId: floor.buildingId,
          unitNumber: unitNumber,
          propertyType: propertyType,
          grossArea: grossArea,
          extFields: extFields.isEmpty ? null : extFields,
        );
        created++;
      } catch (e) {
        // 单条创建失败不中断整批，仅记录日志
        print('[CadImportService] Unit 创建失败（unitNumber=$unitNumber）：$e');
      }
    }
    if (updated > 0) {
      print(
        '[CadImportService] 面积回填：$updated 个已有 Unit 的 gross_area 由 null 更新为 DXF 标注值',
      );
    }
    return created;
  }

  // ─── 辅助：错误信息截断 ────────────────────────────────────────────────

  String _truncate(String s, {int max = 500}) =>
      s.length > max ? '${s.substring(0, max)}…(已截断)' : s;
}
