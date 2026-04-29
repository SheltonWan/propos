import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/renovation.dart';

part 'renovation_model.freezed.dart';
part 'renovation_model.g.dart';

/// RenovationSummary DTO（对应 API_CONTRACT v1.7 §2.17）。
@freezed
abstract class RenovationSummaryModel with _$RenovationSummaryModel {
  const factory RenovationSummaryModel({
    required String id,
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'unit_number') required String unitNumber,
    @JsonKey(name: 'renovation_type') required String renovationType,
    @JsonKey(name: 'started_at') required String startedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    double? cost,
    String? contractor,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _RenovationSummaryModel;

  factory RenovationSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$RenovationSummaryModelFromJson(json);
}

extension RenovationSummaryModelX on RenovationSummaryModel {
  RenovationSummary toEntity() => RenovationSummary(
        id: id,
        unitId: unitId,
        unitNumber: unitNumber,
        renovationType: renovationType,
        startedAt: DateTime.parse(startedAt),
        completedAt:
            completedAt != null ? DateTime.tryParse(completedAt!) : null,
        cost: cost,
        contractor: contractor,
        createdAt: DateTime.parse(createdAt),
      );
}
