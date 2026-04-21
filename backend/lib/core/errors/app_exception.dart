/// 应用统一异常基类。
/// Service 层通过此类抛出业务错误，由 error_handler.dart 转为 HTTP 响应。
/// 禁止在 Controller / Service 中直接构建 Response。
class AppException implements Exception {
  /// 错误码（SCREAMING_SNAKE_CASE），来自 ERROR_CODE_REGISTRY.md
  final String code;

  /// 人类可读描述（面向调试 / 日志，不作为 Flutter 业务判断依据）
  final String message;

  /// HTTP 状态码
  final int statusCode;

  const AppException(this.code, this.message, this.statusCode);

  @override
  String toString() => 'AppException[$statusCode]($code): $message';
}

/// 快捷子类 — 404
class NotFoundException extends AppException {
  const NotFoundException(String code, String message)
      : super(code, message, 404);
}

/// 快捷子类 — 403
class ForbiddenException extends AppException {
  const ForbiddenException(
      [String code = 'FORBIDDEN', String message = '无操作权限'])
      : super(code, message, 403);
}

/// 快捷子类 — 401
class UnauthorizedException extends AppException {
  const UnauthorizedException(
      [String code = 'UNAUTHORIZED', String message = '认证失败'])
      : super(code, message, 401);
}

/// 快捷子类 — 400
class ValidationException extends AppException {
  const ValidationException(String code, String message)
      : super(code, message, 400);
}

/// 快捷子类 — 409
class ConflictException extends AppException {
  const ConflictException(String code, String message)
      : super(code, message, 409);
}

/// 快捷子类 — 非法状态转换
class InvalidStateTransitionException extends AppException {
  const InvalidStateTransitionException(String message)
      : super('INVALID_STATE_TRANSITION', message, 422);
}

/// 快捷子类 — 429 限流
/// 携带 [retryAfterSeconds] 以便 errorHandler 附加 Retry-After 响应头
class RateLimitException extends AppException {
  /// 客户端应等待秒数后再重试
  final int retryAfterSeconds;

  const RateLimitException({this.retryAfterSeconds = 60})
      : super('RATE_LIMIT_EXCEEDED', '请求过于频繁，请稍后再试', 429);
}
