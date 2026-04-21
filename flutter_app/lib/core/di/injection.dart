import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../api/api_client.dart';
import '../api/mock/mock_interceptor.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// 注册所有依赖，按顺序：日志 → 基础设施 → Repository → Cubit/BLoC。
///
/// 在 `main()` 中 `runApp()` 之前调用一次。
void configureDependencies() {
  // ── Logging（最先注册，其他层均可注入）──
  getIt.registerSingleton<AppLogger>(AppLogger.create());

  // ── Infrastructure ──
  const storage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(storage);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  // 网络日志拦截器（非 Release 模式启用；不打印请求/响应 headers 避免 Authorization 泄漏）
  dio.interceptors.add(
    TalkerDioLogger(
      talker: getIt<AppLogger>().talker,
      settings: const TalkerDioLoggerSettings(
        printRequestHeaders: false,
        printResponseHeaders: false,
        printResponseData: false,
      ),
    ),
  );

  // Add mock interceptor if configured
  if (AppConfig.useMock) {
    dio.interceptors.add(MockInterceptor());
  }

  final apiClient = ApiClient(
    dio,
    storage,
    // 当 token 刷新失败时，强制清除内存中的认证状态，触发路由守卫跳转至登录页。
    // 使用惰性 lambda 避免 AuthCubit 尚未注册时的循环依赖问题。
    onSessionExpired: () => getIt<AuthCubit>().forceLogout(),
  );
  getIt.registerSingleton<ApiClient>(apiClient);

  // ── Repositories ──
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<ApiClient>(), getIt<FlutterSecureStorage>()),
  );

  // ── Cubits / BLoCs ──
  // AuthCubit must be a singleton — shared by BlocProvider and router auth guard.
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>()),
  );
}

/// 重置 DI 容器（用于测试 tearDown）。
///
/// Widget 集成测试中，在 `setUp` 注册 mock，`tearDown` 调用此方法清理。
Future<void> resetDependencies() => getIt.reset();

/// 配置测试模式 DI — 仅注册调用方通过 [overrides] 提供的 mock 实例。
///
/// 使用方式：
/// ```dart
/// setUp(() {
///   configureTestDependencies(overrides: (getIt) {
///     getIt.registerSingleton<AuthRepository>(MockAuthRepository());
///     getIt.registerFactory<AuthCubit>(() => MockAuthCubit());
///   });
/// });
/// tearDown(resetDependencies);
/// ```
void configureTestDependencies({
  required void Function(GetIt getIt) overrides,
}) {
  overrides(getIt);
}
