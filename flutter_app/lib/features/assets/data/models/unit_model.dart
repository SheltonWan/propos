import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/property_type.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_status.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

/// UnitSummary DTO（对应 API_CONTRACT v1.7 §2.12，列表场景）。
@freezed
abstract class UnitSummaryModel with _$UnitSummaryModel {
  const factory UnitSummaryModel({
    required String id,
    @JsonKey(name: 'building_id') required String buildingId,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'floor_id') required String floorId,
    @JsonKey(name: 'floor_name') String? floorName,
    @JsonKey(name: 'unit_number') required String unitNumber,
    @JsonKey(name: 'property_type') required String propertyType,
    @JsonKey(name: 'gross_area') double? grossArea,
    @JsonKey(name: 'net_area') double? netArea,
    @JsonKey(name: 'current_status') required String currentStatus,
    @JsonKey(name: 'is_leasable') required bool isLeasable,
    @JsonKey(name: 'decoration_status') required String decorationStatus,
    @JsonKey(name: 'market_rent_reference') double? marketRentReference,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _UnitSummaryModel;

  factory UnitSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$UnitSummaryModelFromJson(json);
}

extension UnitSummaryModelX on UnitSummaryModel {
  UnitSummary toEntity() => UnitSummary(
        id: id,
        buildingId: buildingId,
        buildingName: buildingName,
        floorId: floorId,
        floorName: floorName,
        unitNumber: unitNumber,
        propertyType: PropertyType.fromString(propertyType),
        grossArea: grossArea,
        netArea: netArea,
        currentStatus: UnitStatus.fromString(currentStatus),
        isLeasable: isLeasable,
        decorationStatus: DecorationStatus.fromString(decorationStatus),
        marketRentReference: marketRentReference,
        createdAt: DateTime.parse(createdAt),
      );
}

/// UnitDetail DTO（对应 API_CONTRACT v1.7 §2.14）。
@freezed
abstract class UnitDetailModel with _$UnitDetailModel {
  const factory UnitDetailModel({
    required String id,
    @JsonKey(name: 'building_id') required String buildingId,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'floor_id') required String floorId,
    @JsonKey(name: 'floor_name') String? floorName,
    @JsonKey(name: 'unit_number') required String unitNumber,
    @JsonKey(name: 'property_type') required String propertyType,
    @JsonKey(name: 'gross_area') double? grossArea,
    @JsonKey(name: 'net_area') double? netArea,
    String? orientation,
    @JsonKey(name: 'ceiling_height') double? ceilingHeight,
    @JsonKey(name: 'decoration_status') required String decorationStatus,
    @JsonKey(name: 'current_status') required String currentStatus,
    @JsonKey(name: 'is_leasable') required bool isLeasable,
    @JsonKey(name: 'ext_fields') Map<String, dynamic>? extFields,
    @JsonKey(name: 'current_contract_id') String? currentContractId,
    @JsonKey(name: 'qr_code') String? qrCode,
    @JsonKey(name: 'market_rent_reference') double? marketRentReference,
    @JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[])
    @Default(<String>[])
    List<String> predecessorUnitIds,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _UnitDetailModel;

  factory UnitDetailModel.fromJson(Map<String, dynamic> json) =>
      _$UnitDetailModelFromJson(json);
}

extension UnitDetailModelX on UnitDetailModel {
  UnitDetail toEntity() => UnitDetail(
        id: id,
        buildingId: buildingId,
        buildingName: buildingName,
        floorId: floorId,
        floorName: floorName,
        unitNumber: unitNumber,
        propertyType: PropertyType.fromString(propertyType),
        grossArea: grossArea,
        netArea: netArea,
        orientation: orientation,
        ceilingHeight: ceilingHeight,
        decorationStatus: DecorationStatus.fromString(decorationStatus),
        currentStatus: UnitStatus.fromString(currentStatus),
        isLeasable: isLeasable,
        extFields: extFields,
        currentContractId: currentContractId,
        qrCode: qrCode,
        marketRentReference: marketRentReference,
        predecessorUnitIds: predecessorUnitIds,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
