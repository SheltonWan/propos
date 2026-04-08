import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'shared/theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();
  runApp(const PropOsApp());
}

void _setupDependencies() {
  // ignore: unused_local_variable
  final sl = GetIt.instance;
  // TODO: 注册各模块 Repository 实现与 BLoC / Cubit
}

class PropOsApp extends StatelessWidget {
  const PropOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PropOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}

