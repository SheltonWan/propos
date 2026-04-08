import 'dart:io' as io;
import 'package:shelf/shelf.dart';
import '../request_context.dart';

/// 审计日志中间件 — 记录所有非 GET 请求的操作人 / 路由 / 方法 / 时间
/// 详细业务级审计（合同变更、账单核销等）在 Service 层手动写入 audit_logs 表
Middleware auditMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      // 只记录写操作
      if (request.method != 'GET' && request.method != 'HEAD') {
        final ctx = request.context[kRequestContextKey] as RequestContext?;
        final userId = ctx?.userId ?? 'anonymous';
        final now = DateTime.now().toUtc().toIso8601String();
        io.stderr.writeln(
          '[AUDIT] $now | $userId | ${request.method} /${request.url.path} | ${response.statusCode}',
        );
      }
      return response;
    };
  };
}
