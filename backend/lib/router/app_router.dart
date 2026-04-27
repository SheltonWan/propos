import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:propos_backend/config/app_config.dart';
import 'package:propos_backend/modules/auth/controllers/auth_controller.dart';
import 'package:propos_backend/modules/auth/controllers/test_helper_controller.dart';
import 'package:propos_backend/modules/auth/controllers/user_admin_controller.dart';
import 'package:propos_backend/modules/auth/repositories/password_reset_otp_repository.dart';
import 'package:propos_backend/modules/auth/repositories/user_auth_repository.dart';
import 'package:propos_backend/modules/auth/repositories/refresh_token_repository.dart';
import 'package:propos_backend/modules/auth/services/auth_service.dart';
import 'package:propos_backend/modules/auth/services/login_service.dart';
import 'package:propos_backend/modules/auth/services/user_admin_service.dart';
import 'package:propos_backend/modules/auth/services/user_import_service.dart';
import 'package:propos_backend/shared/email_service.dart';

// 系统设置：组织架构
import 'package:propos_backend/modules/org/controllers/department_controller.dart';
import 'package:propos_backend/modules/org/controllers/managed_scope_controller.dart';
import 'package:propos_backend/modules/org/services/department_import_service.dart';
import 'package:propos_backend/modules/org/services/department_service.dart';
import 'package:propos_backend/modules/org/services/managed_scope_service.dart';

// M1 资产模块
import 'package:propos_backend/modules/assets/services/building_service.dart';
import 'package:propos_backend/modules/assets/services/floor_service.dart';
import 'package:propos_backend/modules/assets/services/unit_service.dart';
import 'package:propos_backend/modules/assets/services/unit_import_service.dart';
import 'package:propos_backend/modules/assets/services/renovation_service.dart';
import 'package:propos_backend/modules/assets/controllers/building_controller.dart';
import 'package:propos_backend/modules/assets/controllers/floor_controller.dart';
import 'package:propos_backend/modules/assets/controllers/floor_plan_controller.dart';
import 'package:propos_backend/modules/assets/controllers/unit_controller.dart';
import 'package:propos_backend/modules/assets/controllers/renovation_controller.dart';

// 通用文件代理
import 'package:propos_backend/modules/files/services/file_service.dart';
import 'package:propos_backend/modules/files/controllers/file_controller.dart';

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

  // ── 用户管理（系统设置）──────────────────────────────────────────────────
  final userAdminService = UserAdminService(db);
  final userImportService = UserImportService(db);
  final userAdminController = UserAdminController(
    userAdminService,
    userImportService,
  );
  router.mount('/api/', userAdminController.router.call);

  // ── 组织架构（系统设置）──────────────────────────────────────────────────
  final departmentService = DepartmentService(db);
  final departmentImportService = DepartmentImportService(db);
  final managedScopeService = ManagedScopeService(db);
  final departmentController = DepartmentController(
    departmentService,
    departmentImportService,
  );
  final managedScopeController = ManagedScopeController(managedScopeService);
  router.mount('/api/', departmentController.router.call);
  router.mount('/api/', managedScopeController.router.call);

  // ── 测试辅助端点（仅限非生产环境）────────────────────────────────────────
  if (config.allowTestEndpoints) {
    final testHelperController = TestHelperController(userAuthRepo);
    router.mount('/api/', testHelperController.router.call);
  }

  // ── M1 资产模块 ──────────────────────────────────────────────────────────
  final buildingService = BuildingService(db);
  final floorService = FloorService(db, config.fileStoragePath);
  final unitService = UnitService(db);
  final unitImportService = UnitImportService(db);
  final renovationService = RenovationService(db, config.fileStoragePath);

  final buildingController = BuildingController(buildingService);
  final floorController = FloorController(floorService);
  final floorPlanController = FloorPlanController(floorService);
  final unitController = UnitController(unitService, unitImportService);
  final renovationController = RenovationController(renovationService);

  router.mount('/api/', buildingController.router.call);
  router.mount('/api/', floorController.router.call);
  router.mount('/api/', floorPlanController.router.call);
  router.mount('/api/', unitController.router.call);
  router.mount('/api/', renovationController.router.call);

  // ── 通用文件代理 ─────────────────────────────────────────────────────────
  final fileService = FileService(
    config.fileStoragePath,
    maxUploadSizeMb: config.maxUploadSizeMb,
  );
  final fileController = FileController(fileService);
  router.mount('/api/', fileController.router.call);
  // ──────────────────────────────────────────────────────────────────────────

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
