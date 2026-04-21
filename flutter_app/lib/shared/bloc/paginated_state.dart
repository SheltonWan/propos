import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/api/api_list_response.dart';

part 'paginated_state.freezed.dart';

/// 通用分页列表状态 — sealed union 四态。
///
/// 配合 [PaginatedCubit] 使用，消除各列表模块的样板代码。
/// [T] 为 domain 层实体类型（如 `Contract`、`Unit`、`Invoice`）。
@Freezed(genericArgumentFactories: true)
abstract class PaginatedState<T> with _$PaginatedState<T> {
  const factory PaginatedState.initial() = PaginatedInitial<T>;
  const factory PaginatedState.loading() = PaginatedLoading<T>;
  const factory PaginatedState.loaded(
    List<T> items, {
    required PaginationMeta meta,
  }) = PaginatedLoaded<T>;
  const factory PaginatedState.error(String message) = PaginatedError<T>;
}
