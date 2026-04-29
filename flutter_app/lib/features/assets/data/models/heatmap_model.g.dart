// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heatmap_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HeatmapUnitModel _$HeatmapUnitModelFromJson(Map<String, dynamic> json) =>
    _HeatmapUnitModel(
      unitId: json['unit_id'] as String,
      unitNumber: json['unit_number'] as String,
      currentStatus: json['current_status'] as String,
      propertyType: json['property_type'] as String,
      tenantName: json['tenant_name'] as String?,
      contractEndDate: json['contract_end_date'] as String?,
    );

Map<String, dynamic> _$HeatmapUnitModelToJson(_HeatmapUnitModel instance) =>
    <String, dynamic>{
      'unit_id': instance.unitId,
      'unit_number': instance.unitNumber,
      'current_status': instance.currentStatus,
      'property_type': instance.propertyType,
      'tenant_name': instance.tenantName,
      'contract_end_date': instance.contractEndDate,
    };

_FloorHeatmapModel _$FloorHeatmapModelFromJson(Map<String, dynamic> json) =>
    _FloorHeatmapModel(
      floorId: json['floor_id'] as String,
      svgPath: json['svg_path'] as String?,
      units: (json['units'] as List<dynamic>)
          .map((e) => HeatmapUnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FloorHeatmapModelToJson(_FloorHeatmapModel instance) =>
    <String, dynamic>{
      'floor_id': instance.floorId,
      'svg_path': instance.svgPath,
      'units': instance.units,
    };
