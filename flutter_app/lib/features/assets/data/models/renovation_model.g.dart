// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'renovation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RenovationSummaryModel _$RenovationSummaryModelFromJson(
  Map<String, dynamic> json,
) => _RenovationSummaryModel(
  id: json['id'] as String,
  unitId: json['unit_id'] as String,
  unitNumber: json['unit_number'] as String,
  renovationType: json['renovation_type'] as String,
  startedAt: json['started_at'] as String,
  completedAt: json['completed_at'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  contractor: json['contractor'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$RenovationSummaryModelToJson(
  _RenovationSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'unit_id': instance.unitId,
  'unit_number': instance.unitNumber,
  'renovation_type': instance.renovationType,
  'started_at': instance.startedAt,
  'completed_at': instance.completedAt,
  'cost': instance.cost,
  'contractor': instance.contractor,
  'created_at': instance.createdAt,
};
