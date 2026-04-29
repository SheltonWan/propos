import 'package:freezed_annotation/freezed_annotation.dart';

import 'property_type.dart';

part 'building.freezed.dart';

/// 楼栋实体（领域层，纯 Dart，无 Flutter SDK 依赖）。
///
/// 对应 API_CONTRACT v1.7 §2.1 BuildingSummary。
@freezed
abstract class Building with _$Building {
  const factory Building({
    required String id,
    required String name,
    required PropertyType propertyType,
    required int totalFloors,
    @Default(0) int basementFloors,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Building;
}
