import 'dart:io';
import 'package:shelf/shelf.dart';

/// CORS 中间件
///
/// 行为：
/// - [allowedOrigins] 为空列表时不添加任何 CORS 响应头（最安全默认值）
/// - [allowedOrigins] 包含 `*` 时响应 `Access-Control-Allow-Origin: *`（仅用于公开只读 API）
/// - 其余情况精确匹配请求 Origin，命中则反射该 Origin（支持多域名白名单）
/// - OPTIONS 预检请求直接返回 204，不再向后透传
///
/// 从 CORS_ORIGINS 环境变量解析（逗号分隔）：
///   CORS_ORIGINS=https://admin.propos.example,https://app.propos.example
Middleware corsMiddleware(List<String> allowedOrigins) {
  // 过滤空串，避免误匹配
  final origins = allowedOrigins.where((o) => o.isNotEmpty).toList();
  final allowAll = origins.contains('*');

  return (Handler innerHandler) {
    return (Request request) async {
      final requestOrigin = request.headers['origin'] ?? '';

      // 判断是否允许该来源
      final bool originAllowed;
      if (origins.isEmpty) {
        // 未配置 CORS，所有跨域请求均不添加头
        originAllowed = false;
      } else if (allowAll) {
        originAllowed = true;
      } else {
        originAllowed = origins.contains(requestOrigin);
      }

      // OPTIONS 预检：快速响应，不再向后透传
      if (request.method == 'OPTIONS') {
        if (!originAllowed || requestOrigin.isEmpty) {
          // 不允许的来源：返回 403 拒绝预检
          return Response(HttpStatus.forbidden);
        }
        return Response(
          HttpStatus.noContent,
          headers: _buildCorsHeaders(
            origin: allowAll ? '*' : requestOrigin,
            includeCredentials: !allowAll,
          ),
        );
      }

      final response = await innerHandler(request);

      if (!originAllowed || requestOrigin.isEmpty) {
        return response;
      }

      // 在实际响应中添加 CORS 头
      return response.change(
        headers: _buildCorsHeaders(
          origin: allowAll ? '*' : requestOrigin,
          includeCredentials: !allowAll,
        ),
      );
    };
  };
}

/// 构建 CORS 响应头
Map<String, String> _buildCorsHeaders({
  required String origin,
  required bool includeCredentials,
}) {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers':
        'Authorization, Content-Type, X-Request-ID',
    'Access-Control-Max-Age': '86400',
    // credentials 仅在精确 Origin 匹配时开启，允许 Cookie/Authorization
    if (includeCredentials) 'Access-Control-Allow-Credentials': 'true',
  };
}

/// 从逗号分隔字符串解析 Origin 白名单
List<String> parseCorsOrigins(String raw) {
  if (raw.isEmpty) return [];
  return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}
