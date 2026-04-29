import 'package:freezed_annotation/freezed_annotation.dart';

part 'floor.freezed.dart';

/// 楼层实体（领域层，纯 Dart，无 Flutter SDK 依赖）。
///
/// 对应 API_CONTRACT v1.7 §2.5 FloorSummary。
@freezed
abstract class Floor with _$Floor {
  const factory Floor({
    required String id,
    required String buildingId,
    required String buildingName,
    required int floorNumber,
    String? floorName,
    String? svgPath,
    String? pngPath,
    double? nla,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Floor;

  const Floor._();

  /// 展示名：优先用 floorName，否则 "${floorNumber}F"。
  String get displayName => floorName ?? '${floorNumber}F';
}
