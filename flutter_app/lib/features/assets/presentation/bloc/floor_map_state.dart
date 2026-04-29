import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';

part 'floor_map_state.freezed.dart';

/// 楼层平面图页 BLoC 状态（四态 sealed union）。
@freezed
sealed class FloorMapState with _$FloorMapState {
  const factory FloorMapState.initial() = FloorMapStateInitial;
  const factory FloorMapState.loading() = FloorMapStateLoading;
  const factory FloorMapState.loaded({
    required Floor floor,
    required FloorHeatmap heatmap,
  }) = FloorMapStateLoaded;
  const factory FloorMapState.error(String message) = FloorMapStateError;
}
