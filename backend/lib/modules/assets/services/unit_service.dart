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

  // ─── 内部 ─────────────────────────────────────────────────────────────────

  static const _validPropertyTypes = {'office', 'retail', 'apartment'};

  void _validatePropertyType(String pt) {
    if (!_validPropertyTypes.contains(pt)) {
      throw ValidationException(
          'VALIDATION_ERROR', '无效业态值: $pt（合法值: office/retail/apartment）');
    }
  }
}
