import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/pagination.dart';
import '../models/unit.dart';
import '../repositories/building_repository.dart';
import '../repositories/floor_repository.dart';
import '../repositories/import_batch_repository.dart';
import '../repositories/unit_repository.dart';

/// UnitService — 房源单元管理业务逻辑。
///
/// 约束：
///   1. current_status 由合同系统（M2）维护，PATCH 不允许修改
///   2. 归档（archived_at）后单元不物理删除，仍可查询
///   3. 批量导入使用 ON CONFLICT DO NOTHING 幂等处理
class UnitService {
  final Pool _db;

  UnitService(this._db);

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<PaginatedResult<Unit>> listUnits({
    String? buildingId,
    String? floorId,
    String? propertyType,
    String? currentStatus,
    bool? isLeasable,
    bool includeArchived = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    return UnitRepository(_db).findAll(
      buildingId: buildingId,
      floorId: floorId,
      propertyType: propertyType,
      currentStatus: currentStatus,
      isLeasable: isLeasable,
      includeArchived: includeArchived,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Unit> getUnit(String id) async {
    final unit = await UnitRepository(_db).findById(id);
    if (unit == null) {
      throw const NotFoundException('UNIT_NOT_FOUND', '单元不存在');
    }
    return unit;
  }

  Future<Unit> createUnit({
    required String floorId,
    required String buildingId,
    required String unitNumber,
    required String propertyType,
    double? grossArea,
    double? netArea,
    String? orientation,
    double? ceilingHeight,
    String decorationStatus = 'blank',
    bool isLeasable = true,
    Map<String, dynamic>? extFields,
    double? marketRentReference,
    String? qrCode,
  }) async {
    _validatePropertyType(propertyType);

    // 校验楼栋与楼层存在
    final building = await BuildingRepository(_db).findById(buildingId);
    if (building == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    if (floor.buildingId != buildingId) {
      throw const ValidationException('VALIDATION_ERROR', '楼层不属于指定楼栋');
    }

    try {
      return await UnitRepository(_db).create(
        floorId: floorId,
        buildingId: buildingId,
        unitNumber: unitNumber,
        propertyType: propertyType,
        grossArea: grossArea,
        netArea: netArea,
        orientation: orientation,
        ceilingHeight: ceilingHeight,
        decorationStatus: decorationStatus,
        isLeasable: isLeasable,
        extFields: extFields,
        marketRentReference: marketRentReference,
        qrCode: qrCode,
      );
    } catch (e) {
      // 唯一约束冲突
      if (e.toString().contains('units_building_id_unit_number_key')) {
        throw const ConflictException('CONFLICT', '该楼栋下单元编号已存在');
      }
      rethrow;
    }
  }

  Future<Unit> updateUnit(
    String id, {
    String? unitNumber,
    double? grossArea,
    double? netArea,
    String? orientation,
    double? ceilingHeight,
    String? decorationStatus,
    bool? isLeasable,
    Map<String, dynamic>? extFields,
    double? marketRentReference,
    List<String>? predecessorUnitIds,
    DateTime? archivedAt,
    bool archivedAtSet = false,
  }) async {
    final updated = await UnitRepository(_db).update(
      id,
      unitNumber: unitNumber,
      grossArea: grossArea,
      netArea: netArea,
      orientation: orientation,
      ceilingHeight: ceilingHeight,
      decorationStatus: decorationStatus,
      isLeasable: isLeasable,
      extFields: extFields,
      marketRentReference: marketRentReference,
      predecessorUnitIds: predecessorUnitIds,
      archivedAt: archivedAt,
      archivedAtSet: archivedAtSet,
    );
    if (updated == null) {
      throw const NotFoundException('UNIT_NOT_FOUND', '单元不存在');
    }
    return updated;
  }

  // ─── 批量导入 ─────────────────────────────────────────────────────────────

  /// 解析 Excel 文件并批量导入单元。
  ///
  /// 列映射（与 unit_import_template.ts 的 OFFICE/RETAIL/APARTMENT_TEMPLATE 严格对齐）：
  ///   0: 楼栋名称   → 通过 buildings.name 解析为 building_id，并推导 property_type
  ///   1: 楼层名称   → 通过 floors.floor_name + building_id 解析为 floor_id
  ///   2: 单元编号   → unit_number
  ///   3: 建筑面积   → gross_area
  ///   4: 套内面积   → net_area
  ///   5: 朝向       → orientation（东/南/西/北 → east/south/west/north）
  ///   6: 层高       → ceiling_height
  ///   7: 装修状态   → decoration_status（精装/简装/毛坯/原始）
  ///   8: 是否可租   → is_leasable（是→true）
  ///   9: 参考租金   → market_rent_reference
  ///  10-11: 业态专属 ext_fields（写字楼: 工位数/分隔间数；商铺: 门面宽/是否临街；
  ///          公寓: 卧室数/独立卫生间；商铺col12: 商铺层高）
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

    // ── ② 行级校验（含楼栋/楼层名称解析，跳过注释行和空行）───────────────
    final errorDetails = <Map<String, dynamic>>[];
    final validRows = <Map<String, dynamic>>[];

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

      final unitNumber = _cellStr(row, 2);
      if (unitNumber == null) {
        errorDetails.add(_err(rowNum, '单元编号', '单元编号不能为空'));
        continue;
      }

      // ── 楼栋名称解析（带缓存）─────────────────────────────────────────
      if (!buildingCache.containsKey(buildingName)) {
        final r = await _db.execute(
          Sql.named(
            'SELECT id::TEXT, property_type::TEXT FROM buildings '
            'WHERE name = @name AND archived_at IS NULL LIMIT 1',
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
      final propertyType = buildingInfo['property_type']!;

      // ── 楼层名称解析（带缓存）─────────────────────────────────────────
      final floorCacheKey = '$buildingId:$floorName';
      if (!floorCache.containsKey(floorCacheKey)) {
        final r = await _db.execute(
          Sql.named(
            'SELECT id::TEXT FROM floors '
            'WHERE building_id = @bid::UUID AND floor_name = @name LIMIT 1',
          ),
          parameters: {'bid': buildingId, 'name': floorName},
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

      // ── 业态专属扩展字段 ─────────────────────────────────────────────────
      final extFields = <String, dynamic>{};
      if (propertyType == 'office') {
        final workstations = _cellInt(row, 10);
        if (workstations != null) extFields['workstations'] = workstations;
        final partitions = _cellInt(row, 11);
        if (partitions != null) extFields['partitions'] = partitions;
      } else if (propertyType == 'retail') {
        final shopWidth = _cellDouble(row, 10);
        if (shopWidth != null) extFields['shopWidth'] = shopWidth;
        extFields['isStreetside'] = (_cellStr(row, 11) ?? '') == '是';
        final shopCeilingHeight = _cellDouble(row, 12);
        if (shopCeilingHeight != null) {
          extFields['shopCeilingHeight'] = shopCeilingHeight;
        }
      } else if (propertyType == 'apartment') {
        final bedroomCount = _cellInt(row, 10);
        if (bedroomCount != null) extFields['bedroomCount'] = bedroomCount;
        extFields['privateBathroom'] = (_cellStr(row, 11) ?? '') == '是';
      }

      validRows.add({
        'building_id': buildingId,
        'floor_id': floorId,
        'unit_number': unitNumber,
        'property_type': propertyType,
        'gross_area': _cellDouble(row, 3),
        'net_area': _cellDouble(row, 4),
        'orientation': _parseOrientation(_cellStr(row, 5)),
        'ceiling_height': _cellDouble(row, 6),
        'decoration_status': _parseDecoration(_cellStr(row, 7)),
        'is_leasable': (_cellStr(row, 8) ?? '是') == '是',
        'market_rent_reference': _cellDouble(row, 9),
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

  // ─── 概览统计 ──────────────────────────────────────────────────────────────

  Future<AssetOverviewStats> getOverview() async {
    final repo = UnitRepository(_db);
    final byType = await repo.getOverviewStats();
    final wale = await repo.getWaleStats();
    // 可租单元数走独立 COUNT，避免按业态聚合时遗漏未分类/异常状态导致分母失真
    final totalLeasable = await repo.countLeasableUnits();

    var totalUnits = 0;
    var occupied = 0; // leased + expiring_soon
    for (final s in byType) {
      totalUnits += s.totalUnits;
      occupied += s.leasedUnits + s.expiringSoonUnits;
    }

    return AssetOverviewStats(
      totalUnits: totalUnits,
      totalLeasableUnits: totalLeasable,
      totalOccupancyRate: totalLeasable > 0 ? occupied / totalLeasable : 0.0,
      waleIncomeWeighted: wale.incomeWeighted,
      waleAreaWeighted: wale.areaWeighted,
      byPropertyType: byType,
    );
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  static const _validPropertyTypes = {'office', 'retail', 'apartment'};

  void _validatePropertyType(String pt) {
    if (!_validPropertyTypes.contains(pt)) {
      throw ValidationException(
          'VALIDATION_ERROR', '无效业态值: $pt（合法值: office/retail/apartment）');
    }
  }

  /// 从单元格读取字符串（兼容 CSV 原生类型 和 Excel CellValue 对象）
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
