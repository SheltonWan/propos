/// Generic paginated list response matching the backend envelope format:
/// `{ "data": [...], "meta": { "page": 1, "pageSize": 20, "total": 639 } }`
class ApiListResponse<T> {
  final List<T> items;
  final PaginationMeta meta;

  const ApiListResponse({
    required this.items,
    required this.meta,
  });
}

/// Pagination metadata from the `meta` field in API responses.
class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  bool get hasMore => page * pageSize < total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
      );
}
