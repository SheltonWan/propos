import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/api_list_response.dart';
import '../../core/constants/ui_constants.dart';
import 'paginated_state.dart';

/// 通用分页列表 Cubit — 消除各列表模块的样板代码。
///
/// 子类只需实现 [fetchPage] 提供数据源即可。
///
/// 示例：
/// ```dart
/// class ContractListCubit extends PaginatedCubit<Contract> {
///   final ContractRepository _repository;
///   ContractListCubit(this._repository);
///
///   @override
///   Future<ApiListResponse<Contract>> fetchPage(int page, int pageSize) =>
///       _repository.getContracts(page: page, pageSize: pageSize);
/// }
/// ```
abstract class PaginatedCubit<T> extends Cubit<PaginatedState<T>> {
  PaginatedCubit() : super(const PaginatedState.initial());

  /// 子类实现此方法，调用对应 Repository 的分页查询。
  Future<ApiListResponse<T>> fetchPage(int page, int pageSize);

  /// 加载或重新加载第一页。
  Future<void> load({int pageSize = UiConstants.defaultPageSize}) async {
    emit(PaginatedState<T>.loading());
    try {
      final result = await fetchPage(1, pageSize);
      emit(PaginatedState.loaded(result.items, meta: result.meta));
    } catch (e) {
      emit(PaginatedState.error(
        e is ApiException ? e.message : '加载失败，请重试',
      ));
    }
  }

  /// 加载下一页（追加模式，用于无限滚动）。
  ///
  /// 非 `loaded` 状态或无更多数据时不执行。
  Future<void> loadMore() async {
    final current = state;
    if (current is! PaginatedLoaded<T>) return;
    if (!current.meta.hasMore) return;

    final nextPage = current.meta.page + 1;
    try {
      final result = await fetchPage(nextPage, current.meta.pageSize);
      emit(PaginatedState.loaded(
        [...current.items, ...result.items],
        meta: result.meta,
      ));
    } catch (_) {
      // 保留已有数据不变，不 emit 新状态。
      // 调用方可通过 snackbar 等机制展示瞬态错误。
    }
  }

  /// 下拉刷新：从第 1 页重新加载，保留当前 pageSize。
  Future<void> refresh() async {
    final pageSize = state is PaginatedLoaded<T>
        ? (state as PaginatedLoaded<T>).meta.pageSize
        : UiConstants.defaultPageSize;
    await load(pageSize: pageSize);
  }
}
