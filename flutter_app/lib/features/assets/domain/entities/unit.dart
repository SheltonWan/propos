import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_type.dart';
import 'unit_status.dart';

part 'unit.freezed.dart';

/// 房源摘要实体（列表场景使用）。
///
/// 对应 API_CONTRACT v1.7 §2.12 UnitSummary。
@freezed
abstract class UnitSummary with _$UnitSummary {
  const factory UnitSummary({
    required String id,
    required String buildingId,
    required String buildingName,
    required String floorId,
    String? floorName,
    required String unitNumber,
    required PropertyType propertyType,
    double? grossArea,
    double? netArea,
    required UnitStatus currentStatus,
    required bool isLeasable,
    required DecorationStatus decorationStatus,
    double? marketRentReference,
    required DateTime createdAt,
  }) = _UnitSummary;
}

/// 房源完整详情实体（详情页使用）。
///
/// 对应 API_CONTRACT v1.7 §2.14 UnitDetail。
@freezed
abstract class UnitDetail with _$UnitDetail {
  const factory UnitDetail({
    required String id,
    required String buildingId,
    required String buildingName,
    required String floorId,
    String? floorName,
    required String unitNumber,
    required PropertyType propertyType,
    double? grossArea,
    double? netArea,
    String? orientation,
    double? ceilingHeight,
    required DecorationStatus decorationStatus,
    required UnitStatus currentStatus,
    required bool isLeasable,
    Map<String, dynamic>? extFields,
    String? currentContractId,
    String? qrCode,
    double? marketRentReference,
    @Default([]) List<String> predecessorUnitIds,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UnitDetail;
}
