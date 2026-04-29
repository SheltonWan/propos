import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_paths.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/entities/renovation.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/assets_repository.dart';
import '../models/asset_overview_model.dart';
import '../models/building_model.dart';
import '../models/floor_model.dart';
import '../models/heatmap_model.dart';
import '../models/renovation_model.dart';
import '../models/unit_model.dart';

/// AssetsRepository 的 HTTP 实现。
///
/// 所有路径来自 [ApiPaths] 常量，禁止硬编码字符串。
class AssetsRepositoryImpl implements AssetsRepository {
  final ApiClient _client;

  const AssetsRepositoryImpl(this._client);

  @override
  Future<AssetOverview> fetchOverview() async {
    final model = await _client.apiGet<AssetOverviewModel>(
      ApiPaths.assetsOverview,
      fromJson: (json) =>
          AssetOverviewModel.fromJson(json as Map<String, dynamic>),
    );
    return model.toEntity();
  }

  @override
  Future<List<Building>> fetchBuildings() async {
    final response = await _client.apiGetList<BuildingModel>(
      ApiPaths.buildings,
      fromJson: (json) =>
          BuildingModel.fromJson(json as Map<String, dynamic>),
    );
    return response.items.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Building> fetchBuilding(String id) async {
    final model = await _client.apiGet<BuildingModel>(
      '${ApiPaths.buildings}/$id',
      fromJson: (json) =>
          BuildingModel.fromJson(json as Map<String, dynamic>),
    );
    return model.toEntity();
  }

  @override
  Future<List<Floor>> fetchFloors(String buildingId) async {
    final response = await _client.apiGetList<FloorModel>(
      ApiPaths.floors,
      queryParams: {'building_id': buildingId},
      fromJson: (json) =>
          FloorModel.fromJson(json as Map<String, dynamic>),
    );
    return response.items.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Floor> fetchFloor(String id) async {
    final model = await _client.apiGet<FloorModel>(
      '${ApiPaths.floors}/$id',
      fromJson: (json) =>
          FloorModel.fromJson(json as Map<String, dynamic>),
    );
    return model.toEntity();
  }

  @override
  Future<FloorHeatmap> fetchFloorHeatmap(String floorId) async {
    final model = await _client.apiGet<FloorHeatmapModel>(
      '${ApiPaths.floors}/$floorId/heatmap',
      fromJson: (json) =>
          FloorHeatmapModel.fromJson(json as Map<String, dynamic>),
    );
    return model.toEntity();
  }

  @override
  Future<UnitDetail> fetchUnit(String id) async {
    final model = await _client.apiGet<UnitDetailModel>(
      '${ApiPaths.units}/$id',
      fromJson: (json) =>
          UnitDetailModel.fromJson(json as Map<String, dynamic>),
    );
    return model.toEntity();
  }

  @override
  Future<List<RenovationSummary>> fetchRenovations(String unitId) async {
    final response = await _client.apiGetList<RenovationSummaryModel>(
      ApiPaths.renovations,
      queryParams: {'unit_id': unitId},
      fromJson: (json) =>
          RenovationSummaryModel.fromJson(json as Map<String, dynamic>),
    );
    return response.items.map((m) => m.toEntity()).toList();
  }
}
