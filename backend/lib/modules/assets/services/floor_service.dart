import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/floor.dart';
import '../models/floor_map.dart';
import '../models/floor_plan.dart';
import '../repositories/building_repository.dart';
import '../repositories/floor_map_repository.dart';
import '../repositories/floor_repository.dart';

/// FloorService — 楼层与楼层图纸版本管理业务逻辑。
///
/// 约束：
///   1. CAD 上传后异步触发转换（Phase 1 仅存储原始文件，标记 converting 状态）
///   2. set-current 操作需同步更新 floors.svg_path / png_path
///   3. 楼层创建前校验楼栋是否存在
class FloorService {
  final Pool _db;
  final String _fileStoragePath;

  FloorService(this._db, this._fileStoragePath);

  // ─── floors ─────────────────────────────────────────────────────────────

  Future<List<Floor>> listFloors({String? buildingId}) async {
    return FloorRepository(_db).findAll(buildingId: buildingId);
  }

  Future<Floor> getFloor(String id) async {
    final floor = await FloorRepository(_db).findById(id);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return floor;
  }

  Future<Floor> createFloor({
    required String buildingId,
    required int floorNumber,
    String? floorName,
    double? nla,
    String? propertyType,
  }) async {
    // 校验楼栋存在
    final building = await BuildingRepository(_db).findById(buildingId);
    if (building == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    // 非混合体楼栋：忽略传入的 propertyType，自动继承楼栋业态
    // 混合体楼栋：使用传入值（可为 null，代表待定）
    final resolvedPropertyType =
        building.propertyType != 'mixed' ? building.propertyType : propertyType;
    // 校验同楼栋楼层号唯一
    final exists = await FloorRepository(_db)
        .existsByBuildingAndNumber(buildingId, floorNumber);
    if (exists) {
      throw const ConflictException(
          'FLOOR_ALREADY_EXISTS', '该楼栋下此楼层号已存在');
    }
    return FloorRepository(_db).create(
      buildingId: buildingId,
      floorNumber: floorNumber,
      floorName: floorName,
      nla: nla,
      propertyType: resolvedPropertyType,
    );
  }

  /// 更新楼层属性；若 propertyType 有变化则同事务级联更新该楼层所有未归档单元。
  /// 返回 ({floor, updatedUnitCount})。
  Future<({Floor floor, int updatedUnitCount})> patchFloor(
    String id, {
    String? propertyType,
    String? floorName,
    double? nla,
  }) async {
    final repo = FloorRepository(_db);
    final existing = await repo.findById(id);
    if (existing == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }

    // 校验业态值合法
    const validPropertyTypes = {'office', 'retail', 'apartment'};
    if (propertyType != null && !validPropertyTypes.contains(propertyType)) {
      throw const ValidationException(
          'INVALID_PROPERTY_TYPE', '业态必须为 office / retail / apartment');
    }

    var updatedUnitCount = 0;

    // 若业态有变化，在同一事务内级联更新楼层 + 单元
    if (propertyType != null && propertyType != existing.propertyType) {
      updatedUnitCount = await _db.runTx<int>((tx) async {
        final txRepo = FloorRepository(tx);
        await txRepo.updatePropertyType(id, propertyType);
        return txRepo.cascadePropertyTypeToUnits(id, propertyType);
      });
    }

    // 更新 floor_name / nla（若有传入）
    if (floorName != null || nla != null) {
      await _db.execute(
        Sql.named('''
          UPDATE floors SET
            floor_name = COALESCE(@floorName, floor_name),
            nla        = COALESCE(@nla,       nla),
            updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id, 'floorName': floorName, 'nla': nla},
      );
    }

    final updated = await repo.findById(id);
    return (floor: updated!, updatedUnitCount: updatedUnitCount);
  }

  // ─── 热区 ─────────────────────────────────────────────────────────────────

  Future<FloorHeatmap> getHeatmap(String floorId) async {
    final heatmap = await FloorRepository(_db).getHeatmap(floorId);
    if (heatmap == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return heatmap;
  }

  // ─── floor_plans ─────────────────────────────────────────────────────────

  Future<List<FloorPlan>> listPlans(String floorId) async {
    // 校验楼层存在
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return FloorRepository(_db).findPlansByFloor(floorId);
  }

  /// 上传 CAD 文件并创建图纸版本记录。
  /// Phase 1：仅存储原始文件，返回 status='converting'；
  ///           转换任务由后台 Job 实际处理，此处同步存为 svg_path（占位）。
  Future<Map<String, dynamic>> uploadCad({
    required String floorId,
    required String versionLabel,
    required List<int> fileBytes,
    required String originalFilename,
    required String uploadedBy,
  }) async {
    // 校验楼层存在
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }

    // 校验文件扩展名
    final ext = p.extension(originalFilename).toLowerCase();
    if (ext != '.dwg') {
      throw const ValidationException('INVALID_CAD_FILE', '只接受 .dwg 格式文件');
    }

    // 持久化原始 DWG 文件
    final cadDir = Directory(
        p.join(_fileStoragePath, 'floors', floor.buildingId, floorId));
    await cadDir.create(recursive: true);

    final safeLabel = versionLabel
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .toLowerCase();
    final cadPath = p.join(cadDir.path, '$safeLabel.dwg');
    await File(cadPath).writeAsBytes(Uint8List.fromList(fileBytes));

    // 使用占位 svg_path（待后台 Job 转换后更新）
    final svgRelPath =
        'floors/${floor.buildingId}/$floorId/$safeLabel.svg';

    final plan = await FloorRepository(_db).createPlan(
      floorId: floorId,
      versionLabel: versionLabel,
      svgPath: svgRelPath,
      isCurrent: false,
      uploadedBy: uploadedBy,
    );

    return {
      'floor_plan_id': plan.id,
      'version_label': plan.versionLabel,
      'status': 'converting',
    };
  }

  /// 将指定图纸版本设为当前生效版本，并同步更新 floors.svg_path
  Future<FloorPlan> setCurrentPlan(String planId) async {
    final plan = await FloorRepository(_db).setCurrentPlan(planId);
    if (plan == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '图纸版本不存在');
    }
    return plan;
  }

  // ─── floor_maps（楼层结构标注 v2）────────────────────────

  static const _kAllowedStructureTypes = <String>{
    'core', 'elevator', 'stair', 'restroom', 'equipment', 'corridor', 'column',
  };
  static const _kStructureTypesWithRect = <String>{
    'core', 'elevator', 'stair', 'restroom', 'equipment', 'corridor',
  };
  static final _kElevatorCodeRe = RegExp(r'^[A-Z]\d{1,3}$');
  static const _kAllowedGenders = <String>{'M', 'F', 'unknown'};
  static const _kAllowedSides = <String>{'N', 'S', 'E', 'W'};

  /// 读取该楼层的候选结构（DXF 抽取生成）。
  Future<Map<String, dynamic>> getCandidates(String floorId) async {
    _ensureUuid(floorId);
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    final candidates = await FloorMapRepository(_db).findCandidates(floorId);
    if (candidates == null) {
      throw const NotFoundException(
        'FLOOR_MAP_CANDIDATES_NOT_GENERATED',
        '该楼层尚未生成候选结构，请先上传 DXF 并运行抽取流水线',
      );
    }
    return candidates;
  }

  /// 读取该楼层已确认的结构（PUT 保存后的数据）。
  /// 同时返回乐观锁版本号（floors.floor_map_updated_at）以供 Controller 写入 ETag 响应头。
  Future<({FloorMap map, DateTime? version})> getConfirmedStructures(
      String floorId) async {
    _ensureUuid(floorId);
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    final map = await FloorMapRepository(_db).findByFloorId(floorId);
    if (map == null) {
      // 首次查询尚未保存任何 structures，返回空壳以便前端加载候选。
      // 以 floors.floor_map_updated_at 作为版本号（可为 null）。
      return (
        map: FloorMap(floorId: floorId, updatedAt: DateTime.now().toUtc()),
        version: floor.floorMapUpdatedAt,
      );
    }
    return (map: map, version: floor.floorMapUpdatedAt);
  }

  /// 保存审核后的结构（覆盖写）。
  ///
  /// 入参 [payload] 为 HTTP 请求 body。[ifMatch] 为请求头 If-Match 原始值（可选）。
  /// 返回覆盖后的 FloorMap + 新版本号（用于 ETag）。
  Future<({FloorMap map, DateTime version})> saveStructures({
    required String floorId,
    required Map<String, dynamic> payload,
    String? ifMatch,
    required String updatedBy,
  }) async {
    _ensureUuid(floorId);

    // 前置校验
    final schemaVersion = payload['schema_version'];
    if (schemaVersion != '2.0') {
      throw const ValidationException(
        'FLOOR_MAP_SCHEMA_UNSUPPORTED',
        'schema_version 必须为 2.0',
      );
    }

    final viewport = _asMap(payload['viewport']);
    if (viewport == null) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'viewport 必填',
      );
    }
    final vw = _asNum(viewport['width']);
    final vh = _asNum(viewport['height']);
    if (vw == null || vh == null || vw < 100 || vw > 4000 || vh < 100 || vh > 4000) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'viewport.width / height 必须在 [100, 4000]',
      );
    }

    final outline = _asMap(payload['outline']);
    if (outline == null) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'outline 必填',
      );
    }
    final outlineType = outline['type'];
    if (outlineType == 'rect') {
      if (_asMap(outline['rect']) == null) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'outline.rect 必填（type=rect）',
        );
      }
    } else if (outlineType == 'polygon') {
      final pts = outline['points'];
      if (pts is! List || pts.length < 3 || pts.length > 32) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'outline.points 长度必须在 [3, 32]',
        );
      }
    } else {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'outline.type 必须为 rect 或 polygon',
      );
    }

    final structuresRaw = payload['structures'];
    if (structuresRaw is! List) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'structures 必须为数组',
      );
    }
    if (structuresRaw.length > 200) {
      throw const ValidationException(
        'FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED',
        'structures 数量不得超过 200',
      );
    }

    final windowsRaw = (payload['windows'] as List?) ?? const [];
    if (windowsRaw.length > 100) {
      throw const ValidationException(
        'FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED',
        'windows 数量不得超过 100',
      );
    }

    final structures = <Map<String, dynamic>>[];
    for (final raw in structuresRaw) {
      if (raw is! Map) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'structure 必须为对象',
        );
      }
      final s = Map<String, dynamic>.from(raw);
      _validateStructure(s, vw, vh);
      structures.add(s);
    }

    final windows = <Map<String, dynamic>>[];
    for (final raw in windowsRaw) {
      if (raw is! Map) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'window 必须为对象',
        );
      }
      final w = Map<String, dynamic>.from(raw);
      _validateWindow(w, vw, vh);
      windows.add(w);
    }

    final north = _asMap(payload['north']);
    if (north != null) {
      final nx = _asNum(north['x']);
      final ny = _asNum(north['y']);
      if (nx == null || ny == null || nx < 0 || ny < 0 || nx > vw || ny > vh) {
        throw const ValidationException(
          'FLOOR_MAP_COORDINATE_OUT_OF_RANGE',
          'north.x / y 坐标超出 viewport',
        );
      }
      final rot = _asNum(north['rotation_deg']);
      if (rot != null && (rot < -180 || rot > 180)) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'north.rotation_deg 必须在 [-180, 180]',
        );
      }
    }

    // 楼层必须存在
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }

    // 乐观锁：ifMatch 与当前 floor_map_updated_at 比对
    if (ifMatch != null && ifMatch.isNotEmpty) {
      final currentTag = floor.floorMapUpdatedAt?.toUtc().toIso8601String();
      // 允许两种格式：原始 ISO8601 或 "<value>"（HTTP ETag 常规带引号）
      final normalized = ifMatch.replaceAll('"', '').trim();
      if (currentTag == null || normalized != currentTag) {
        throw const ConflictException(
          'FLOOR_MAP_VERSION_CONFLICT',
          '楼层结构已被其他会话修改，请重新加载',
        );
      }
    }

    // 覆盖写入
    final saved = await FloorMapRepository(_db).upsert(
      floorId: floorId,
      schemaVersion: '2.0',
      viewport: viewport,
      outline: outline,
      structures: structures,
      windows: windows,
      north: north,
      updatedBy: updatedBy,
    );

    // 同步推进 floors.floor_map_updated_at 作为版本号
    final newVersion =
        await FloorRepository(_db).bumpFloorMapVersion(floorId);

    // 写入审计日志
    await _writeAudit(
      userId: updatedBy,
      action: 'floor_map.structures.update',
      resourceType: 'floor',
      resourceId: floorId,
      after: {
        'structures_count': structures.length,
        'windows_count': windows.length,
        'outline_type': outlineType,
      },
    );

    return (map: saved, version: newVersion);
  }

  /// 切换楼层渲染模式（vector / semantic）。
  Future<Map<String, dynamic>> switchRenderMode({
    required String floorId,
    required String renderMode,
    required String userId,
  }) async {
    _ensureUuid(floorId);
    if (renderMode != 'vector' && renderMode != 'semantic') {
      throw const ValidationException(
        'INVALID_RENDER_MODE',
        'render_mode 必须为 vector 或 semantic',
      );
    }

    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }

    if (renderMode == 'semantic') {
      final map = await FloorMapRepository(_db).findByFloorId(floorId);
      if (map == null || map.outline == null) {
        throw const AppException(
          'FLOOR_MAP_NOT_READY_FOR_SEMANTIC',
          '语义渲染需要先保存 outline',
          422,
        );
      }
      final hasCoreOrCorridor = map.structures.any((s) {
        final t = s['type'];
        return t == 'core' || t == 'corridor';
      });
      if (!hasCoreOrCorridor) {
        throw const AppException(
          'FLOOR_MAP_NOT_READY_FOR_SEMANTIC',
          '语义渲染要求 structures 至少含一个 core 或 corridor',
          422,
        );
      }
    }

    await FloorRepository(_db).updateRenderMode(floorId, renderMode);

    final changedAt = DateTime.now().toUtc();
    await _writeAudit(
      userId: userId,
      action: 'floor_map.render_mode.change',
      resourceType: 'floor',
      resourceId: floorId,
      after: {'render_mode': renderMode},
    );

    return {
      'floor_id': floorId,
      'render_mode': renderMode,
      'render_mode_changed_at': changedAt.toIso8601String(),
      'changed_by': userId,
    };
  }

  // ─── 内部辅助 ────────────────────────────────────────────

  void _ensureUuid(String value) {
    final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!re.hasMatch(value)) {
      throw const ValidationException('INVALID_UUID', '非法的 UUID 格式');
    }
  }

  void _validateStructure(Map<String, dynamic> s, num vw, num vh) {
    final type = s['type'];
    if (type is! String || !_kAllowedStructureTypes.contains(type)) {
      throw const ValidationException(
        'FLOOR_MAP_INVALID_STRUCTURE_TYPE',
        'structure.type 不在允许枚举内',
      );
    }
    if (s['source'] != 'manual') {
      throw const ValidationException(
        'VALIDATION_ERROR',
        '保存时所有 structure.source 必须为 manual',
      );
    }
    final label = s['label'];
    if (label is String && label.length > 32) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'structure.label 长度不得超过 32',
      );
    }

    if (type == 'column') {
      final point = s['point'];
      if (point is! List || point.length != 2) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'column.point 必须为 [x, y]',
        );
      }
      final px = _asNum(point[0]);
      final py = _asNum(point[1]);
      if (px == null || py == null) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'column.point 需为数字',
        );
      }
      if (px < 0 || py < 0 || px > vw || py > vh) {
        throw const ValidationException(
          'FLOOR_MAP_COORDINATE_OUT_OF_RANGE',
          'column 坐标超出 viewport',
        );
      }
      return;
    }

    if (_kStructureTypesWithRect.contains(type)) {
      final rect = _asMap(s['rect']);
      if (rect == null) {
        throw ValidationException(
          'VALIDATION_ERROR',
          '$type 必须提供 rect',
        );
      }
      final x = _asNum(rect['x']);
      final y = _asNum(rect['y']);
      final w = _asNum(rect['w']);
      final h = _asNum(rect['h']);
      if (x == null || y == null || w == null || h == null || w <= 0 || h <= 0) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'rect.x/y/w/h 需为有效数字且 w/h > 0',
        );
      }
      if (x < 0 || y < 0 || x + w > vw || y + h > vh) {
        throw const ValidationException(
          'FLOOR_MAP_COORDINATE_OUT_OF_RANGE',
          'structure rect 超出 viewport',
        );
      }
    }

    if (type == 'elevator') {
      final code = s['code'];
      if (code is! String || !_kElevatorCodeRe.hasMatch(code)) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'elevator.code 必须形如 E1 / E12 (^[A-Z]\\d{1,3}\$)',
        );
      }
    }
    if (type == 'restroom') {
      final gender = s['gender'];
      if (gender == null || (gender is String && !_kAllowedGenders.contains(gender))) {
        throw const ValidationException(
          'VALIDATION_ERROR',
          'restroom.gender 必须为 M / F / unknown',
        );
      }
    }
  }

  void _validateWindow(Map<String, dynamic> w, num vw, num vh) {
    final side = w['side'];
    if (side is! String || !_kAllowedSides.contains(side)) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'window.side 必须为 N / S / E / W',
      );
    }
    final offset = _asNum(w['offset']);
    final width = _asNum(w['width']);
    if (offset == null || width == null) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'window.offset / width 需为数字',
      );
    }
    if (width < 8) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'window.width 最小为 8',
      );
    }
    if (offset < 0) {
      throw const ValidationException(
        'VALIDATION_ERROR',
        'window.offset 不得为负',
      );
    }
    final sideLen = (side == 'N' || side == 'S') ? vw : vh;
    if (offset + width > sideLen) {
      throw const ValidationException(
        'FLOOR_MAP_COORDINATE_OUT_OF_RANGE',
        'window 超出所属边长度',
      );
    }
  }

  Future<void> _writeAudit({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    required Map<String, dynamic> after,
  }) async {
    try {
      await _db.execute(
        Sql.named('''
          INSERT INTO audit_logs
            (user_id, action, resource_type, resource_id,
             before_json, after_json, retention_until)
          VALUES
            (@userId::uuid, @action, @resourceType, @resourceId::uuid,
             '{}'::jsonb, @after::jsonb,
             NOW() + INTERVAL '3 years')
        '''),
        parameters: {
          'userId': userId,
          'action': action,
          'resourceType': resourceType,
          'resourceId': resourceId,
          'after': jsonEncode(after),
        },
      );
    } catch (e) {
      stderr.writeln(
          '[AUDIT_ERROR] floor_map 审计写入失败 action=$action id=$resourceId: $e');
    }
  }

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}
