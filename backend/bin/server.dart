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
    config = AppConfig.load(get: (key) => dotEnv[key]);
  } on StateError catch (e) {
    stderr.writeln('[FATAL] ${e.message}');
    exit(1);
  }

  await Database.init(config);

  final router = buildRouter();

  // Pipeline 顺序：errorHandler → logMiddleware → rateLimitMiddleware
  //               → authMiddleware → rbacMiddleware → auditMiddleware → router
  // errorHandler 必须在最外层，捕获后续所有中间件和路由抛出的异常
  final pipeline = const Pipeline()
      .addMiddleware(errorHandler())
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


