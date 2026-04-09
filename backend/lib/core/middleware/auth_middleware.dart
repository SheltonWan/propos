import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

/// JWT 鉴权中间件
/// 验证 Authorization: Bearer <token>，解析后将 RequestContext 注入 Request
Middleware authMiddleware(String jwtSecret) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 仅放行登录/刷新两个真正无需 Bearer Token 的公开端点。
      // /api/auth/me、/api/auth/logout、/api/auth/change-password 均需 JWT 验证。
      final path = request.url.path;
      if (path == 'health' ||
          path == 'api/auth/login' ||
          path == 'api/auth/refresh') {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'] ?? '';
      if (!authHeader.startsWith('Bearer ')) {
        throw const UnauthorizedException('MISSING_TOKEN', '缺少认证 Token');
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(jwtSecret));
        final payload = jwt.payload as Map<String, dynamic>;
        final ctx = RequestContext(
          userId: payload['sub'] as String,
          role: UserRole.fromString(payload['role'] as String),
          boundContractId: payload['bound_contract_id'] as String?,
        );
        final updatedRequest =
            request.change(context: {kRequestContextKey: ctx});
        return innerHandler(updatedRequest);
      } on JWTExpiredException {
        throw const UnauthorizedException('TOKEN_EXPIRED', 'Token 已过期');
      } on JWTException catch (e) {
        throw UnauthorizedException('INVALID_TOKEN', 'Token 无效: ${e.message}');
      }
    };
  };
}
