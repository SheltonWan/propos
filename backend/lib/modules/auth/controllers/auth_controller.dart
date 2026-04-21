import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../services/auth_service.dart';
import '../services/login_service.dart';

/// Auth Controller — 认证相关全部路由处理器。
///
/// 公开端点（无需 JWT）：
///   POST /api/auth/login            — 邮箱 + 密码登录
///   POST /api/auth/refresh          — 刷新令牌（旋转）
///   POST /api/auth/forgot-password  — 发送 OTP 验证码
///   POST /api/auth/reset-password   — OTP 验证码重置密码
///
/// 需要 JWT 的端点：
///   POST   /api/auth/logout          — 登出（撤销 refresh token）
///   GET    /api/auth/me              — 当前用户详情
///   POST   /api/auth/change-password — 修改密码
///
/// Controller 不含业务逻辑，不直接构建错误 Response，统一由 error_handler 处理。
class AuthController {
  final AuthService _authService;
  final LoginService _loginService;

  AuthController(this._authService, this._loginService);

  Router get router {
    final router = Router();
    // 公开端点
    router.post('/api/auth/login', _login);
    router.post('/api/auth/refresh', _refresh);
    router.post('/api/auth/forgot-password', _forgotPassword);
    router.post('/api/auth/reset-password', _resetPassword);
    // 需要 JWT 的端点
    router.post('/api/auth/logout', _logout);
    router.get('/api/auth/me', _me);
    router.post('/api/auth/change-password', _changePassword);
    return router;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// POST /api/auth/login
  /// Body: { "email": "...", "password": "..." }
  Future<Response> _login(Request request) async {
    final body = await _parseBody(request);
    final email = _requireString(body, 'email');
    final password = _requireString(body, 'password');
    final deviceInfo = body['device_info'] as String?;

    final result = await _loginService.login(
      email: email.trim().toLowerCase(),
      password: password,
      deviceInfo: deviceInfo,
    );
    return _jsonResponse(200, {'data': result.toJson()});
  }

  /// POST /api/auth/refresh
  /// Body: { "refresh_token": "..." }
  Future<Response> _refresh(Request request) async {
    final body = await _parseBody(request);
    final rawToken = _requireString(body, 'refresh_token');
    final deviceInfo = body['device_info'] as String?;

    final pair = await _loginService.refresh(
      rawRefreshToken: rawToken,
      deviceInfo: deviceInfo,
    );
    return _jsonResponse(200, {'data': pair.toJson()});
  }

  /// POST /api/auth/logout
  /// Body: { "refresh_token": "..." }
  /// 需要有效 JWT（auth_middleware 会验证）
  Future<Response> _logout(Request request) async {
    final body = await _parseBody(request);
    final rawToken = _requireString(body, 'refresh_token');

    await _loginService.logout(rawRefreshToken: rawToken);
    return _jsonResponse(200, {
      'data': {'message': '已成功登出'},
    });
  }

  /// GET /api/auth/me
  /// 需要有效 JWT
  Future<Response> _me(Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final result = await _loginService.getMe(userId: ctx.userId);
    return _jsonResponse(200, {'data': result.toJson()});
  }

  /// POST /api/auth/change-password
  /// Body: { "old_password": "...", "new_password": "..." }
  /// 需要有效 JWT
  Future<Response> _changePassword(Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final body = await _parseBody(request);
    final oldPassword = _requireString(body, 'old_password');
    final newPassword = _requireString(body, 'new_password');
    final deviceInfo = body['device_info'] as String?;

    final pair = await _loginService.changePassword(
      userId: ctx.userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
      deviceInfo: deviceInfo,
    );
    return _jsonResponse(200, {'data': pair.toJson()});
  }

  /// POST /api/auth/forgot-password
  /// Body: { "email": "..." }
  Future<Response> _forgotPassword(Request request) async {
    final body = await _parseBody(request);
    final email = _requireString(body, 'email');

    await _authService.forgotPassword(email: email.trim().toLowerCase());

    return _jsonResponse(200, {
      'data': {'message': '若该邮箱已注册，验证码已发送至邮箱'},
    });
  }

  /// POST /api/auth/reset-password
  /// Body: { "email": "...", "otp": "...", "new_password": "..." }
  Future<Response> _resetPassword(Request request) async {
    final body = await _parseBody(request);
    final email = _requireString(body, 'email');
    final otp = _requireString(body, 'otp');
    final newPassword = _requireString(body, 'new_password');

    await _authService.resetPassword(
      email: email.trim().toLowerCase(),
      otp: otp.trim(),
      newPassword: newPassword,
    );

    return _jsonResponse(200, {
      'data': {'message': '密码已重置，请使用新密码登录'},
    });
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _parseBody(Request request) async {
    final bodyStr = await request.readAsString();
    if (bodyStr.isEmpty) return {};
    try {
      return jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// 从请求体中提取必填字符串字段，空值抛出 VALIDATION_ERROR。
  String _requireString(Map<String, dynamic> body, String field) {
    final value = body[field];
    if (value == null || value is! String || value.trim().isEmpty) {
      throw ValidationException('VALIDATION_ERROR', '$field 不能为空');
    }
    return value;
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
