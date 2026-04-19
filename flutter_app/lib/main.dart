import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment config
  await dotenv.load(fileName: '.env.dev');

  // Register all DI dependencies
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
