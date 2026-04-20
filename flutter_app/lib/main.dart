import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册所有 DI 依赖
  configureDependencies();

  runApp(const ProposApp());
}

class ProposApp extends StatelessWidget {
  const ProposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>()..checkAuth(),
      child: MaterialApp.router(
        title: 'PropOS',
        theme: buildAppTheme(),
        routerConfig: buildAppRouter(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
      ),
    );
  }
}
