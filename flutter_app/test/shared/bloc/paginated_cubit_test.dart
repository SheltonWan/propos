import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/core/api/api_list_response.dart';
import 'package:propos_app/shared/bloc/paginated_cubit.dart';
import 'package:propos_app/shared/bloc/paginated_state.dart';

// ── 测试替身 ──

class _TestItem {
  final String id;
  const _TestItem(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _TestItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class _TestCubit extends PaginatedCubit<_TestItem> {
  final Future<ApiListResponse<_TestItem>> Function(int page, int pageSize)
      onFetchPage;

  _TestCubit(this.onFetchPage);

  @override
  Future<ApiListResponse<_TestItem>> fetchPage(int page, int pageSize) =>
      onFetchPage(page, pageSize);
}

// ── 辅助工具 ──

ApiListResponse<_TestItem> _makeResponse({
  required int page,
  int pageSize = 20,
  required int total,
  required List<_TestItem> items,
}) =>
    ApiListResponse(
      items: items,
      meta: PaginationMeta(page: page, pageSize: pageSize, total: total),
    );

const _meta1 = PaginationMeta(page: 1, pageSize: 20, total: 40);
const _meta2 = PaginationMeta(page: 2, pageSize: 20, total: 40);
const _metaLast = PaginationMeta(page: 2, pageSize: 20, total: 40);

final _page1Items = List.generate(20, (i) => _TestItem('item_$i'));
final _page2Items = List.generate(20, (i) => _TestItem('item_${i + 20}'));

void main() {
  group('PaginatedCubit', () {
    // ── load ──

    /// 正常加载：依次 emit loading → loaded，携带正确的列表数据和分页 meta。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'load emits [loading, loaded] on success',
      build: () => _TestCubit(
        (page, pageSize) async => _makeResponse(
          page: page,
          pageSize: pageSize,
          total: 40,
          items: _page1Items,
        ),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PaginatedState<_TestItem>.loading(),
        PaginatedState.loaded(_page1Items, meta: _meta1),
      ],
    );

    /// ApiException 错误：emit error 状态并透传异常中的 message 字段。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'load emits [loading, error] with ApiException message',
      build: () => _TestCubit(
        (_, _) async => throw const ApiException(
          code: 'INTERNAL_ERROR',
          message: '服务异常',
          statusCode: 500,
        ),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PaginatedState<_TestItem>.loading(),
        const PaginatedState<_TestItem>.error('服务异常'),
      ],
    );

    /// 非 API 异常（如网络错误）：emit error 状态并使用兜底提示文案。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'load emits [loading, error] with fallback message on non-API error',
      build: () => _TestCubit(
        (_, _) async => throw Exception('network'),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PaginatedState<_TestItem>.loading(),
        const PaginatedState<_TestItem>.error('加载失败，请重试'),
      ],
    );

    // ── loadMore ──

    /// 加载下一页成功：将新数据追加到已有列表，更新 meta 为第 2 页。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'loadMore appends items and updates meta',
      build: () => _TestCubit(
        (page, pageSize) async => _makeResponse(
          page: page,
          pageSize: pageSize,
          total: 40,
          items: _page2Items,
        ),
      ),
      seed: () => PaginatedState.loaded(_page1Items, meta: _meta1),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        PaginatedState.loaded(
          [..._page1Items, ..._page2Items],
          meta: _meta2,
        ),
      ],
    );

    /// 无更多分页（hasMore=false）时调用 loadMore 不发起请求、不 emit 新状态。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'loadMore is no-op when no more pages',
      build: () => _TestCubit(
        (_, _) async => throw StateError('should not be called'),
      ),
      seed: () => PaginatedState.loaded(_page1Items, meta: _metaLast),
      act: (cubit) => cubit.loadMore(),
      expect: () => <PaginatedState<_TestItem>>[],
    );

    /// 非 loaded 状态（如 initial）时调用 loadMore 不发起请求、不 emit 新状态。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'loadMore is no-op when state is not loaded',
      build: () => _TestCubit(
        (_, _) async => throw StateError('should not be called'),
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => <PaginatedState<_TestItem>>[],
    );

    /// loadMore 请求失败时保留已有数据不变，不 emit 新状态（UI 可通过 snackbar 展示错误）。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'loadMore keeps existing data on error (no emission)',
      build: () => _TestCubit(
        (_, _) async => throw const ApiException(
          code: 'TIMEOUT',
          message: '超时',
          statusCode: 504,
        ),
      ),
      seed: () => PaginatedState.loaded(_page1Items, meta: _meta1),
      act: (cubit) => cubit.loadMore(),
      expect: () => <PaginatedState<_TestItem>>[],
    );

    // ── refresh ──

    /// 下拉刷新：保留当前 pageSize，从第 1 页重新请求，emit loading → loaded。
    blocTest<_TestCubit, PaginatedState<_TestItem>>(
      'refresh reloads from page 1 keeping pageSize',
      build: () {
        return _TestCubit((page, pageSize) async {
          // 验证请求的是第 1 页
          expect(page, 1);
          expect(pageSize, 20);
          return _makeResponse(
            page: 1,
            pageSize: 20,
            total: 5,
            items: [const _TestItem('fresh')],
          );
        });
      },
      seed: () => PaginatedState.loaded(
        _page1Items,
        meta: _meta1,
      ),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const PaginatedState<_TestItem>.loading(),
        const PaginatedState.loaded(
          [_TestItem('fresh')],
          meta: PaginationMeta(page: 1, pageSize: 20, total: 5),
        ),
      ],
    );
  });
}
