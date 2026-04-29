import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/renovation.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/assets_repository.dart';
import 'unit_detail_state.dart';

/// 房源详情页 Cubit。
///
/// 并行拉取房源信息和改造记录。
class UnitDetailCubit extends Cubit<UnitDetailState> {
  final AssetsRepository _repository;

  UnitDetailCubit(this._repository) : super(const UnitDetailState.initial());

  /// 加载指定 [unitId] 的房源详情 + 改造记录。
  Future<void> fetch(String unitId) async {
    emit(const UnitDetailState.loading());
    try {
      final unitFuture = _repository.fetchUnit(unitId);
      final renovationsFuture = _repository.fetchRenovations(unitId);
      final UnitDetail unit = await unitFuture;
      final List<RenovationSummary> renovations = await renovationsFuture;
      emit(UnitDetailState.loaded(unit: unit, renovations: renovations));
    } catch (e) {
      emit(UnitDetailState.error(
        e is ApiException ? e.message : '操作失败，请重试',
      ));
    }
  }
}
