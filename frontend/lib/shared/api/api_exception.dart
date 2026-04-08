/// API 调用异常 — 网络层统一包装，不透传 DioException
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromResponse(Map<String, dynamic> json, int statusCode) {
    final error = json['error'] as Map<String, dynamic>?;
    return ApiException(
      code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error?['message'] as String? ?? '未知错误',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException[$statusCode]($code): $message';
}
