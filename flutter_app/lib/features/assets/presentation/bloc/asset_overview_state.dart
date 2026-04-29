import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';

part 'asset_overview_state.freezed.dart';

/// 资产概览页 BLoC 状态（四态 sealed union）。
@freezed
sealed class AssetOverviewState with _$AssetOverviewState {
  const factory AssetOverviewState.initial() = AssetOverviewStateInitial;
  const factory AssetOverviewState.loading() = AssetOverviewStateLoading;
  const factory AssetOverviewState.loaded({
    required AssetOverview overview,
    required List<Building> buildings,
  }) = AssetOverviewStateLoaded;
  const factory AssetOverviewState.error(String message) = AssetOverviewStateError;
}
