import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_paths.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/renovation.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_status.dart';
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

  @override
  Future<({List<UnitSummary> items, int total})> fetchUnits({
    int page = 1,
    int pageSize = 20,
    PropertyType? propertyType,
    UnitStatus? status,
    String? buildingId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (propertyType != null) 'property_type': propertyType.name,
      if (status != null)
        'status': switch (status) {
          UnitStatus.leased => 'leased',
          UnitStatus.vacant => 'vacant',
          UnitStatus.expiringSoon => 'expiring_soon',
          UnitStatus.nonLeasable => 'non_leasable',
        },
      if (buildingId != null) 'building_id': buildingId,
    };
    final response = await _client.apiGetList<UnitSummaryModel>(
      ApiPaths.units,
      queryParams: queryParams,
      fromJson: (json) =>
          UnitSummaryModel.fromJson(json as Map<String, dynamic>),
    );
    return (
      items: response.items.map((m) => m.toEntity()).toList(),
      total: response.meta.total,
    );
  }

  @override
  Future<({int success, int failed, List<String> errors})> uploadUnits(
    String filePath,
    String fileName,
  ) async {
    final data = await _client.apiUpload<Map<String, dynamic>>(
      ApiPaths.unitsImport,
      filePath: filePath,
      fileName: fileName,
    );
    return (
      success: (data['success'] as num?)?.toInt() ?? 0,
      failed: (data['failed'] as num?)?.toInt() ?? 0,
      errors: (data['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
