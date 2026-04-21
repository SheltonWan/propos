import 'dart:convert';
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
          path == 'api/auth/refresh' ||
          path == 'api/auth/forgot-password' ||
          path == 'api/auth/reset-password') {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'] ?? '';
      if (!authHeader.startsWith('Bearer ')) {
        throw const UnauthorizedException('MISSING_TOKEN', '缺少认证 Token');
      }

      final token = authHeader.substring(7);
      try {
        // 在验签前先解析 header，强制只允许 HS256
        // 防止算法混淆攻击（HS384/RS256 等算法替换，或未来 alg:none 绕过）
        _enforceHS256Algorithm(token);

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

/// 从 JWT header 中解析 alg 字段，只允许 HS256。
/// 拒绝 HS384 / HS512 / RS256 / ES256 等算法，防止算法混淆攻击。
void _enforceHS256Algorithm(String token) {
  final parts = token.split('.');
  if (parts.length < 2) {
    throw const UnauthorizedException('INVALID_TOKEN', 'Token 格式错误');
  }
  try {
    // base64url 补全后解码
    final padded = base64.normalize(parts[0].replaceAll('-', '+').replaceAll('_', '/'));
    final header = jsonDecode(utf8.decode(base64.decode(padded))) as Map<String, dynamic>;
    final alg = header['alg'] as String?;
    if (alg != 'HS256') {
      throw UnauthorizedException('INVALID_TOKEN', 'Token 算法不被允许: $alg');
    }
  } on UnauthorizedException {
    rethrow;
  } catch (_) {
    throw const UnauthorizedException('INVALID_TOKEN', 'Token header 解析失败');
  }
}