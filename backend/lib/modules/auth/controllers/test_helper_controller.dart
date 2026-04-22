import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../repositories/user_auth_repository.dart';

/// 集成测试辅助 Controller。
///
/// ⚠️ 仅在 ALLOW_TEST_ENDPOINTS=true 时由 app_router 挂载，
///    生产部署**绝对不能**开启此开关。
///
/// 端点：
///   POST /api/test/reset-account-lock  — 按邮箱重置登录失败计数与锁定状态
class TestHelperController {
  final UserAuthRepository _userAuthRepo;

  TestHelperController(this._userAuthRepo);

  Router get router {
    final router = Router();
    router.post('/test/reset-account-lock', _resetAccountLock);
    return router;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// POST /api/test/reset-account-lock
  /// Body: { "email": "..." }
  ///
  /// 重置指定邮箱账号的 failed_login_attempts = 0, locked_until = NULL。
  /// 返回 200 { "data": { "email": "...", "reset": true } }。
  /// 邮箱不存在时返回 404。
  Future<Response> _resetAccountLock(Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final email = body['email'];
    if (email == null || email is! String || email.isEmpty) {
      throw AppException('VALIDATION_ERROR', 'email 字段不能为空', 400);
    }

    final reset = await _userAuthRepo.resetAccountLockByEmail(email);
    if (!reset) {
      throw AppException('USER_NOT_FOUND', '用户不存在: $email', 404);
    }

    return Response.ok(
      jsonEncode({'data': {'email': email, 'reset': true}}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
