import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';

void main() {
  // 层三：必须最先建立 Zone，确保 ensureInitialized 与 runApp 在同一 Zone 内，
  // 避免 BindingBase.debugCheckZone 的 "Zone mismatch" 警告。
  AppLogger? logger;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 注册所有 DI 依赖（AppLogger 最先完成注册）
      configureDependencies();

      logger = getIt<AppLogger>();

      // 层一：捕获 Flutter 框架内的同步异常（Widget build、渲染、布局等）
      FlutterError.onError = (FlutterErrorDetails details) {
        logger!.error('[Flutter] 未捕获框架异常', details.exception, details.stack);
      };

      // 层二：捕获原生层 / Dart isolate 的异步异常
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        logger!.critical('[Platform] 未捕获平台异常', error, stack);
        return true; // 已处理，阻止向上传播
      };

      // 注册 BLoC 全局观察器
      Bloc.observer = AppBlocObserver(logger!);

      runApp(const ProposApp());
    },
    (error, stack) {
      // logger 可能尚未初始化（DI 设置前出错），降级为 debugPrint
      if (logger != null) {
        logger!.critical('[Zone] 未捕获异常', error, stack);
      } else {
        debugPrint('[Zone] 未捕获异常（logger 未就绪）: $error\n$stack');
      }
    },
  );
}

/// 应用根 Widget，使用 StatefulWidget 确保 GoRouter 实例只创建一次。
///
/// 在 StatelessWidget 的 build() 中创建 GoRouter 会导致每次重建时重置导航栈。
class ProposApp extends StatefulWidget {
  const ProposApp({super.key});

  @override
  State<ProposApp> createState() => _ProposAppState();
}

class _ProposAppState extends State<ProposApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>()..checkAuth(),
      child: MaterialApp.router(
        title: 'PropOS',
        theme: buildAppTheme(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
      ),
    );
  }
}
