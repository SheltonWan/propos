import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../services/auth_service.dart';

/// Auth Controller — 忘记密码 / OTP 验证码重置密码路由处理器。
///
/// 路由列表（均为公共接口，无需 RBAC 中间件）：
///   POST /api/auth/forgot-password  — 向邮箱发送 6 位 OTP 验证码
///   POST /api/auth/reset-password   — 通过 email + OTP + new_password 重置密码
///
/// 响应均遵循统一信封格式 {data: {message: ...}}，错误由全局 error_handler 处理。
/// Controller 不含业务逻辑，不直接构建错误 Response（VALIDATION_ERROR 通过抛异常处理）。
class AuthController {
  final AuthService _authService;

  AuthController(this._authService);

  Router get router {
    final router = Router();
    router.post('/api/auth/forgot-password', _forgotPassword);
    router.post('/api/auth/reset-password', _resetPassword);
    return router;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// POST /api/auth/forgot-password
  /// Body: { "email": "..." }
  Future<Response> _forgotPassword(Request request) async {
    final body = await _parseBody(request);
    final email = body['email'];
    if (email == null || email is! String || email.trim().isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'email 不能为空');
    }

    // Service 内部永不抛出业务异常（防枚举）
    await _authService.forgotPassword(email: email.trim().toLowerCase());

    return _jsonResponse(200, {
      'data': {'message': '若该邮箱已注册，验证码已发送至邮箱'},
    });
  }

  /// POST /api/auth/reset-password
  /// Body: { "email": "...", "otp": "...", "new_password": "..." }
  Future<Response> _resetPassword(Request request) async {
    final body = await _parseBody(request);
    final email = body['email'];
    final otp = body['otp'];
    final newPassword = body['new_password'];

    if (email == null || email is! String || email.trim().isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'email 不能为空');
    }
    if (otp == null || otp is! String || otp.trim().isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'otp 不能为空');
    }
    if (newPassword == null || newPassword is! String || newPassword.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'new_password 不能为空');
    }

    // 业务异常（OTP_INVALID / OTP_EXPIRED / RESET_PASSWORD_EXHAUSTED 等）
    // 由全局 error_handler 捕获转为 HTTP 响应，此处不 try/catch
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

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
