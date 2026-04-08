import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// 应用路由注册表
/// 各模块 Controller 就绪后在此挂载
Router buildRouter() {
  final router = Router();

  // 健康检查
  router.get('/health', _health);

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

  // TODO: 认证模块
  // router.mount('/api/', authRouter);

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
