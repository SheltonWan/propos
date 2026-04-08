/// 分页结果通用容器
class PaginatedResult<T> {
  final List<T> items;
  final PaginationMeta meta;

  const PaginatedResult({required this.items, required this.meta});
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
        'total': total,
      };

  /// 根据 page / pageSize 计算 SQL OFFSET
  int get offset => (page - 1) * pageSize;
}
