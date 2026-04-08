import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:propos_backend/config/app_config.dart';
import 'package:propos_backend/config/database.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/middleware/auth_middleware.dart';
import 'package:propos_backend/core/middleware/audit_middleware.dart';
import 'package:propos_backend/router/app_router.dart';

Future<void> main() async {
  // 加载 .env（本地开发；生产通过实际环境变量注入）
  // DotEnv(includePlatformEnvironment: true) 已自动合并 Platform.environment
  try {
    DotEnv(includePlatformEnvironment: true).load(['.env']);
  } catch (_) {
    // .env 文件可选，生产环境不需要
  }

  final config = AppConfig.load();
  await Database.init(config);

  final router = buildRouter();

  final pipeline = const Pipeline()
      .addMiddleware(errorHandler())
      .addMiddleware(authMiddleware(config.jwtSecret))
      .addMiddleware(auditMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    pipeline,
    InternetAddress.anyIPv4,
    config.appPort,
  );

  print('[PropOS] 服务已启动: http://${server.address.host}:${server.port}');
}

