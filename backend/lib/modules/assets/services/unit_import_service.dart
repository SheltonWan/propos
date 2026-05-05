import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../repositories/import_batch_repository.dart';
import '../repositories/unit_repository.dart';

/// UnitImportService — 房源单元批量导入/导出逻辑。
///
/// 从 UnitService 独立拆出，保持 CRUD 与 Import/Export 职责分离。
/// 仅持有 Pool，不感知 HTTP 层。
class UnitImportService {
  final Pool _db;

  UnitImportService(this._db);

  // ─── 批量导入 ─────────────────────────────────────────────────────────────

  /// 解析 Excel 文件并批量导入单元。
  ///
  /// 列映射（与 unit_import_template.ts 的 TEMPLATE 严格对齐）：
  ///
  /// 【新模板 v2（含楼层业态列，15 列）】
  ///   0: 楼栋名称   → 通过 buildings.name 解析为 building_id
  ///   1: 楼层名称   → 通过 floors.floor_name + building_id 解析为 floor_id
  ///   2: 楼层业态   → 更新 floors.property_type 并级联单元（写字楼/商铺/公寓）
  ///   3: 单元编号   → unit_number
  ///   4: 建筑面积   → gross_area
  ///   5: 套内面积   → net_area
  ///   6: 朝向       → orientation
  ///   7: 层高       → ceiling_height
  ///   8: 装修状态   → decoration_status
  ///   9: 是否可租   → is_leasable
  ///  10: 参考租金   → market_rent_reference
  ///  11-13: 业态专属 ext_fields
  ///
  /// 【旧模板 v1-b（含单元业态列，14 列）】
  ///   0-1: 同上
  ///   2: 单元编号   → unit_number
  ///   3: 单元业态   → property_type（兜底时继承楼栋业态）
  ///   4-13: 同上
  ///
  /// 【旧模板 v1-a（无业态列，13 列）】
  ///   0-1: 同上
  ///   2: 单元编号   → unit_number
  ///   3-12: 同 v1-b 的 4-13
  ///
  /// 行为契约：
  ///   - `dryRun=true`：仅校验，不入库；写入一条 `is_dry_run=true` 的批次记录，
  ///     `rollback_status='committed'`，`success_count` 为校验通过行数，
  ///     `failure_count` 为校验失败行数。
  ///   - `dryRun=false`：在事务中校验 + 整批插入；任意行校验失败则整体回滚，
  ///     批次记录 `rollback_status='rolled_back'`、`success_count=0`；
  ///     全部通过则提交，`success_count` 为实际写入行数（去重后）。
  ///
  /// 返回结构与 admin/`ImportBatchDetail` 字段严格对齐。
  Future<Map<String, dynamic>> importUnits({
    required String filename,
    required List<int> fileBytes,
    bool dryRun = false,
    String? userId,
  }) async {
    // ── ① 解析文件（CSV / xlsx / xls 均支持）────────────────────────────
    final List<List<dynamic>> rawRows;
    final lower = filename.toLowerCase();
    if (lower.endsWith('.csv')) {
      final text = utf8
          .decode(fileBytes)
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      rawRows = const CsvToListConverter(eol: '\n').convert(text);
    } else if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      final Excel excel;
      try {
        excel = Excel.decodeBytes(fileBytes);
      } catch (_) {
        throw const ValidationException(
            'INVALID_FILE_FORMAT', '文件格式不支持，请上传 .csv / .xlsx 文件');
      }
      final sheet = excel.tables.values.first;
      rawRows = sheet.rows.map((r) => r.map((c) => c?.value).toList()).toList();
    } else {
      throw const ValidationException(
          'INVALID_FILE_FORMAT', '仅支持 .csv / .xlsx / .xls 文件');
    }

    if (rawRows.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', '文件内容为空');
    }

    // 将 rawRows 转为统一的 List<List<dynamic>>，用于后续按列索引访问
    // 跳过表头行（rawRows[0]）
    final rows = rawRows;

    // ── 表头自适应：三种模板兼容 ────────────────────────────────────────
    // v2 新模板（Col 2 = 楼层业态）：col2 header 含「楼层」和「业态」
    // v1-b 旧模板（Col 3 = 单元业态）：col3 header 含「业态」
    // v1-a 旧模板（无业态列）：默认
    final headerRow = rows.isNotEmpty ? rows[0] : const <dynamic>[];
    final headerCol2 =
        headerRow.length > 2 ? (headerRow[2]?.toString().trim() ?? '') : '';
    final headerCol3 = headerRow.length > 3
        ? (headerRow[3]?.toString().trim() ?? '')
        : '';
    // hasFloorPropertyTypeCol: v2 模板，Col 2 是楼层业态
    final hasFloorPropertyTypeCol =
        headerCol2.contains('楼层') && headerCol2.contains('业态');
    // hasUnitPropertyTypeCol: v1-b 模板，Col 3 是单元业态
    final hasUnitPropertyTypeCol =
        !hasFloorPropertyTypeCol && headerCol3.contains('业态');
    // colOffset: 在 v2/v1-b 中，数值列整体右移 1 位
    // v2:  unit_number=Col3, data起始=Col4
    // v1-b: unit_number=Col2, data起始=Col3（但业态在Col3，数值从Col4开始，offset=1）
    // v1-a: unit_number=Col2, data起始=Col3，offset=0
    final int unitNumberCol;
    final int colOffset;
    if (hasFloorPropertyTypeCol) {
      unitNumberCol = 3; // v2: 单元编号在 Col 3
      colOffset = 1; // 数值列从 Col 4 开始（相对 v1-a 的 Col 3 右移 1）
    } else if (hasUnitPropertyTypeCol) {
      unitNumberCol = 2; // v1-b: 单元编号仍在 Col 2
      colOffset = 1; // 数值列从 Col 4 开始
    } else {
      unitNumberCol = 2; // v1-a: 单元编号在 Col 2
      colOffset = 0; // 数值列从 Col 3 开始
    }

    // ── ② 行级校验（含楼栋/楼层名称解析，跳过注释行和空行）───────────────
    final errorDetails = <Map<String, dynamic>>[];
    final validRows = <Map<String, dynamic>>[];

    // 楼层业态更新缓存：避免同一楼层重复调用 patchFloor
    // key = floorId，value = 解析后的 property_type
    final floorPropertyTypeUpdates = <String, String>{};

    // 楼栋/楼层名称解析缓存；避免同名重复查询
    final buildingCache = <String, Map<String, String>?>{}; // 楼栋名→{id,property_type}
    final floorCache = <String, String?>{};                 // "$buildingId:楼层名"→floor_id

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      // 跳过空行（全列为空）
      if (row.every((c) =>
          c == null ||
          c.toString().trim().isEmpty)) {
        continue;
      }

      // 跳过模板提示行（首列以 # 开头）
      final firstCell = _cellStrRaw(row, 0);
      if (firstCell != null && firstCell.startsWith('#')) continue;

      final rowNum = i + 1;

      // ── 必填字段 ────────────────────────────────────────────────────────
      final buildingName = firstCell;
      if (buildingName == null) {
        errorDetails.add(_err(rowNum, '楼栋名称', '楼栋名称不能为空'));
        continue;
      }

      final floorName = _cellStr(row, 1);
      if (floorName == null) {
        errorDetails.add(_err(rowNum, '楼层名称', '楼层名称不能为空'));
        continue;
      }

      final unitNumber = _cellStr(row, unitNumberCol);
      if (unitNumber == null) {
        errorDetails.add(_err(rowNum, '单元编号', '单元编号不能为空'));
        continue;
      }

      // ── 楼栋名称解析（带缓存）─────────────────────────────────────────
      if (!buildingCache.containsKey(buildingName)) {
        final r = await _db.execute(
          Sql.named(
            'SELECT id::TEXT, property_type::TEXT FROM buildings '
            'WHERE name = @name LIMIT 1',
          ),
          parameters: {'name': buildingName},
        );
        buildingCache[buildingName] = r.isEmpty
            ? null
            : {
                'id': r.first.toColumnMap()['id'] as String,
                'property_type':
                    r.first.toColumnMap()['property_type'] as String,
              };
      }
      final buildingInfo = buildingCache[buildingName];
      if (buildingInfo == null) {
        errorDetails.add(_err(rowNum, '楼栋名称', '楼栋不存在: $buildingName'));
        continue;
      }
      final buildingId = buildingInfo['id']!;
      final buildingPropertyType = buildingInfo['property_type']!;

      // ── 楼层名称解析（带缓存）─────────────────────────────────────────
      // 容错：除按 floor_name 精确匹配外，再用解析出来的 floor_number 兜底，
      // 兼容历史 floor_name=NULL 的楼栋（如早期通过 SQL 直接插入的 floors）。
      // 支持 "6F"/"6" → 6，"B1"/"-1" → -1
      final floorCacheKey = '$buildingId:$floorName';
      if (!floorCache.containsKey(floorCacheKey)) {
        final fallbackNumber = _parseFloorNumber(floorName);
        final r = await _db.execute(
          Sql.named(
            'SELECT id::TEXT FROM floors '
            'WHERE building_id = @bid::UUID '
            '  AND (floor_name = @name OR floor_number = @num) '
            'LIMIT 1',
          ),
          parameters: {
            'bid': buildingId,
            'name': floorName,
            'num': fallbackNumber ?? -9999,
          },
        );
        floorCache[floorCacheKey] =
            r.isEmpty ? null : r.first.toColumnMap()['id'] as String;
      }
      final floorId = floorCache[floorCacheKey];
      if (floorId == null) {
        errorDetails.add(_err(
            rowNum, '楼层名称', '楼层不存在: $floorName（楼栋: $buildingName）'));
        continue;
      }

      // ── 行级楼层业态（v2 新模板：Col 2 = 楼层业态）──────────────────────
      // v1-b 旧模板：Col 3 = 单元业态（直接继承到单元，不更新楼层）
      // v1-a 旧模板：继承楼栋业态
      String? rawPt;
      if (hasFloorPropertyTypeCol) {
        // v2：Col 2 为楼层业态，写入楼层并让单元继承
        rawPt = _cellStr(row, 2);
        // 记录本楼层本次导入应设置的业态（同一楼层多行取最后一行，实践中同楼层应一致）
        if (rawPt != null && rawPt.isNotEmpty) {
          final parsedPt = _parsePropertyType(rawPt);
          if (parsedPt == null) {
            errorDetails.add(_err(rowNum, '楼层业态',
                '无效业态值: $rawPt（合法值: 写字楼/商铺/公寓 或 office/retail/apartment）'));
            continue;
          }
          floorPropertyTypeUpdates[floorId] = parsedPt;
        }
      } else if (hasUnitPropertyTypeCol) {
        // v1-b：Col 3 为单元业态
        rawPt = _cellStr(row, 3);
      }
      final propertyType = _parsePropertyType(rawPt) ?? buildingPropertyType;
      if (rawPt != null &&
          rawPt.isNotEmpty &&
          _parsePropertyType(rawPt) == null &&
          !hasFloorPropertyTypeCol) {
        // v2 模板的错误已在上方处理；此处只需处理 v1-b 的单元业态错误
        errorDetails.add(_err(rowNum, '业态',
            '无效业态值: $rawPt（合法值: 写字楼/商铺/公寓 或 office/retail/apartment）'));
        continue;
      }
      // 综合体（mixed）楼栋的每个单元必须显式指定具体业态，不能继承楼栋标签
      if (propertyType == 'mixed') {
        errorDetails.add(_err(rowNum, '业态',
            '综合体楼栋的每行必须指定业态（写字楼/商铺/公寓 或 office/retail/apartment），不能留空'));
        continue;
      }

      // ── 业态专属扩展字段（snake_case，对齐 admin 编辑表单和数据库 JSONB）
      // 新模板列序：col11=字段1, col12=字段2, col13=字段3
      // 旧模板列序：col10=字段1, col11=字段2, col12=字段3（不带业态列时整体 -1）
      final ext1 = 11 + colOffset - 1; // 等价：新=11，旧=10
      final ext2 = 12 + colOffset - 1; // 等价：新=12，旧=11
      final ext3 = 13 + colOffset - 1; // 等价：新=13，旧=12
      final extFields = <String, dynamic>{};
      if (propertyType == 'office') {
        final workstationCount = _cellInt(row, ext1);
        if (workstationCount != null) {
          extFields['workstation_count'] = workstationCount;
        }
        final partitionCount = _cellInt(row, ext2);
        if (partitionCount != null) {
          extFields['partition_count'] = partitionCount;
        }
      } else if (propertyType == 'retail') {
        final frontageWidth = _cellDouble(row, ext1);
        if (frontageWidth != null) extFields['frontage_width'] = frontageWidth;
        final streetFacingRaw = _cellStr(row, ext2);
        if (streetFacingRaw != null && streetFacingRaw.isNotEmpty) {
          extFields['street_facing'] = streetFacingRaw == '是';
        }
        final retailCeilingHeight = _cellDouble(row, ext3);
        if (retailCeilingHeight != null) {
          extFields['retail_ceiling_height'] = retailCeilingHeight;
        }
      } else if (propertyType == 'apartment') {
        final bedroomCount = _cellInt(row, ext1);
        if (bedroomCount != null) extFields['bedroom_count'] = bedroomCount;
        final enSuiteRaw = _cellStr(row, ext2);
        if (enSuiteRaw != null && enSuiteRaw.isNotEmpty) {
          extFields['en_suite_bathroom'] = enSuiteRaw == '是';
        }
      }

      validRows.add({
        'building_id': buildingId,
        'floor_id': floorId,
        'unit_number': unitNumber,
        'property_type': propertyType,
        'gross_area': _cellDouble(row, 3 + colOffset),
        'net_area': _cellDouble(row, 4 + colOffset),
        'orientation': _parseOrientation(_cellStr(row, 5 + colOffset)),
        'ceiling_height': _cellDouble(row, 6 + colOffset),
        'decoration_status': _parseDecoration(_cellStr(row, 7 + colOffset)),
        'is_leasable': (_cellStr(row, 8 + colOffset) ?? '是') == '是',
        'market_rent_reference': _cellDouble(row, 9 + colOffset),
        'ext_fields': extFields,
      });
    }

    // totalRecords = 实际参与校验的数据行数（不含注释行/空行）
    final totalRecords = validRows.length + errorDetails.length;
    if (totalRecords == 0) {
      throw const ValidationException('VALIDATION_ERROR', 'Excel 文件中无有效数据行');
    }

    // 批次名称：units_<UTC ISO 紧凑格式>
    final batchName = 'units_${_compactNow()}';

    // ── ③ Dry run：仅记录批次，不入库 ────────────────────────────────────
    if (dryRun) {
      final record = await ImportBatchRepository(_db).create(
        batchName: batchName,
        dataType: 'units',
        totalRecords: totalRecords,
        successCount: validRows.length,
        failureCount: errorDetails.length,
        rollbackStatus: 'committed',
        isDryRun: true,
        errorDetails: errorDetails.isEmpty ? null : errorDetails,
        createdBy: userId,
      );
      return _formatBatchRecord(record);
    }

    // ── ④ Commit：有错误则记录回滚批次，无错误则事务化整批插入 ──────────
    if (errorDetails.isNotEmpty) {
      final record = await ImportBatchRepository(_db).create(
        batchName: batchName,
        dataType: 'units',
        totalRecords: totalRecords,
        successCount: 0,
        failureCount: errorDetails.length,
        rollbackStatus: 'rolled_back',
        isDryRun: false,
        errorDetails: errorDetails,
        createdBy: userId,
      );
      return _formatBatchRecord(record);
    }

    // 全部行校验通过 → 在事务中插入；冲突行 ON CONFLICT DO NOTHING 后真实写入数可能 < validRows
    late Map<String, dynamic> record;
    await _db.runTx((tx) async {
      // v2 新模板：将本次解析出的楼层业态统一更新（含级联单元），在同一事务内完成
      for (final entry in floorPropertyTypeUpdates.entries) {
        await tx.execute(
          Sql.named('''
            UPDATE floors SET
              property_type = @pt::property_type,
              updated_at    = NOW()
            WHERE id = @fid
          '''),
          parameters: {'fid': entry.key, 'pt': entry.value},
        );
        await tx.execute(
          Sql.named('''
            UPDATE units SET
              property_type = @pt::property_type,
              updated_at    = NOW()
            WHERE floor_id   = @fid
              AND archived_at IS NULL
          '''),
          parameters: {'fid': entry.key, 'pt': entry.value},
        );
      }
      final inserted = await UnitRepository(tx).bulkCreate(validRows, tx: tx);
      record = await ImportBatchRepository(tx).create(
        batchName: batchName,
        dataType: 'units',
        totalRecords: totalRecords,
        successCount: inserted,
        failureCount: 0,
        rollbackStatus: 'committed',
        isDryRun: false,
        errorDetails: null,
        createdBy: userId,
        tx: tx,
      );
    });
    return _formatBatchRecord(record);
  }

  // ─── 导出 ─────────────────────────────────────────────────────────────────

  /// 生成房源台账 Excel 文件，返回字节数组
  Future<List<int>> exportUnits({String? propertyType}) async {
    final units = await UnitRepository(_db).findAllForExport(
      propertyType: propertyType,
    );

    final excel = Excel.createExcel();
    final sheet = excel['房源台账'];

    // 标题行
    sheet.appendRow([
      TextCellValue('单元ID'),
      TextCellValue('楼栋名称'),
      TextCellValue('楼层'),
      TextCellValue('单元编号'),
      TextCellValue('业态'),
      TextCellValue('建筑面积(m²)'),
      TextCellValue('套内面积(m²)'),
      TextCellValue('装修状态'),
      TextCellValue('出租状态'),
      TextCellValue('是否可租'),
      TextCellValue('参考租金(元/m²/月)'),
      TextCellValue('归档时间'),
    ]);

    for (final u in units) {
      sheet.appendRow([
        TextCellValue(u.id),
        TextCellValue(u.buildingName ?? ''),
        TextCellValue(u.floorName ?? ''),
        TextCellValue(u.unitNumber),
        TextCellValue(u.propertyType),
        u.grossArea != null
            ? DoubleCellValue(u.grossArea!)
            : TextCellValue(''),
        u.netArea != null
            ? DoubleCellValue(u.netArea!)
            : TextCellValue(''),
        TextCellValue(u.decorationStatus),
        TextCellValue(u.currentStatus),
        TextCellValue(u.isLeasable ? '是' : '否'),
        u.marketRentReference != null
            ? DoubleCellValue(u.marketRentReference!)
            : TextCellValue(''),
        TextCellValue(u.archivedAt != null
            ? u.archivedAt!.toUtc().toIso8601String()
            : ''),
      ]);
    }

    return excel.encode() ?? [];
  }

  // ─── 私有辅助 ──────────────────────────────────────────────────────────────

  /// 构造一条错误明细
  Map<String, dynamic> _err(int row, String field, String error) =>
      {'row': row, 'field': field, 'error': error};

  /// 紧凑 UTC 时间戳，例：20260425T093015Z
  String _compactNow() {
    final iso = DateTime.now().toUtc().toIso8601String();
    return iso.replaceAll(RegExp(r'[-:.]'), '').split('T').join('T').substring(0, 16);
  }

  /// 将 import_batches 表的列映射格式化为响应 JSON
  /// 与 admin/`ImportBatchDetail` 字段严格对齐
  Map<String, dynamic> _formatBatchRecord(Map<String, dynamic> r) {
    final createdAt = r['created_at'];
    final errorRaw = r['error_details'];
    return {
      'id': r['id'] as String,
      'batch_name': r['batch_name'] as String,
      'data_type': r['data_type'] as String,
      'total_records': (r['total_records'] as num).toInt(),
      'success_count': (r['success_count'] as num).toInt(),
      'failure_count': (r['failure_count'] as num).toInt(),
      'rollback_status': r['rollback_status'] as String,
      'is_dry_run': r['is_dry_run'] as bool,
      'error_details': errorRaw is List ? errorRaw : null,
      'source_file_path': r['source_file_path'] as String?,
      'created_by': r['created_by'] as String?,
      'created_at': createdAt is DateTime
          ? createdAt.toUtc().toIso8601String()
          : createdAt?.toString(),
    };
  }

  /// 从单元格读取字符串（兼容 CSV 原生类型和 Excel CellValue 对象）
  String? _cellStr(List<dynamic> row, int col) {
    if (col >= row.length) return null;
    final v = row[col];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// _cellStr 的别名，语义上强调读取原始字符串
  String? _cellStrRaw(List<dynamic> row, int idx) => _cellStr(row, idx);

  double? _cellDouble(List<dynamic> row, int col) {
    if (col >= row.length) return null;
    final v = row[col];
    if (v == null) return null;
    // CSV 路径：CsvToListConverter 已将数字解析为 num
    if (v is num) return v.toDouble();
    // Excel 路径：c?.value 返回 CellValue 子类
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    return double.tryParse(v.toString());
  }

  /// 从单元格读取整数（兼容 String/Int/Double 格）
  int? _cellInt(List<dynamic> row, int col) {
    return _cellDouble(row, col)?.round();
  }

  /// 业态中文或英文→标准英文枚举；无法识别时返回 null
  String? _parsePropertyType(String? value) {
    if (value == null || value.isEmpty) return null;
    const map = {
      '写字楼': 'office',
      'office': 'office',
      '商铺': 'retail',
      'retail': 'retail',
      '公寓': 'apartment',
      'apartment': 'apartment',
    };
    return map[value.toLowerCase()] ?? map[value];
  }

  /// 楼层名称→楼层序号；解析失败返回 null。
  /// 支持 "1F"/"1"/"6F" → 正数；"B1"/"-1" → 负数。
  int? _parseFloorNumber(String value) {
    final v = value.trim().toUpperCase();
    if (v.isEmpty) return null;
    // 纯数字（含负号）
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    // "<数字>F" 形式 → 正数
    final upMatch = RegExp(r'^(\d+)F$').firstMatch(v);
    if (upMatch != null) return int.parse(upMatch.group(1)!);
    // "B<数字>" 形式 → 负数
    final downMatch = RegExp(r'^B(\d+)$').firstMatch(v);
    if (downMatch != null) return -int.parse(downMatch.group(1)!);
    return null;
  }

  /// 朝向中文→英文枚举；不在映射表内时返回 null
  String? _parseOrientation(String? value) {
    if (value == null) return null;
    const map = {'东': 'east', '南': 'south', '西': 'west', '北': 'north'};
    return map[value];
  }

  /// 装修状态中文→英文枚举；无法识别时回退到 'blank'
  String _parseDecoration(String? value) {
    const map = {
      '精装': 'refined',
      '简装': 'simple',
      '毛坯': 'blank',
      '原始': 'raw',
    };
    return map[value] ?? 'blank';
  }
}
