import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/middleware/auth_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// JWT 鉴权中间件单元测试
/// 重点验证 V002 修复：只允许 HS256 算法，拒绝算法混淆攻击
void main() {
  // 测试用密钥（≥ 32 字节）
  const testSecret = 'test-secret-key-must-be-32-bytes!!';

  late Handler handler;

  setUp(() {
    final middleware = authMiddleware(testSecret);
    // 内层 handler：仅在验证通过后返回 200
    handler = middleware((_) async => Response.ok('ok'));
  });

  /// 构造一个合法的 HS256 JWT
  String makeHS256Token({
    String sub = 'user-uuid-1',
    String role = 'admin',
    Duration? expiresIn,
  }) {
    return JWT(
      {'sub': sub, 'role': role},
    ).sign(
      SecretKey(testSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: expiresIn ?? const Duration(hours: 1),
    );
  }

  group('algorithm restriction（算法限制 V002）', () {
    test('有效 HS256 token 通过验证', () async {
      final token = makeHS256Token();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': 'Bearer $token'},
      );
      final response = await handler(request);
      expect(response.statusCode, equals(200));
    });

    test('HS384 token 被拒绝（算法混淆攻击）', () async {
      // 使用同一密钥但以 HS384 签发
      final token = JWT(
        {'sub': 'user-uuid-1', 'role': 'admin'},
      ).sign(
        SecretKey(testSecret),
        algorithm: JWTAlgorithm.HS384,
        expiresIn: const Duration(hours: 1),
      );
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': 'Bearer $token'},
      );
      expect(
        () => handler(request),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'INVALID_TOKEN'),
        ),
      );
    });

    test('HS512 token 被拒绝', () async {
      final token = JWT(
        {'sub': 'user-uuid-1', 'role': 'admin'},
      ).sign(
        SecretKey(testSecret),
        algorithm: JWTAlgorithm.HS512,
        expiresIn: const Duration(hours: 1),
      );
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': 'Bearer $token'},
      );
      expect(
        () => handler(request),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'INVALID_TOKEN'),
        ),
      );
    });

    test('格式错误的 token 被拒绝', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': 'Bearer notavalidjwt'},
      );
      expect(
        () => handler(request),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('token 提取与基础验证', () {
    test('缺少 Authorization header 抛出 MISSING_TOKEN', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
      );
      expect(
        () => handler(request),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'MISSING_TOKEN'),
        ),
      );
    });

    test('Bearer 前缀缺失抛出 MISSING_TOKEN', () async {
      final token = makeHS256Token();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': token},
      );
      expect(
        () => handler(request),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'MISSING_TOKEN'),
        ),
      );
    });

    test('已过期 token 抛出 TOKEN_EXPIRED', () async {
      final token = makeHS256Token(expiresIn: const Duration(seconds: -1));
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/assets'),
        headers: {'authorization': 'Bearer $token'},
      );
      expect(
        () => handler(request),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'TOKEN_EXPIRED'),
        ),
      );
    });

    test('/api/auth/login 公开路径无需 token', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/auth/login'),
      );
      // 不抛出异常，直接交给 innerHandler
      final response = await handler(request);
      expect(response.statusCode, equals(200));
    });

    test('/health 公开路径无需 token', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/health'),
      );
      final response = await handler(request);
      expect(response.statusCode, equals(200));
    });
  });
}
