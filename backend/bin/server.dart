import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:propos_backend/config/app_config.dart';
import 'package:propos_backend/config/database.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/middleware/log_middleware.dart';
import 'package:propos_backend/core/middleware/rate_limit_middleware.dart';
import 'package:propos_backend/core/middleware/auth_middleware.dart';
import 'package:propos_backend/core/middleware/rbac_middleware.dart';
import 'package:propos_backend/core/middleware/audit_middleware.dart';
import 'package:propos_backend/core/middleware/cors_middleware.dart';
import 'package:propos_backend/router/app_router.dart';

Future<void> main() async {
  // 加载 .env（本地开发）；生产环境仍可直接使用进程环境变量。
  final dotEnv = DotEnv(includePlatformEnvironment: true);
  try {
    dotEnv.load(['.env']);
  } catch (_) {
    // .env 文件可选，生产环境不需要
  }

  // 任一必填变量缺失时此处 throw StateError，服务拒绝启动
  late final AppConfig config;
  try {
    // Platform.environment（进程级）优先于 .env 文件，符合 12-factor 原则
    config = AppConfig.load(get: (key) => Platform.environment[key] ?? dotEnv[key]);
  } on StateError catch (e) {
    stderr.writeln('[FATAL] ${e.message}');
    exit(1);
  }

  await Database.init(config);

  // 解析 CORS 白名单并在通配符时打印警告
  final corsOrigins = parseCorsOrigins(config.corsOrigins);
  if (corsOrigins.contains('*')) {
    stderr.writeln('[WARN] CORS_ORIGINS=* 将允许所有来源跨域访问，请确认这是预期行为');
  }

  final router = buildRouter(db: Database.pool, config: config);

  // Pipeline 顺序：errorHandler → logMiddleware → rateLimitMiddleware
  //               → authMiddleware → rbacMiddleware → auditMiddleware → router
  // errorHandler 必须在最外层，捕获后续所有中间件和路由抛出的异常
  final pipeline = const Pipeline()
      .addMiddleware(errorHandler())
      .addMiddleware(corsMiddleware(corsOrigins)) // CORS 必须在 auth 之前，OPTIONS 预检不携带 JWT
      .addMiddleware(logMiddleware())
      .addMiddleware(rateLimitMiddleware())
      .addMiddleware(authMiddleware(config.jwtSecret))
      .addMiddleware(rbacMiddleware())
      .addMiddleware(auditMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    pipeline,
    InternetAddress.anyIPv4,
    config.appPort,
  );

  stderr.writeln('[PropOS] 服务已启动: http://${server.address.host}:${server.port}');
}


