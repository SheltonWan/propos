import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/property_type.dart';

part 'asset_overview_model.freezed.dart';
part 'asset_overview_model.g.dart';

/// PropertyTypeStats DTO（对应 API_CONTRACT v1.7 §2.23）。
@freezed
abstract class PropertyTypeStatsModel with _$PropertyTypeStatsModel {
  const factory PropertyTypeStatsModel({
    @JsonKey(name: 'property_type') required String propertyType,
    @JsonKey(name: 'total_units') required int totalUnits,
    @JsonKey(name: 'leased_units') required int leasedUnits,
    @JsonKey(name: 'vacant_units') required int vacantUnits,
    @JsonKey(name: 'expiring_soon_units') required int expiringSoonUnits,
    @JsonKey(name: 'occupancy_rate') required double occupancyRate,
    @JsonKey(name: 'total_nla') required double totalNla,
    @JsonKey(name: 'leased_nla') required double leasedNla,
  }) = _PropertyTypeStatsModel;

  factory PropertyTypeStatsModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyTypeStatsModelFromJson(json);
}

/// AssetOverview DTO（对应 API_CONTRACT v1.7 §2.23）。
@freezed
abstract class AssetOverviewModel with _$AssetOverviewModel {
  const factory AssetOverviewModel({
    @JsonKey(name: 'total_units') required int totalUnits,
    @JsonKey(name: 'total_leasable_units') required int totalLeasableUnits,
    @JsonKey(name: 'total_occupancy_rate') required double totalOccupancyRate,
    @JsonKey(name: 'wale_income_weighted') required double waleIncomeWeighted,
    @JsonKey(name: 'wale_area_weighted') required double waleAreaWeighted,
    @JsonKey(name: 'by_property_type')
    required List<PropertyTypeStatsModel> byPropertyType,
  }) = _AssetOverviewModel;

  factory AssetOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$AssetOverviewModelFromJson(json);
}

extension AssetOverviewModelX on AssetOverviewModel {
  AssetOverview toEntity() => AssetOverview(
        totalUnits: totalUnits,
        totalLeasableUnits: totalLeasableUnits,
        totalOccupancyRate: totalOccupancyRate,
        waleIncomeWeighted: waleIncomeWeighted,
        waleAreaWeighted: waleAreaWeighted,
        byPropertyType:
            byPropertyType.map((e) => e.toEntity()).toList(),
      );
}

extension PropertyTypeStatsModelX on PropertyTypeStatsModel {
  PropertyTypeStats toEntity() => PropertyTypeStats(
        propertyType: PropertyType.fromString(propertyType),
        totalUnits: totalUnits,
        leasedUnits: leasedUnits,
        vacantUnits: vacantUnits,
        expiringSoonUnits: expiringSoonUnits,
        occupancyRate: occupancyRate,
        totalNla: totalNla,
        leasedNla: leasedNla,
      );
}
