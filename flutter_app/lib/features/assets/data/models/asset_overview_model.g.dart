// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_overview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PropertyTypeStatsModel _$PropertyTypeStatsModelFromJson(
  Map<String, dynamic> json,
) => _PropertyTypeStatsModel(
  propertyType: json['property_type'] as String,
  totalUnits: (json['total_units'] as num).toInt(),
  leasedUnits: (json['leased_units'] as num).toInt(),
  vacantUnits: (json['vacant_units'] as num).toInt(),
  expiringSoonUnits: (json['expiring_soon_units'] as num).toInt(),
  occupancyRate: (json['occupancy_rate'] as num).toDouble(),
  totalNla: (json['total_nla'] as num).toDouble(),
  leasedNla: (json['leased_nla'] as num).toDouble(),
);

Map<String, dynamic> _$PropertyTypeStatsModelToJson(
  _PropertyTypeStatsModel instance,
) => <String, dynamic>{
  'property_type': instance.propertyType,
  'total_units': instance.totalUnits,
  'leased_units': instance.leasedUnits,
  'vacant_units': instance.vacantUnits,
  'expiring_soon_units': instance.expiringSoonUnits,
  'occupancy_rate': instance.occupancyRate,
  'total_nla': instance.totalNla,
  'leased_nla': instance.leasedNla,
};

_AssetOverviewModel _$AssetOverviewModelFromJson(Map<String, dynamic> json) =>
    _AssetOverviewModel(
      totalUnits: (json['total_units'] as num).toInt(),
      totalLeasableUnits: (json['total_leasable_units'] as num).toInt(),
      totalOccupancyRate: (json['total_occupancy_rate'] as num).toDouble(),
      waleIncomeWeighted: (json['wale_income_weighted'] as num).toDouble(),
      waleAreaWeighted: (json['wale_area_weighted'] as num).toDouble(),
      byPropertyType: (json['by_property_type'] as List<dynamic>)
          .map(
            (e) => PropertyTypeStatsModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$AssetOverviewModelToJson(_AssetOverviewModel instance) =>
    <String, dynamic>{
      'total_units': instance.totalUnits,
      'total_leasable_units': instance.totalLeasableUnits,
      'total_occupancy_rate': instance.totalOccupancyRate,
      'wale_income_weighted': instance.waleIncomeWeighted,
      'wale_area_weighted': instance.waleAreaWeighted,
      'by_property_type': instance.byPropertyType,
    };
