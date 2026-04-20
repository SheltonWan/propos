import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
