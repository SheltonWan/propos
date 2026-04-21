/// API 请求失败时抛出的异常。
///
/// [ApiClient] 中所有 [DioException] 均被转换为此异常向上传播。
/// [lockedUntil] 仅在 code == 'ACCOUNT_LOCKED' 时有值，
/// 表示账号解锁时间（UTC），由后端 error.locked_until 字段提供。
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  /// 账号锁定解除时间（UTC），仅 ACCOUNT_LOCKED 时非 null。
  final DateTime? lockedUntil;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.lockedUntil,
  });

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
