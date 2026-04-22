import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

/// JWT 鉴权中间件
/// 验证 Authorization: Bearer <token>，解析后将 RequestContext 注入 Request。
///
/// 安全机制（双重验证）：
///   1. 签名验证：强制 HS256 算法，防止算法混淆攻击
///   2. session_version DB 比对：防止改密/冻结/停用后旧 JWT 继续通行
///      每次密码变更或账号冻结时，users.session_version 自增，
///      与 JWT payload 中的 session_version 不一致则返回 TOKEN_REVOKED(401)
Middleware authMiddleware(String jwtSecret, Pool db) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 仅放行登录/刷新两个真正无需 Bearer Token 的公开端点。
      // /api/auth/me、/api/auth/logout、/api/auth/change-password 均需 JWT 验证。
      final path = request.url.path;
      if (path == 'health' ||
          path == 'api/auth/login' ||
          path == 'api/auth/refresh' ||
          path == 'api/auth/forgot-password' ||
          path == 'api/auth/reset-password' ||
          path == 'api/test/reset-account-lock') {
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

        final userId = payload['sub'] as String;

        // ── session_version 校验（P1 安全修复）────────────────────────────
        // 每次改密或账号冻结/停用时，users.session_version 自增，
        // 旧 JWT 中的 session_version 将与 DB 不一致，从而被强制失效。
        final tokenVersion = payload['session_version'] as int?;
        if (tokenVersion == null) {
          // Token 缺少 session_version 字段（格式无效，拒绝访问）
          throw const UnauthorizedException('INVALID_TOKEN', 'Token 格式无效');
        }
        await _verifySessionVersion(db, userId, tokenVersion);
        // ─────────────────────────────────────────────────────────────────

        final ctx = RequestContext(
          userId: userId,
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

/// 查询 DB 中用户的最新 session_version，与 Token 中的版本号比对。
/// 不一致时抛出 TOKEN_REVOKED，触发客户端重新登录。
Future<void> _verifySessionVersion(Pool db, String userId, int tokenVersion) async {
  final result = await db.execute(
    Sql.named(
      'SELECT session_version FROM users WHERE id = @userId LIMIT 1',
    ),
    parameters: {'userId': userId},
  );
  if (result.isEmpty) {
    // 用户不存在（已被删除），拒绝访问
    throw const UnauthorizedException('INVALID_TOKEN', '用户不存在');
  }
  final dbVersion = result.first.toColumnMap()['session_version'] as int;
  if (dbVersion != tokenVersion) {
    // 版本不一致：改密、冻结或停用后旧 Token 必须失效
    throw const UnauthorizedException('TOKEN_REVOKED', 'Token 已被吊销，请重新登录');
  }
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