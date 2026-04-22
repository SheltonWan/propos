import 'package:excel/excel.dart';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/pagination.dart';
import '../models/unit.dart';
import '../repositories/building_repository.dart';
import '../repositories/floor_repository.dart';
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
  /// `dryRun=true` 时仅校验不入库，返回校验结果。
  Future<Map<String, dynamic>> importUnits({
    required List<int> fileBytes,
    bool dryRun = false,
  }) async {
    final excel = Excel.decodeBytes(fileBytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'Excel 文件为空');
    }

    // 第一行为标题行，跳过
    final errors = <String>[];
    final validRows = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 1;

      final buildingId = _cellStr(row, 0);
      final floorId = _cellStr(row, 1);
      final unitNumber = _cellStr(row, 2);
      final propertyType = _cellStr(row, 3);

      if (buildingId == null || floorId == null ||
          unitNumber == null || propertyType == null) {
        errors.add('第 $rowNum 行：楼栋ID、楼层ID、单元编号、业态为必填项');
        continue;
      }
      if (!{'office', 'retail', 'apartment'}.contains(propertyType)) {
        errors.add('第 $rowNum 行：无效业态值 "$propertyType"');
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

    if (!dryRun && validRows.isNotEmpty) {
      await UnitRepository(_db).bulkCreate(validRows);
    }

    return {
      'total_rows': rows.length - 1,
      'valid_rows': validRows.length,
      'error_rows': errors.length,
      'errors': errors,
      'dry_run': dryRun,
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
    final statsList = await UnitRepository(_db).getOverviewStats();
    var totalUnits = 0;
    var totalLeased = 0;
    var totalVacant = 0;

    for (final s in statsList) {
      totalUnits += s.total;
      totalLeased += s.leased;
      totalVacant += s.vacant;
    }

    return AssetOverviewStats(
      byPropertyType: statsList,
      totalUnits: totalUnits,
      totalLeased: totalLeased,
      totalVacant: totalVacant,
      occupancyRate: totalUnits > 0 ? totalLeased / totalUnits : 0.0,
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
