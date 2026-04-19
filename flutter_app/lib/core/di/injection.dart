import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../api/mock/mock_interceptor.dart';
import '../config/app_config.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Register all dependencies in correct order.
///
/// Called once in `main()` before `runApp()`.
/// Order: infrastructure → repositories → cubits/blocs.
void configureDependencies() {
  // ── Infrastructure ──
  const storage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(storage);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  // Add mock interceptor if configured
  if (AppConfig.useMock) {
    dio.interceptors.add(MockInterceptor());
  }

  final apiClient = ApiClient(dio, storage);
  getIt.registerSingleton<ApiClient>(apiClient);

  // ── Repositories ──
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<ApiClient>(), getIt<FlutterSecureStorage>()),
  );

  // ── Cubits / BLoCs ──
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>()),
  );
}
