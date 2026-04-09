import 'dart:convert';
import 'package:shelf/shelf.dart';

/// IP 粒度、内存滑动窗口限流中间件。
/// 默认：每 IP 60 秒内最多 120 次请求（包含健康检查）。
/// 超限返回 429，不记录敏感信息。
///
/// 注意：多进程/多实例部署时请替换为 Redis 计数器；
/// 当前实现仅适用于单进程开发 / 测试环境。
Middleware rateLimitMiddleware({
  int maxRequests = 120,
  Duration window = const Duration(seconds: 60),
}) {
  // IP → 时间戳列表（滑动窗口）
  final buckets = <String, List<DateTime>>{};

  return (Handler inner) {
    return (Request request) async {
      final ip = _extractIp(request);
      final now = DateTime.now();

      final bucket = buckets.putIfAbsent(ip, () => []);
      // 清除窗口外的旧记录
      bucket.removeWhere((t) => now.difference(t) > window);

      if (bucket.length >= maxRequests) {
        return Response(
          429,
          body: jsonEncode({
            'error': {
              'code': 'RATE_LIMIT_EXCEEDED',
              'message': '请求过于频繁，请稍后再试',
            },
          }),
          headers: {
            'content-type': 'application/json; charset=utf-8',
            // 告知客户端最早何时可以重试（秒数）
            'retry-after': window.inSeconds.toString(),
          },
        );
      }

      bucket.add(now);
      return inner(request);
    };
  };
}

/// 提取客户端真实 IP：优先读取反向代理注入的 X-Forwarded-For 头。
String _extractIp(Request request) {
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.isNotEmpty) {
    // X-Forwarded-For 可能包含逗号分隔的 IP 链；取最左侧（原始客户端）
    return forwarded.split(',').first.trim();
  }
  // Shelf 在 connection_info 上存储远端地址（仅 shelf_io 环境可用）
  final connInfo =
      request.context['shelf.io.connection_info'] as dynamic;
  if (connInfo != null) {
    try {
      return (connInfo.remoteAddress?.address as String?) ?? 'unknown';
    } catch (_) {}
  }
  return 'unknown';
}
