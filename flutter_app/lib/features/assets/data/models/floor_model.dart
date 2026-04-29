import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/floor.dart';

part 'floor_model.freezed.dart';
part 'floor_model.g.dart';

/// FloorSummary DTO（对应 API_CONTRACT v1.7 §2.5）。
@freezed
abstract class FloorModel with _$FloorModel {
  const factory FloorModel({
    required String id,
    @JsonKey(name: 'building_id') required String buildingId,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'floor_number') required int floorNumber,
    @JsonKey(name: 'floor_name') String? floorName,
    @JsonKey(name: 'svg_path') String? svgPath,
    @JsonKey(name: 'png_path') String? pngPath,
    double? nla,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _FloorModel;

  factory FloorModel.fromJson(Map<String, dynamic> json) =>
      _$FloorModelFromJson(json);
}

extension FloorModelX on FloorModel {
  Floor toEntity() => Floor(
        id: id,
        buildingId: buildingId,
        buildingName: buildingName,
        floorNumber: floorNumber,
        floorName: floorName,
        svgPath: svgPath,
        pngPath: pngPath,
        nla: nla,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
