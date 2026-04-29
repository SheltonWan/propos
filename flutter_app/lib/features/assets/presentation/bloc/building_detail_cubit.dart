import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';
import '../../domain/repositories/assets_repository.dart';
import 'building_detail_state.dart';

/// 楼栋详情页 Cubit。
///
/// 并行拉取楼栋信息和楼层列表。
class BuildingDetailCubit extends Cubit<BuildingDetailState> {
  final AssetsRepository _repository;

  BuildingDetailCubit(this._repository)
      : super(const BuildingDetailState.initial());

  /// 加载指定 [buildingId] 的楼栋详情 + 楼层列表。
  Future<void> fetch(String buildingId) async {
    emit(const BuildingDetailState.loading());
    try {
      final buildingFuture = _repository.fetchBuilding(buildingId);
      final floorsFuture = _repository.fetchFloors(buildingId);
      final Building building = await buildingFuture;
      final List<Floor> floors = await floorsFuture;
      emit(BuildingDetailState.loaded(
        building: building,
        floors: floors,
      ));
    } catch (e) {
      emit(BuildingDetailState.error(
        e is ApiException ? e.message : '操作失败，请重试',
      ));
    }
  }
}
