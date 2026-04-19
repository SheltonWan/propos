/// API exception thrown when an API request fails.
///
/// All [DioException]s are converted to [ApiException] in [ApiClient].
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
