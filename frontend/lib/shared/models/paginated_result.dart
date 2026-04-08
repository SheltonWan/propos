/// 分页结果通用容器（Flutter 端 domain 层，纯 Dart）
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

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
      );

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
        'total': total,
      };
}
