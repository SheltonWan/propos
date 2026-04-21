import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'app_exception.dart';

/// Shelf 全局错误处理中间件。
/// 捕获所有 AppException 并转为标准 JSON 信封响应，非预期异常返回 500。
Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on AppException catch (e) {
        // RateLimitException 需要附加 Retry-After 头
        final extraHeaders = e is RateLimitException
            ? {'retry-after': e.retryAfterSeconds.toString()}
            : const <String, String>{};
        return Response(
          e.statusCode,
          body: jsonEncode({
            'error': {'code': e.code, 'message': e.message},
          }),
          headers: {
            'content-type': 'application/json; charset=utf-8',
            ...extraHeaders,
          },
        );
      } catch (e, st) {
        // 生产环境不暴露堆栈，仅写 stderr
        stderr.writeln('[ERROR] Unhandled exception: $e\n$st');
        return Response(
          500,
          body: jsonEncode({
            'error': {'code': 'INTERNAL_SERVER_ERROR', 'message': '服务器内部错误'},
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    };
  };
}

// ignore: avoid_dynamic_calls
final stderr = _Stderr();

class _Stderr {
  void writeln(String msg) {
    // ignore: avoid_print
    print('[STDERR] $msg');
  }
}
