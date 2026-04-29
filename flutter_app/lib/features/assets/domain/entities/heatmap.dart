import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_type.dart';
import 'unit_status.dart';

part 'heatmap.freezed.dart';

/// 楼层热区单元（SVG 热区图中的一个房源色块）。
///
/// 对应 API_CONTRACT v1.7 §2.9 HeatmapUnit。
@freezed
abstract class HeatmapUnit with _$HeatmapUnit {
  const factory HeatmapUnit({
    required String unitId,
    required String unitNumber,
    required UnitStatus currentStatus,
    required PropertyType propertyType,
    String? tenantName,
    DateTime? contractEndDate,
  }) = _HeatmapUnit;
}

/// 楼层热区图数据（SVG 路径 + 单元状态列表）。
///
/// 对应 API_CONTRACT v1.7 §2.9 FloorHeatmap。
@freezed
abstract class FloorHeatmap with _$FloorHeatmap {
  const factory FloorHeatmap({
    required String floorId,
    String? svgPath,
    required List<HeatmapUnit> units,
  }) = _FloorHeatmap;
}
