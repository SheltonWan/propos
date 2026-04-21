import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:propos_backend/config/app_config.dart';
import 'package:propos_backend/modules/auth/controllers/auth_controller.dart';
import 'package:propos_backend/modules/auth/repositories/password_reset_otp_repository.dart';
import 'package:propos_backend/modules/auth/repositories/user_auth_repository.dart';
import 'package:propos_backend/modules/auth/repositories/refresh_token_repository.dart';
import 'package:propos_backend/modules/auth/services/auth_service.dart';
import 'package:propos_backend/modules/auth/services/login_service.dart';
import 'package:propos_backend/shared/email_service.dart';

/// 应用路由注册表
/// 各模块 Controller 就绪后在此挂载
Router buildRouter({required Pool db, required AppConfig config}) {
  final router = Router();

  // 健康检查
  router.get('/health', _health);

  // ── 认证模块 ──────────────────────────────────────────────────────────────
  final otpRepo = PasswordResetOtpRepository(db);
  final userAuthRepo = UserAuthRepository(db);
  final refreshTokenRepo = RefreshTokenRepository(db);
  final emailService = EmailService(
    smtpHost: config.smtpHost,
    smtpPort: config.smtpPort,
    smtpUser: config.smtpUser,
    smtpPassword: config.smtpPassword,
    senderAddress: config.smtpFrom,
  );

  final authService = AuthService(db, otpRepo, emailService);
  final loginService = LoginService(db, config, userAuthRepo, refreshTokenRepo);
  final authController = AuthController(authService, loginService);

  router.mount('/api/', authController.router.call);
  // ──────────────────────────────────────────────────────────────────────────

  // TODO: M1 资产模块
  // router.mount('/api/', assetsRouter);

  // TODO: M2 合同模块
  // router.mount('/api/', contractsRouter);

  // TODO: M3 财务模块
  // router.mount('/api/', financeRouter);

  // TODO: M4 工单模块
  // router.mount('/api/', workordersRouter);

  // TODO: M5 二房东模块
  // router.mount('/api/', subleasesRouter);

  // 404 fallback
  router.all('/<ignored|.*>', (Request req) {
    return Response.notFound('{"error":{"code":"NOT_FOUND","message":"路由不存在"}}',
        headers: {'content-type': 'application/json; charset=utf-8'});
  });

  return router;
}

Response _health(Request request) {
  return Response.ok('{"status":"ok"}',
      headers: {'content-type': 'application/json; charset=utf-8'});
}
