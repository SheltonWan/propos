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
    /// SVG 文件内容（已从 Repository 获取，widget 层直接使用，无需再发 HTTP 请求）。
    @Default('') String svgContent,
    /// 同楼栋下所有楼层列表，用于楼层切换标签栏。
    @Default([]) List<Floor> floors,
    /// 是否正在切换楼层（Hold & Replace 模式）。
    ///
    /// `true` 时 UI 保留当前楼层图，在目标楼层 Tab 上显示加载动画，
    /// 新楼层数据就绪后平滑替换。
    @Default(false) bool isSwitching,
    /// 正在加载的目标楼层 ID（[isSwitching] 为 `true` 时有效）。
    String? switchingToFloorId,
  }) = FloorMapStateLoaded;
  const factory FloorMapState.error(String message) = FloorMapStateError;
}
