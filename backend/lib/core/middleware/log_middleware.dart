import 'dart:io' as io;
import 'package:shelf/shelf.dart';

/// HTTP 请求日志中间件
/// 记录请求方法、路径、响应状态码、耗时。
/// 不记录 Authorization / Cookie 等敏感头字段。
Middleware logMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final method = request.method;
      // Shelf 的 request.url 不含前导斜杠，加回来保持可读性
      final path = '/${request.url}';
      final now = DateTime.now().toUtc().toIso8601String();

      try {
        final response = await inner(request);
        stopwatch.stop();
        io.stderr.writeln(
            '[$now] $method $path → ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
        return response;
      } catch (e) {
        // 异常由外层 errorHandler 转换为错误响应；此处仍需记录请求，否则错误请求无任何日志
        stopwatch.stop();
        io.stderr.writeln(
            '[$now] $method $path → ERR (${stopwatch.elapsedMilliseconds}ms) $e');
        rethrow;
      }
    };
  };
}
