import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/repositories/assets_repository.dart';
import 'floor_map_state.dart';

/// 楼层平面图页 Cubit。
///
/// 并行拉取楼层信息和热区数据。
class FloorMapCubit extends Cubit<FloorMapState> {
  final AssetsRepository _repository;

  FloorMapCubit(this._repository) : super(const FloorMapState.initial());

  /// 加载指定 [floorId] 的楼层信息 + 热区数据。
  Future<void> fetch(String floorId) async {
    emit(const FloorMapState.loading());
    try {
      final floorFuture = _repository.fetchFloor(floorId);
      final heatmapFuture = _repository.fetchFloorHeatmap(floorId);
      final Floor floor = await floorFuture;
      final FloorHeatmap heatmap = await heatmapFuture;
      emit(FloorMapState.loaded(floor: floor, heatmap: heatmap));
    } catch (e) {
      emit(FloorMapState.error(
        e is ApiException ? e.message : '操作失败，请重试',
      ));
    }
  }
}
