import 'dart:io' as io;
import 'package:shelf/shelf.dart';

/// HTTP 请求日志中间件
/// 记录请求方法、路径、响应状态码、耗时。
/// 不记录 Authorization / Cookie 等敏感头字段。
Middleware logMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();

      Response response;
      try {
        response = await inner(request);
      } finally {
        stopwatch.stop();
      }

      final method = request.method;
      // Shelf 的 request.url 不含前导斜杠，加回来保持可读性
      final path = '/${request.url}';
      final status = response.statusCode;
      final ms = stopwatch.elapsedMilliseconds;
      final now = DateTime.now().toUtc().toIso8601String();

      io.stderr.writeln('[$now] $method $path → $status (${ms}ms)');

      return response;
    };
  };
}
