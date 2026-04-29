// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildingModel _$BuildingModelFromJson(Map<String, dynamic> json) =>
    _BuildingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      propertyType: json['property_type'] as String,
      totalFloors: (json['total_floors'] as num).toInt(),
      basementFloors: (json['basement_floors'] as num?)?.toInt() ?? 0,
      gfa: (json['gfa'] as num).toDouble(),
      nla: (json['nla'] as num).toDouble(),
      address: json['address'] as String?,
      builtYear: (json['built_year'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$BuildingModelToJson(_BuildingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'property_type': instance.propertyType,
      'total_floors': instance.totalFloors,
      'basement_floors': instance.basementFloors,
      'gfa': instance.gfa,
      'nla': instance.nla,
      'address': instance.address,
      'built_year': instance.builtYear,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
