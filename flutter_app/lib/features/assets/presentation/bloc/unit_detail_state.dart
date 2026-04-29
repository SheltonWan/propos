import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/renovation.dart';
import '../../domain/entities/unit.dart';

part 'unit_detail_state.freezed.dart';

/// 房源详情页 BLoC 状态（四态 sealed union）。
@freezed
sealed class UnitDetailState with _$UnitDetailState {
  const factory UnitDetailState.initial() = UnitDetailStateInitial;
  const factory UnitDetailState.loading() = UnitDetailStateLoading;
  const factory UnitDetailState.loaded({
    required UnitDetail unit,
    required List<RenovationSummary> renovations,
  }) = UnitDetailStateLoaded;
  const factory UnitDetailState.error(String message) = UnitDetailStateError;
}
