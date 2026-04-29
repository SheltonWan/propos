import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/heatmap.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/unit_status.dart';

part 'heatmap_model.freezed.dart';
part 'heatmap_model.g.dart';

/// HeatmapUnit DTO（对应 API_CONTRACT v1.7 §2.9）。
@freezed
abstract class HeatmapUnitModel with _$HeatmapUnitModel {
  const factory HeatmapUnitModel({
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'unit_number') required String unitNumber,
    @JsonKey(name: 'current_status') required String currentStatus,
    @JsonKey(name: 'property_type') required String propertyType,
    @JsonKey(name: 'tenant_name') String? tenantName,
    @JsonKey(name: 'contract_end_date') String? contractEndDate,
  }) = _HeatmapUnitModel;

  factory HeatmapUnitModel.fromJson(Map<String, dynamic> json) =>
      _$HeatmapUnitModelFromJson(json);
}

/// FloorHeatmap DTO（对应 API_CONTRACT v1.7 §2.9）。
@freezed
abstract class FloorHeatmapModel with _$FloorHeatmapModel {
  const factory FloorHeatmapModel({
    @JsonKey(name: 'floor_id') required String floorId,
    @JsonKey(name: 'svg_path') String? svgPath,
    required List<HeatmapUnitModel> units,
  }) = _FloorHeatmapModel;

  factory FloorHeatmapModel.fromJson(Map<String, dynamic> json) =>
      _$FloorHeatmapModelFromJson(json);
}

extension FloorHeatmapModelX on FloorHeatmapModel {
  FloorHeatmap toEntity() => FloorHeatmap(
        floorId: floorId,
        svgPath: svgPath,
        units: units.map((e) => e.toEntity()).toList(),
      );
}

extension HeatmapUnitModelX on HeatmapUnitModel {
  HeatmapUnit toEntity() => HeatmapUnit(
        unitId: unitId,
        unitNumber: unitNumber,
        currentStatus: UnitStatus.fromString(currentStatus),
        propertyType: PropertyType.fromString(propertyType),
        tenantName: tenantName,
        contractEndDate: contractEndDate != null
            ? DateTime.tryParse(contractEndDate!)
            : null,
      );
}
