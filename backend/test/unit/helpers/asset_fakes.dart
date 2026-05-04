/// M1 资产模块测试共享伪对象库。
///
/// 包含：
///   - 模型工厂函数（fakeBuilding / fakeFloor / fakeFloorPlan / fakeUnit /
///     fakeRenovationRecord）
///   - DB 行工厂（列名常量 + 行数据列表）
///   - 伪 Service 类（FakeBuildingService / FakeFloorService / FakeUnitService
///     / FakeRenovationService）— 供 Controller 单元测试注入
library asset_test_helpers;

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/pagination.dart';
import 'package:propos_backend/modules/assets/models/building.dart';
import 'package:propos_backend/modules/assets/models/floor.dart';
import 'package:propos_backend/modules/assets/models/floor_plan.dart';
import 'package:propos_backend/modules/assets/models/renovation_record.dart';
import 'package:propos_backend/modules/assets/models/unit.dart';
import 'package:propos_backend/modules/assets/services/building_service.dart';
import 'package:propos_backend/modules/assets/services/floor_service.dart';
import 'package:propos_backend/modules/assets/services/renovation_service.dart';
import 'package:propos_backend/modules/assets/services/unit_import_service.dart';
import 'package:propos_backend/modules/assets/services/unit_service.dart';

import 'fakes.dart';

// ─── 时间常量 ──────────────────────────────────────────────────────────────────
final _t = DateTime.utc(2026, 1, 1);

// ─── 模型工厂函数 ─────────────────────────────────────────────────────────────

Building fakeBuilding({
  String id = 'b-1',
  String name = 'Test Tower',
  String propertyType = 'office',
  int totalFloors = 10,
  int basementFloors = 0,
  double gfa = 5000.0,
  double nla = 4000.0,
  String? address,
}) =>
    Building(
      id: id,
      name: name,
      propertyType: propertyType,
      totalFloors: totalFloors,
      basementFloors: basementFloors,
      gfa: gfa,
      nla: nla,
      address: address,
      createdAt: _t,
      updatedAt: _t,
    );

Floor fakeFloor({
  String id = 'f-1',
  String buildingId = 'b-1',
  String? buildingName = 'Test Tower',
  int floorNumber = 1,
  String? floorName = '1F',
}) =>
    Floor(
      id: id,
      buildingId: buildingId,
      buildingName: buildingName,
      floorNumber: floorNumber,
      floorName: floorName,
      createdAt: _t,
      updatedAt: _t,
    );

FloorPlan fakeFloorPlan({
  String id = 'fp-1',
  String floorId = 'f-1',
  String versionLabel = 'v1',
  String svgPath = 'floors/b-1/f-1/v1.svg',
  bool isCurrent = true,
}) =>
    FloorPlan(
      id: id,
      floorId: floorId,
      versionLabel: versionLabel,
      svgPath: svgPath,
      isCurrent: isCurrent,
      createdAt: _t,
    );

Unit fakeUnit({
  String id = 'u-1',
  String buildingId = 'b-1',
  String? buildingName = 'Test Tower',
  String floorId = 'f-1',
  String? floorName = '1F',
  String unitNumber = '101',
  String propertyType = 'office',
  String decorationStatus = 'blank',
  String currentStatus = 'vacant',
  bool isLeasable = true,
}) =>
    Unit(
      id: id,
      buildingId: buildingId,
      buildingName: buildingName,
      floorId: floorId,
      floorName: floorName,
      unitNumber: unitNumber,
      propertyType: propertyType,
      decorationStatus: decorationStatus,
      currentStatus: currentStatus,
      isLeasable: isLeasable,
      extFields: {},
      predecessorUnitIds: [],
      createdAt: _t,
      updatedAt: _t,
    );

RenovationRecord fakeRenovationRecord({
  String id = 'r-1',
  String unitId = 'u-1',
  String? unitNumber = '101',
  String renovationType = '隔断改造',
  DateTime? startedAt,
}) =>
    RenovationRecord(
      id: id,
      unitId: unitId,
      unitNumber: unitNumber,
      renovationType: renovationType,
      startedAt: startedAt ?? _t,
      beforePhotoPaths: [],
      afterPhotoPaths: [],
      createdAt: _t,
      updatedAt: _t,
    );

// ─── DB 行工厂（供 FakePool.executeHandler 使用）───────────────────────────────

/// buildings 表查询的列名（与 BuildingRepository SQL 保持一致）
const kBuildingCols = [
  'id',
  'name',
  'property_type',
  'total_floors',
  'basement_floors',
  'gfa', 'nla', 'address', 'built_year', 'created_at', 'updated_at'
];

List<Object?> buildingRow({
  String id = 'b-1',
  String name = 'Test Tower',
  String propertyType = 'office',
  int totalFloors = 10,
  int basementFloors = 0,
  double gfa = 5000.0,
  double nla = 4000.0,
  String? address,
  int? builtYear,
}) =>
    [
      id,
      name,
      propertyType,
      totalFloors,
      basementFloors,
      gfa,
      nla,
      address,
      builtYear,
      _t,
      _t
    ];

/// floors 表查询的列名（与 FloorRepository SQL 保持一致）
const kFloorCols = [
  'id', 'building_id', 'building_name', 'floor_number',
  'floor_name', 'svg_path', 'png_path', 'nla', 'created_at', 'updated_at'
];

List<Object?> floorRow({
  String id = 'f-1',
  String buildingId = 'b-1',
  String buildingName = 'Test Tower',
  int floorNumber = 1,
  String? floorName = '1F',
  String? svgPath,
  String? pngPath,
  double? nla,
}) =>
    [id, buildingId, buildingName, floorNumber, floorName, svgPath, pngPath, nla, _t, _t];

/// floor_plans 表查询的列名（与 FloorRepository SQL 保持一致）
const kFloorPlanCols = [
  'id', 'floor_id', 'version_label', 'svg_path',
  'png_path', 'is_current', 'uploaded_by', 'uploaded_by_name', 'created_at'
];

List<Object?> floorPlanRow({
  String id = 'fp-1',
  String floorId = 'f-1',
  String versionLabel = 'v1',
  String svgPath = 'floors/b-1/f-1/v1.svg',
  bool isCurrent = true,
}) =>
    [id, floorId, versionLabel, svgPath, null, isCurrent, null, null, _t];

/// units 表查询的列名（与 UnitRepository SQL 保持一致）
const kUnitCols = [
  'id', 'building_id', 'building_name', 'floor_id', 'floor_name',
  'unit_number', 'property_type', 'gross_area', 'net_area',
  'orientation', 'ceiling_height', 'decoration_status', 'current_status',
  'is_leasable', 'ext_fields', 'floor_plan_coords', 'current_contract_id', 'qr_code',
  'market_rent_reference', 'predecessor_unit_ids', 'archived_at',
  'created_at', 'updated_at'
];

List<Object?> unitRow({
  String id = 'u-1',
  String buildingId = 'b-1',
  String buildingName = 'Test Tower',
  String floorId = 'f-1',
  String? floorName = '1F',
  String unitNumber = '101',
  String propertyType = 'office',
  String decorationStatus = 'blank',
  String currentStatus = 'vacant',
  bool isLeasable = true,
}) =>
    [
      id, buildingId, buildingName, floorId, floorName,
      unitNumber, propertyType,
      null, null, null, null, // gross_area, net_area, orientation, ceiling_height
      decorationStatus, currentStatus,
      isLeasable,
      <String, dynamic>{}, // ext_fields
      null, // floor_plan_coords
      null, null, null, // current_contract_id, qr_code, market_rent_reference
      <dynamic>[], // predecessor_unit_ids
      null, // archived_at
      _t, _t // created_at, updated_at
    ];

/// renovation_records 表查询的列名（与 RenovationRepository SQL 保持一致）
const kRenovationCols = [
  'id', 'unit_id', 'unit_number', 'renovation_type',
  'started_at', 'completed_at', 'cost', 'contractor', 'description',
  'before_photo_paths', 'after_photo_paths', 'created_by',
  'created_at', 'updated_at'
];

List<Object?> renovationRow({
  String id = 'r-1',
  String unitId = 'u-1',
  String unitNumber = '101',
  String renovationType = '隔断改造',
  DateTime? startedAt,
}) =>
    [
      id, unitId, unitNumber, renovationType,
      startedAt ?? _t, null, // started_at, completed_at
      null, null, null, // cost, contractor, description
      <dynamic>[], <dynamic>[], // before_photo_paths, after_photo_paths
      null, // created_by
      _t, _t // created_at, updated_at
    ];

// ─── 伪 Service 类（用于 Controller 单元测试）──────────────────────────────────

/// 伪 BuildingService — 供 BuildingController 单元测试注入
class FakeBuildingService extends BuildingService {
  AppException? shouldThrow;
  List<Building> listResult = [];
  Building? itemResult;
  List<Floor> floorsResult = [];

  FakeBuildingService() : super(FakePool());

  @override
  Future<List<Building>> listBuildings() async {
    if (shouldThrow != null) throw shouldThrow!;
    return listResult;
  }

  @override
  Future<Building> getBuilding(String id) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    return itemResult!;
  }

  @override
  Future<Building> createBuilding({
    required String name,
    required String propertyType,
    required int totalFloors,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return itemResult!;
  }

  @override
  Future<Building> updateBuilding(
    String id, {
    String? name,
    String? propertyType,
    int? totalFloors,
    int? basementFloors,
    double? gfa,
    double? nla,
    String? address,
    bool addressSet = false,
    int? builtYear,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    return itemResult!;
  }

  @override
  Future<({Building building, List<Floor> floors})> createBuildingWithFloors({
    required String name,
    required String propertyType,
    required int totalFloors,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
    int basementFloors = 0,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return (building: itemResult!, floors: floorsResult);
  }

  @override
  Future<void> deleteBuilding(String id) async {
    if (shouldThrow != null) throw shouldThrow!;
  }
}

/// 伪 FloorService — 供 FloorController / FloorPlanController 单元测试注入
class FakeFloorService extends FloorService {
  AppException? shouldThrow;
  List<Floor> listResult = [];
  Floor? itemResult;
  FloorHeatmap? heatmapResult;
  List<FloorPlan> plansResult = [];
  FloorPlan? planResult;
  Map<String, dynamic> cadResult = {
    'floor_plan_id': 'fp-1',
    'version_label': 'v1',
    'status': 'converting',
  };

  FakeFloorService() : super(FakePool(), '/tmp');

  @override
  Future<List<Floor>> listFloors({String? buildingId}) async {
    if (shouldThrow != null) throw shouldThrow!;
    return listResult;
  }

  @override
  Future<Floor> getFloor(String id) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return itemResult!;
  }

  @override
  Future<Floor> createFloor({
    required String buildingId,
    required int floorNumber,
    String? floorName,
    double? nla,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return itemResult!;
  }

  @override
  Future<FloorHeatmap> getHeatmap(String floorId) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (heatmapResult == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return heatmapResult!;
  }

  @override
  Future<List<FloorPlan>> listPlans(String floorId) async {
    if (shouldThrow != null) throw shouldThrow!;
    return plansResult;
  }

  @override
  Future<Map<String, dynamic>> uploadCad({
    required String floorId,
    required String versionLabel,
    required List<int> fileBytes,
    required String originalFilename,
    required String uploadedBy,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return cadResult;
  }

  @override
  Future<FloorPlan> setCurrentPlan(String planId) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (planResult == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '图纸版本不存在');
    }
    return planResult!;
  }
}

/// 伪 UnitService — 供 UnitController 单元测试注入
class FakeUnitService extends UnitService {
  AppException? shouldThrow;
  PaginatedResult<Unit>? listResult;
  Unit? itemResult;
  Map<String, dynamic>? importResult;
  List<int> exportBytes = [];
  AssetOverviewStats? overviewResult;

  // 参数捕获字段（用于校验 Controller 层的参数解析正确性）
  bool? capturedIsLeasable;
  bool capturedIncludeArchived = false;
  DateTime? capturedArchivedAt;
  bool capturedArchivedAtSet = false;

  FakeUnitService() : super(FakePool());

  @override
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
    capturedIsLeasable = isLeasable;
    capturedIncludeArchived = includeArchived;
    if (shouldThrow != null) throw shouldThrow!;
    return listResult ??
        PaginatedResult(
          items: [],
          meta: PaginationMeta(page: page, pageSize: pageSize, total: 0),
        );
  }

  @override
  Future<Unit> getUnit(String id) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('UNIT_NOT_FOUND', '单元不存在');
    }
    return itemResult!;
  }

  @override
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
    if (shouldThrow != null) throw shouldThrow!;
    return itemResult!;
  }

  @override
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
    capturedArchivedAt = archivedAt;
    capturedArchivedAtSet = archivedAtSet;
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('UNIT_NOT_FOUND', '单元不存在');
    }
    return itemResult!;
  }

  @override
  Future<AssetOverviewStats> getOverview() async {
    if (shouldThrow != null) throw shouldThrow!;
    return overviewResult ??
        const AssetOverviewStats(
          totalUnits: 0,
          totalLeasableUnits: 0,
          totalOccupancyRate: 0.0,
          waleIncomeWeighted: 0.0,
          waleAreaWeighted: 0.0,
          byPropertyType: [],
        );
  }
}

/// 伪 UnitImportService — 供 UnitController 单元测试注入
class FakeUnitImportService extends UnitImportService {
  AppException? shouldThrow;
  Map<String, dynamic>? importResult;
  List<int> exportBytes = [];

  FakeUnitImportService() : super(FakePool());

  @override
  Future<Map<String, dynamic>> importUnits({
    required String filename,
    required List<int> fileBytes,
    bool dryRun = false,
    String? userId,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return importResult ??
        {
          'id': 'fake-batch-id',
          'batch_name': 'units_fake',
          'data_type': 'units',
          'total_records': 0,
          'success_count': 0,
          'failure_count': 0,
          'rollback_status': 'committed',
          'is_dry_run': dryRun,
          'error_details': null,
          'source_file_path': null,
          'created_by': userId,
          'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        };
  }

  @override
  Future<List<int>> exportUnits({String? propertyType}) async {
    if (shouldThrow != null) throw shouldThrow!;
    return exportBytes;
  }
}

/// 伪 RenovationService — 供 RenovationController 单元测试注入
class FakeRenovationService extends RenovationService {
  AppException? shouldThrow;
  PaginatedResult<RenovationRecord>? listResult;
  RenovationRecord? itemResult;
  Map<String, String>? photoResult;

  FakeRenovationService() : super(FakePool(), '/tmp');

  @override
  Future<PaginatedResult<RenovationRecord>> listRenovations({
    String? unitId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return listResult ??
        PaginatedResult(
          items: [],
          meta: PaginationMeta(page: page, pageSize: pageSize, total: 0),
        );
  }

  @override
  Future<RenovationRecord> getRenovation(String id) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('NOT_FOUND', '改造记录不存在');
    }
    return itemResult!;
  }

  @override
  Future<RenovationRecord> createRenovation({
    required String unitId,
    required String renovationType,
    required DateTime startedAt,
    DateTime? completedAt,
    double? cost,
    String? contractor,
    String? description,
    required String createdBy,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return itemResult!;
  }

  @override
  Future<RenovationRecord> updateRenovation(
    String id, {
    String? renovationType,
    DateTime? startedAt,
    DateTime? completedAt,
    bool completedAtSet = false,
    double? cost,
    String? contractor,
    String? description,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    if (itemResult == null) {
      throw const NotFoundException('NOT_FOUND', '改造记录不存在');
    }
    return itemResult!;
  }

  @override
  Future<Map<String, String>> uploadPhoto({
    required String renovationId,
    required List<int> fileBytes,
    required String originalFilename,
    required String photoStage,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return photoResult ??
        {
          'storage_path': 'renovations/$renovationId/test.jpg',
          'photo_stage': photoStage,
        };
  }
}
