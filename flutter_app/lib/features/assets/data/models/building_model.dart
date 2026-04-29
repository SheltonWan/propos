import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/building.dart';
import '../../domain/entities/property_type.dart';

part 'building_model.freezed.dart';
part 'building_model.g.dart';

/// BuildingSummary DTO（对应 API_CONTRACT v1.7 §2.1）。
@freezed
abstract class BuildingModel with _$BuildingModel {
  const factory BuildingModel({
    required String id,
    required String name,
    @JsonKey(name: 'property_type') required String propertyType,
    @JsonKey(name: 'total_floors') required int totalFloors,
    @JsonKey(name: 'basement_floors') @Default(0) int basementFloors,
    required double gfa,
    required double nla,
    String? address,
    @JsonKey(name: 'built_year') int? builtYear,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _BuildingModel;

  factory BuildingModel.fromJson(Map<String, dynamic> json) =>
      _$BuildingModelFromJson(json);
}

extension BuildingModelX on BuildingModel {
  Building toEntity() => Building(
        id: id,
        name: name,
        propertyType: PropertyType.fromString(propertyType),
        totalFloors: totalFloors,
        basementFloors: basementFloors,
        gfa: gfa,
        nla: nla,
        address: address,
        builtYear: builtYear,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
