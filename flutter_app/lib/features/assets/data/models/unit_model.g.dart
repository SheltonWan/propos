// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitSummaryModel _$UnitSummaryModelFromJson(Map<String, dynamic> json) =>
    _UnitSummaryModel(
      id: json['id'] as String,
      buildingId: json['building_id'] as String,
      buildingName: json['building_name'] as String,
      floorId: json['floor_id'] as String,
      floorName: json['floor_name'] as String?,
      unitNumber: json['unit_number'] as String,
      propertyType: json['property_type'] as String,
      grossArea: (json['gross_area'] as num?)?.toDouble(),
      netArea: (json['net_area'] as num?)?.toDouble(),
      currentStatus: json['current_status'] as String,
      isLeasable: json['is_leasable'] as bool,
      decorationStatus: json['decoration_status'] as String,
      marketRentReference: (json['market_rent_reference'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$UnitSummaryModelToJson(_UnitSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'building_id': instance.buildingId,
      'building_name': instance.buildingName,
      'floor_id': instance.floorId,
      'floor_name': instance.floorName,
      'unit_number': instance.unitNumber,
      'property_type': instance.propertyType,
      'gross_area': instance.grossArea,
      'net_area': instance.netArea,
      'current_status': instance.currentStatus,
      'is_leasable': instance.isLeasable,
      'decoration_status': instance.decorationStatus,
      'market_rent_reference': instance.marketRentReference,
      'created_at': instance.createdAt,
    };

_UnitDetailModel _$UnitDetailModelFromJson(Map<String, dynamic> json) =>
    _UnitDetailModel(
      id: json['id'] as String,
      buildingId: json['building_id'] as String,
      buildingName: json['building_name'] as String,
      floorId: json['floor_id'] as String,
      floorName: json['floor_name'] as String?,
      unitNumber: json['unit_number'] as String,
      propertyType: json['property_type'] as String,
      grossArea: (json['gross_area'] as num?)?.toDouble(),
      netArea: (json['net_area'] as num?)?.toDouble(),
      orientation: json['orientation'] as String?,
      ceilingHeight: (json['ceiling_height'] as num?)?.toDouble(),
      decorationStatus: json['decoration_status'] as String,
      currentStatus: json['current_status'] as String,
      isLeasable: json['is_leasable'] as bool,
      extFields: json['ext_fields'] as Map<String, dynamic>?,
      currentContractId: json['current_contract_id'] as String?,
      qrCode: json['qr_code'] as String?,
      marketRentReference: (json['market_rent_reference'] as num?)?.toDouble(),
      predecessorUnitIds:
          (json['predecessor_unit_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$UnitDetailModelToJson(_UnitDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'building_id': instance.buildingId,
      'building_name': instance.buildingName,
      'floor_id': instance.floorId,
      'floor_name': instance.floorName,
      'unit_number': instance.unitNumber,
      'property_type': instance.propertyType,
      'gross_area': instance.grossArea,
      'net_area': instance.netArea,
      'orientation': instance.orientation,
      'ceiling_height': instance.ceilingHeight,
      'decoration_status': instance.decorationStatus,
      'current_status': instance.currentStatus,
      'is_leasable': instance.isLeasable,
      'ext_fields': instance.extFields,
      'current_contract_id': instance.currentContractId,
      'qr_code': instance.qrCode,
      'market_rent_reference': instance.marketRentReference,
      'predecessor_unit_ids': instance.predecessorUnitIds,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
