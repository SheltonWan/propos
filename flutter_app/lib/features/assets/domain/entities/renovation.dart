import 'package:freezed_annotation/freezed_annotation.dart';

part 'renovation.freezed.dart';

/// 改造记录摘要实体。
///
/// 对应 API_CONTRACT v1.7 §2.17 RenovationSummary。
@freezed
abstract class RenovationSummary with _$RenovationSummary {
  const factory RenovationSummary({
    required String id,
    required String unitId,
    required String unitNumber,
    required String renovationType,
    required DateTime startedAt,
    DateTime? completedAt,
    double? cost,
    String? contractor,
    required DateTime createdAt,
  }) = _RenovationSummary;
}
