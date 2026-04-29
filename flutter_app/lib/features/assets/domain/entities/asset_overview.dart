import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_type.dart';

part 'asset_overview.freezed.dart';

/// 单业态统计数据。
///
/// 对应 API_CONTRACT v1.7 §2.23 PropertyTypeStats。
@freezed
abstract class PropertyTypeStats with _$PropertyTypeStats {
  const factory PropertyTypeStats({
    required PropertyType propertyType,
    required int totalUnits,
    required int leasedUnits,
    required int vacantUnits,
    required int expiringSoonUnits,
    required double occupancyRate,
    required double totalNla,
    required double leasedNla,
  }) = _PropertyTypeStats;
}

/// 资产概览看板数据。
///
/// 对应 API_CONTRACT v1.7 §2.23 AssetOverview。
@freezed
abstract class AssetOverview with _$AssetOverview {
  const factory AssetOverview({
    required int totalUnits,
    required int totalLeasableUnits,
    required double totalOccupancyRate,
    required double waleIncomeWeighted,
    required double waleAreaWeighted,
    required List<PropertyTypeStats> byPropertyType,
  }) = _AssetOverview;
}
