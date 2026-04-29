import '../entities/asset_overview.dart';
import '../entities/building.dart';
import '../entities/floor.dart';
import '../entities/heatmap.dart';
import '../entities/property_type.dart';
import '../entities/renovation.dart';
import '../entities/unit.dart';
import '../entities/unit_status.dart';

/// 资产模块 Repository 抽象接口（领域层）。
///
/// 实现类在 data 层，BLoC 层只依赖此接口，禁止直接引用实现类。
abstract interface class AssetsRepository {
  /// 获取资产概览看板统计（GET /api/assets/overview）
  Future<AssetOverview> fetchOverview();

  /// 获取楼栋列表（GET /api/buildings）
  Future<List<Building>> fetchBuildings();

  /// 获取单个楼栋详情（GET /api/buildings/:id）
  Future<Building> fetchBuilding(String id);

  /// 获取楼层列表（GET /api/floors?building_id=...）
  Future<List<Floor>> fetchFloors(String buildingId);

  /// 获取单个楼层详情（GET /api/floors/:id）
  Future<Floor> fetchFloor(String id);

  /// 获取楼层热区数据（GET /api/floors/:id/heatmap）
  Future<FloorHeatmap> fetchFloorHeatmap(String floorId);

  /// 获取房源详情（GET /api/units/:id）
  Future<UnitDetail> fetchUnit(String id);

  /// 获取改造记录列表（GET /api/renovations?unit_id=...）
  Future<List<RenovationSummary>> fetchRenovations(String unitId);

  /// 分页查询房源列表（GET /api/units）
  ///
  /// 支持多条件过滤：业态 / 状态 / 所属楼栋，分页参数 [page] 从 1 开始。
  Future<({List<UnitSummary> items, int total})> fetchUnits({
    int page = 1,
    int pageSize = 20,
    PropertyType? propertyType,
    UnitStatus? status,
    String? buildingId,
  });

  /// 上传 Excel 批量导入房源（POST /api/units/import multipart/form-data）
  ///
  /// 返回 `({int success, int failed, List<String> errors})`，
  /// 其中 [errors] 为失败行的描述信息列表。
  Future<({int success, int failed, List<String> errors})> uploadUnits(
    String filePath,
    String fileName,
  );
}
