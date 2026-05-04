import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/repositories/assets_repository.dart';
import 'floor_map_state.dart';

/// 楼层平面图页 Cubit。
///
/// 支持两种初始化方式：
///   - [fetch]：直接加载指定 floorId（路由传参时使用）
///   - [loadByBuilding]：先加载楼栋楼层列表，再加载第一层（或指定层）
/// 楼层切换通过 [selectFloor] 实现，复用已缓存的楼层列表。
class FloorMapCubit extends Cubit<FloorMapState> {
  final AssetsRepository _repository;

  FloorMapCubit(this._repository) : super(const FloorMapState.initial());

  /// 加载指定 [floorId] 的楼层信息 + 热区数据。
  ///
  /// 若当前 state 为 [FloorMapStateLoaded]，则保留已有的 floors 列表，
  /// 否则只加载单楼层信息（无楼层切换标签栏）。
  Future<void> fetch(String floorId) async {
    // 保留已有楼层列表（切换楼层时复用）
    final prevFloors = switch (state) {
      FloorMapStateLoaded(:final floors) => floors,
      _ => <Floor>[],
    };

    emit(const FloorMapState.loading());
    try {
      final floorFuture = _repository.fetchFloor(floorId);
      final heatmapFuture = _repository.fetchFloorHeatmap(floorId);
      final Floor floor = await floorFuture;
      final FloorHeatmap heatmap = await heatmapFuture;

      // 若还没有楼层列表，尝试按楼栋拉取（以便显示标签栏）。
      List<Floor> floors = prevFloors;
      if (floors.isEmpty) {
        try {
          floors = await _repository.fetchFloors(floor.buildingId);
        } catch (_) {
          // 拉取失败不阻断主流程，标签栏隐藏即可。
        }
      }

      emit(
        FloorMapState.loaded(floor: floor, heatmap: heatmap, floors: floors),
      );
    } catch (e) {
      emit(FloorMapState.error(e is ApiException ? e.message : '操作失败，请重试'));
    }
  }

  /// 先按 [buildingId] 拉取楼层列表，再加载 [initialFloorId]（或列表第一层）的热区数据。
  Future<void> loadByBuilding(
    String buildingId, {
    String? initialFloorId,
  }) async {
    emit(const FloorMapState.loading());
    try {
      final floors = await _repository.fetchFloors(buildingId);
      if (floors.isEmpty) {
        emit(const FloorMapState.error('该楼栋暂无楼层数据'));
        return;
      }
      final targetId = initialFloorId ?? floors.first.id;
      final floor = floors.firstWhere(
        (f) => f.id == targetId,
        orElse: () => floors.first,
      );
      final heatmap = await _repository.fetchFloorHeatmap(floor.id);
      emit(
        FloorMapState.loaded(floor: floor, heatmap: heatmap, floors: floors),
      );
    } catch (e) {
      emit(FloorMapState.error(
        e is ApiException ? e.message : '操作失败，请重试',
      ));
    }
  }

  /// 切换到另一楼层，保留已有楼层列表（不重复请求）。
  Future<void> selectFloor(String floorId) async {
    if (state case FloorMapStateLoaded(:final floor) when floor.id == floorId) {
      return; // 已是当前楼层，无需重复加载
    }
    await fetch(floorId);
  }
}

