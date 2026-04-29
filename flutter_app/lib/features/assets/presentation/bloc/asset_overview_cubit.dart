import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';
import '../../domain/repositories/assets_repository.dart';
import 'asset_overview_state.dart';

/// 资产概览页 Cubit。
///
/// 并行拉取概览统计和楼栋列表，二者全部成功后一次性 emit loaded 状态。
class AssetOverviewCubit extends Cubit<AssetOverviewState> {
  final AssetsRepository _repository;

  AssetOverviewCubit(this._repository) : super(const AssetOverviewState.initial());

  /// 并行加载资产概览 + 楼栋列表。
  Future<void> fetch() async {
    emit(const AssetOverviewState.loading());
    try {
      final overviewFuture = _repository.fetchOverview();
      final buildingsFuture = _repository.fetchBuildings();
      final AssetOverview overview = await overviewFuture;
      final List<Building> buildings = await buildingsFuture;
      emit(AssetOverviewState.loaded(
        overview: overview,
        buildings: buildings,
      ));
    } catch (e) {
      emit(AssetOverviewState.error(
        e is ApiException ? e.message : '操作失败，请重试',
      ));
    }
  }
}
