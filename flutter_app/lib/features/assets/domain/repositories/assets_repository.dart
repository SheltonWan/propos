import '../entities/asset_overview.dart';
import '../entities/building.dart';
import '../entities/floor.dart';
import '../entities/heatmap.dart';
import '../entities/renovation.dart';
import '../entities/unit.dart';

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
}
