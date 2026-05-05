// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FloorModel _$FloorModelFromJson(Map<String, dynamic> json) => _FloorModel(
  id: json['id'] as String,
  buildingId: json['building_id'] as String,
  buildingName: json['building_name'] as String,
  floorNumber: (json['floor_number'] as num).toInt(),
  floorName: json['floor_name'] as String?,
  propertyType: json['property_type'] as String?,
  svgPath: json['svg_path'] as String?,
  pngPath: json['png_path'] as String?,
  nla: (json['nla'] as num?)?.toDouble(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$FloorModelToJson(_FloorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'building_id': instance.buildingId,
      'building_name': instance.buildingName,
      'floor_number': instance.floorNumber,
      'floor_name': instance.floorName,
      'property_type': instance.propertyType,
      'svg_path': instance.svgPath,
      'png_path': instance.pngPath,
      'nla': instance.nla,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
