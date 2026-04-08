import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

/// JWT 鉴权中间件
/// 验证 Authorization: Bearer <token>，解析后将 RequestContext 注入 Request
Middleware authMiddleware(String jwtSecret) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 放行健康检查
      if (request.url.path == 'health') {
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
