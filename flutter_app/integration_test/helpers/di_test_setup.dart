import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:propos_app/core/api/api_client.dart';
import 'package:propos_app/core/di/injection.dart';
import 'package:propos_app/features/auth/data/repositories/auth_repository_impl.dart';

import 'test_config.dart';

/// 集成测试 DI 工具函数。
///
/// Widget 层测试使用 [setUpRealDependencies] + [tearDownRealDependencies]。
/// Repository 层测试使用 [buildRawComponents] 直接构造，避免触及全局 getIt。

/// 为 Widget 集成测试注册真实依赖（真实 HTTP → 本地后端）。
///
/// 调用方在 [setUp] 里使用，确保每次测试拿到干净的 DI 容器。
Future<void> setUpRealDependencies() async {
  await resetDependencies();
  configureDependencies();
}

/// 清理 DI 容器并删除 SecureStorage（测试隔离）。
Future<void> tearDownRealDependencies() async {
  await resetDependencies();
  await const FlutterSecureStorage().deleteAll();
}

/// Repository 层直连组件集合（不依赖全局 getIt，适合纯网络测试）。
final class RawAuthComponents {
  final AuthRepositoryImpl repository;
  final FlutterSecureStorage storage;
  final Dio dio;

  const RawAuthComponents({
    required this.repository,
    required this.storage,
    required this.dio,
  });

  /// 测试结束后释放 Dio 连接池。
  void dispose() => dio.close(force: true);
}

/// 构造直连本地后端的 [RawAuthComponents]，不注册到 getIt。
///
/// 使用场景：Repository 层集成测试，不需要完整 Widget 树。
/// 调用方需在 [tearDown] 中调用 [RawAuthComponents.dispose]。
RawAuthComponents buildRawComponents() {
  const storage = FlutterSecureStorage();

  final dio = Dio(
    BaseOptions(
      baseUrl: IntegrationTestConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final apiClient = ApiClient(dio, storage);
  final repository = AuthRepositoryImpl(apiClient, storage);

  return RawAuthComponents(
    repository: repository,
    storage: storage,
    dio: dio,
  );
}

/// 调用后端测试辅助端点，重置指定邮箱账号的登录失败计数和锁定状态。
///
/// 要求后端以 ALLOW_TEST_ENDPOINTS=true 启动。
/// 在集成测试的 setUpAll 中调用，防止上一轮测试产生的失败次数积累
/// 导致账号在下一轮测试开始时处于锁定状态。
///
/// 静默失败：若后端不支持此端点（返回 404/403/异常），只打印警告，不中断测试。
Future<void> resetTestAccountLock(String email) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: IntegrationTestConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      // 不抛出 4xx/5xx，由调用方判断
      validateStatus: (_) => true,
    ),
  );
  try {
    final response = await dio.post<Map<String, dynamic>>('/api/test/reset-account-lock', data: {'email': email});
    if (response.statusCode != 200) {
      // ignore: avoid_print
      print(
        '[IT-WARN] reset-account-lock 返回 ${response.statusCode}，'
        '请确认后端已以 ALLOW_TEST_ENDPOINTS=true 启动',
      );
    }
  } catch (e) {
    // ignore: avoid_print
    print('[IT-WARN] reset-account-lock 调用失败：$e');
  } finally {
    dio.close();
  }
}
