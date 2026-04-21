/// AuthController 单元测试
///
/// 覆盖场景（共 15 个 test）：
///   POST /api/auth/login            — 缺 email / 缺 password / 成功
///   POST /api/auth/refresh          — 缺 refresh_token / 成功
///   POST /api/auth/logout           — 缺 refresh_token / 成功
///   GET  /api/auth/me               — 成功
///   POST /api/auth/change-password  — 缺 old_password / 缺 new_password / 成功
///   POST /api/auth/forgot-password  — 缺 email / 成功
///   POST /api/auth/reset-password   — 缺 otp / 成功
///
/// 策略：注入伪 LoginService / AuthService，不执行真实业务逻辑；
///       通过 errorHandler() 中间件验证错误信封格式。
library;

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/request_context.dart';
import 'package:propos_backend/modules/auth/controllers/auth_controller.dart';
import 'package:propos_backend/modules/auth/models/user_auth.dart';
import 'package:propos_backend/modules/auth/services/auth_service.dart';
import 'package:propos_backend/modules/auth/services/login_service.dart';

import 'helpers/fakes.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 伪 LoginService — 覆盖所有业务方法，返回预置响应或抛出指定异常
// ──────────────────────────────────────────────────────────────────────────────

class FakeLoginService extends LoginService {
  LoginResponse? loginResult;
  TokenPair? refreshResult;
  CurrentUserResponse? getMeResult;
  TokenPair? changePasswordResult;

  /// 设置后，所有方法均抛出该异常（用于验证 errorHandler 信封格式）
  AppException? shouldThrow;

  FakeLoginService()
      : super(
          FakePool(),
          makeTestConfig(),
          FakeUserAuthRepository(),
          FakeRefreshTokenRepository(),
        );

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
    String? deviceInfo,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return loginResult!;
  }

  @override
  Future<TokenPair> refresh({
    required String rawRefreshToken,
    String? deviceInfo,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return refreshResult!;
  }

  @override
  Future<void> logout({required String rawRefreshToken}) async {
    if (shouldThrow != null) throw shouldThrow!;
  }

  @override
  Future<CurrentUserResponse> getMe({required String userId}) async {
    if (shouldThrow != null) throw shouldThrow!;
    return getMeResult!;
  }

  @override
  Future<TokenPair> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? deviceInfo,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
    return changePasswordResult!;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 伪 AuthService — 覆盖忘记密码 / 重置密码
// ──────────────────────────────────────────────────────────────────────────────

class FakeAuthService extends AuthService {
  AppException? shouldThrow;

  FakeAuthService()
      : super(FakePool(), FakeOtpRepository(), FakeEmailService());

  @override
  Future<void> forgotPassword({required String email}) async {
    if (shouldThrow != null) throw shouldThrow!;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (shouldThrow != null) throw shouldThrow!;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 预置响应数据常量（快速构造，无 bcrypt 开销）
// ──────────────────────────────────────────────────────────────────────────────

final _fakeBrief = UserBrief(
  id: 'user-1',
  name: '测试用户',
  email: 'test@propos.com',
  role: 'admin',
  mustChangePassword: false,
);

final _fakeLoginResponse = LoginResponse(
  accessToken: 'fake-access-token',
  refreshToken: 'fake-refresh-token',
  expiresIn: 3600,
  user: _fakeBrief,
);

final _fakeTokenPair = TokenPair(
  accessToken: 'fake-new-access',
  refreshToken: 'fake-new-refresh',
  expiresIn: 3600,
);

final _fakeMeResponse = CurrentUserResponse(
  id: 'user-1',
  name: '测试用户',
  email: 'test@propos.com',
  role: 'super_admin',
  mustChangePassword: false,
  permissions: ['contracts.read', 'invoices.write'],
);

// ──────────────────────────────────────────────────────────────────────────────
// 测试辅助函数
// ──────────────────────────────────────────────────────────────────────────────

/// 构造 Shelf Request，可选注入 RequestContext（用于需要 JWT 的端点）
Request makeRequest(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? userId,
}) {
  var request = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body != null ? jsonEncode(body) : null,
    headers: body != null
        ? {'content-type': 'application/json; charset=utf-8'}
        : const {},
  );
  if (userId != null) {
    request = request.change(context: {
      kRequestContextKey:
          RequestContext(userId: userId, role: UserRole.superAdmin),
    });
  }
  return request;
}

/// 读取响应 body 并解析为 JSON Map
Future<Map<String, dynamic>> readJson(Response response) async =>
    jsonDecode(await response.readAsString()) as Map<String, dynamic>;

// ──────────────────────────────────────────────────────────────────────────────
// 测试主体
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  late FakeLoginService loginSvc;
  late FakeAuthService authSvc;
  late Handler handler;

  setUp(() {
    loginSvc = FakeLoginService();
    authSvc = FakeAuthService();
    final ctrl = AuthController(authSvc, loginSvc);
    // 通过 errorHandler 中间件验证错误信封格式
    handler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(ctrl.router.call);
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/login', () {
    test('缺少 email 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest('POST', '/api/auth/login', body: {'password': 'Pass1!'}),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 password 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest(
            'POST', '/api/auth/login', body: {'email': 'a@propos.com'}),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('凭据合法 → 200 data.access_token 非空', () async {
      loginSvc.loginResult = _fakeLoginResponse;

      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/login',
          body: {'email': 'test@propos.com', 'password': 'Pass1!'},
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['access_token'], isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/refresh', () {
    test('缺少 refresh_token 字段 → 400 VALIDATION_ERROR', () async {
      final resp =
          await handler(makeRequest('POST', '/api/auth/refresh', body: {}));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('token 合法 → 200 data.access_token 非空', () async {
      loginSvc.refreshResult = _fakeTokenPair;

      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/refresh',
          body: {'refresh_token': 'valid-token-xyz'},
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['access_token'], isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/logout', () {
    const authUserId = 'user-1';

    test('缺少 refresh_token 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest('POST', '/api/auth/logout', body: {}, userId: authUserId),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('登出成功 → 200 data.message 包含"已成功登出"', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/logout',
          body: {'refresh_token': 'some-token'},
          userId: authUserId,
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect(
        (json['data'] as Map)['message'].toString(),
        contains('已成功登出'),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('GET /api/auth/me', () {
    test('返回当前用户详情 → 200 data.id 非空', () async {
      loginSvc.getMeResult = _fakeMeResponse;

      final resp = await handler(
        makeRequest('GET', '/api/auth/me', userId: 'user-1'),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['id'], 'user-1');
      expect((json['data'] as Map)['role'], 'super_admin');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/change-password', () {
    const authUserId = 'user-1';

    test('缺少 old_password → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/change-password',
          body: {'new_password': 'NewPass1!'},
          userId: authUserId,
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 new_password → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/change-password',
          body: {'old_password': 'OldPass1!'},
          userId: authUserId,
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('修改成功 → 200 data.access_token 非空', () async {
      loginSvc.changePasswordResult = _fakeTokenPair;

      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/change-password',
          body: {'old_password': 'OldPass1!', 'new_password': 'NewPass2!'},
          userId: authUserId,
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['access_token'], isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/forgot-password', () {
    test('缺少 email 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest('POST', '/api/auth/forgot-password', body: {}),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('发送成功（静默，不论邮箱是否存在）→ 200 data.message 非空', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/forgot-password',
          body: {'email': 'anyone@propos.com'},
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['message'], isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('POST /api/auth/reset-password', () {
    test('缺少 otp 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/reset-password',
          body: {'email': 'test@propos.com', 'new_password': 'NewPass1!'},
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('重置成功 → 200 data.message 包含"密码已重置"', () async {
      final resp = await handler(
        makeRequest(
          'POST',
          '/api/auth/reset-password',
          body: {
            'email': 'test@propos.com',
            'otp': '123456',
            'new_password': 'NewPass1!',
          },
        ),
      );
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect(
        (json['data'] as Map)['message'].toString(),
        contains('密码已重置'),
      );
    });
  });
}
