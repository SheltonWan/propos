import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/auth_service.dart';

/// Auth Controller — 忘记密码 / 重置密码路由处理器。
///
/// 路由列表（均为公共接口，无需 RBAC 中间件）：
///   POST /api/auth/forgot-password  — 申请密码重置邮件
///   POST /api/auth/reset-password   — 通过 token 重置密码
///
/// 响应均遵循统一信封格式 {data: {message: ...}}，错误由全局 error_handler 处理。
/// Controller 不含业务逻辑，不直接构建错误 Response。
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
      return _jsonResponse(400, {
        'error': {'code': 'VALIDATION_ERROR', 'message': 'email 不能为空'},
      });
    }

    // Service 内部永不抛出业务异常（防枚举）
    await _authService.forgotPassword(email: email.trim().toLowerCase());

    return _jsonResponse(200, {
      'data': {'message': '若该邮箱已注册，重置链接将在几分钟内发送'},
    });
  }

  /// POST /api/auth/reset-password
  /// Body: { "token": "...", "new_password": "..." }
  Future<Response> _resetPassword(Request request) async {
    final body = await _parseBody(request);
    final token = body['token'];
    final newPassword = body['new_password'];

    if (token == null || token is! String || token.trim().isEmpty) {
      return _jsonResponse(400, {
        'error': {'code': 'VALIDATION_ERROR', 'message': 'token 不能为空'},
      });
    }
    if (newPassword == null || newPassword is! String || newPassword.isEmpty) {
      return _jsonResponse(400, {
        'error': {'code': 'VALIDATION_ERROR', 'message': 'new_password 不能为空'},
      });
    }

    // 业务异常（RESET_TOKEN_INVALID / RESET_TOKEN_EXPIRED 等）
    // 由全局 error_handler 捕获转为 HTTP 响应，此处不 try/catch
    await _authService.resetPassword(
      rawToken: token.trim(),
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
