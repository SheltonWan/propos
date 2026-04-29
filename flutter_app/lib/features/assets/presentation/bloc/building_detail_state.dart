import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';

part 'building_detail_state.freezed.dart';

/// 楼栋详情页 BLoC 状态（四态 sealed union）。
@freezed
sealed class BuildingDetailState with _$BuildingDetailState {
  const factory BuildingDetailState.initial() = BuildingDetailStateInitial;
  const factory BuildingDetailState.loading() = BuildingDetailStateLoading;
  const factory BuildingDetailState.loaded({
    required Building building,
    required List<Floor> floors,
  }) = BuildingDetailStateLoaded;
  const factory BuildingDetailState.error(String message) = BuildingDetailStateError;
}
