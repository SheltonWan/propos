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
    required List<int> fileBytes,
    bool dryRun = false,
    String? userId,
  }) async {
    // ── ① 解析 Excel ─────────────────────────────────────────────────────
    final Excel excel;
    try {
      excel = Excel.decodeBytes(fileBytes);
    } catch (_) {
      throw const ValidationException(
          'INVALID_FILE_FORMAT', '文件格式不支持，请上传 .xlsx 格式文件');
    }
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'Excel 文件为空');
    }

    final totalRecords = rows.length - 1; // 第一行为标题行
    if (totalRecords < 0) {
      throw const ValidationException('VALIDATION_ERROR', 'Excel 文件为空');
    }

    // ── ② 行级校验 ───────────────────────────────────────────────────────
    final errorDetails = <Map<String, dynamic>>[];
    final validRows = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 1;

      final buildingId = _cellStr(row, 0);
      final floorId = _cellStr(row, 1);
      final unitNumber = _cellStr(row, 2);
      final propertyType = _cellStr(row, 3);

      if (buildingId == null) {
        errorDetails.add(_err(rowNum, 'building_id', '楼栋ID不能为空'));
        continue;
      }
      if (floorId == null) {
        errorDetails.add(_err(rowNum, 'floor_id', '楼层ID不能为空'));
        continue;
      }
      if (unitNumber == null) {
        errorDetails.add(_err(rowNum, 'unit_number', '单元编号不能为空'));
        continue;
      }
      if (propertyType == null) {
        errorDetails.add(_err(rowNum, 'property_type', '业态不能为空'));
        continue;
      }
      if (!_validPropertyTypes.contains(propertyType)) {
        errorDetails
            .add(_err(rowNum, 'property_type', '无效业态值: $propertyType'));
        continue;
      }

      validRows.add({
        'building_id': buildingId,
        'floor_id': floorId,
        'unit_number': unitNumber,
        'property_type': propertyType,
        'gross_area': _cellDouble(row, 4),
        'net_area': _cellDouble(row, 5),
        'decoration_status': _cellStr(row, 6) ?? 'blank',
        'is_leasable': _cellStr(row, 7)?.toLowerCase() != 'false',
      });
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

  String? _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final v = row[col]?.value;
    if (v == null) return null;
    return v.toString().trim().isEmpty ? null : v.toString().trim();
  }

  double? _cellDouble(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final v = row[col]?.value;
    if (v == null) return null;
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    return double.tryParse(v.toString());
  }
}
