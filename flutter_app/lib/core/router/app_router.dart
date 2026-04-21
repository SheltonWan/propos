import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../di/injection.dart';
import 'route_paths.dart';

/// Auth 状态变更通知器，供 GoRouter.refreshListenable 使用。
///
/// 订阅 [AuthCubit] 的状态流，每次状态变化时触发路由守卫重新评估。
/// 由于 AuthCubit 是应用级单例，此订阅与应用生命周期相同，无需显式取消。
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Stream<AuthState> stream) {
    stream.listen((_) => notifyListeners());
  }
}

/// Application router configured with [GoRouter].
///
/// Uses [StatefulShellRoute] to maintain independent page stacks per tab.
/// Auth guard redirects unauthenticated users to the login page.
/// [refreshListenable] 确保 auth 状态变化（登录/登出）时路由守卫自动重新触发。
GoRouter buildAppRouter() => GoRouter(
      initialLocation: RoutePaths.dashboard,
      redirect: _authGuard,
  refreshListenable: _AuthRouterNotifier(getIt<AuthCubit>().stream),
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (_, _) => const LoginPage(),
        ),
    GoRoute(
      path: RoutePaths.changePassword,
      builder: (_, _) => const _ChangePasswordPlaceholderPage(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      builder: (_, _) => const ForgotPasswordPage(),
    ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            // Tab 1: Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.dashboard,
                  builder: (_, _) =>
                      const _PlaceholderPage(title: '首页'),
                ),
              ],
            ),
            // Tab 2: Assets
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.assets,
                  builder: (_, _) =>
                      const _PlaceholderPage(title: '资产'),
                ),
              ],
            ),
            // Tab 3: Contracts
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.contracts,
                  builder: (_, _) =>
                      const _PlaceholderPage(title: '合同'),
                ),
              ],
            ),
            // Tab 4: Work Orders
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.workorders,
                  builder: (_, _) =>
                      const _PlaceholderPage(title: '工单'),
                ),
              ],
            ),
            // Tab 5: Finance
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.finance,
                  builder: (_, _) =>
                      const _PlaceholderPage(title: '财务'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Auth guard：未登录强制到登录页；已登录访问登录页跳首页；
/// mustChangePassword 为 true 时强制跳转改密页，阻止访问其他页面。
String? _authGuard(BuildContext context, GoRouterState state) {
  final authState = getIt<AuthCubit>().state;
  final loc = state.matchedLocation;
  final isLoginRoute = loc == RoutePaths.login;
  final isForgotPasswordRoute = loc == RoutePaths.forgotPassword;
  final isChangePasswordRoute = loc == RoutePaths.changePassword;

  if (authState is! AuthStateAuthenticated) {
    if (!isLoginRoute && !isForgotPasswordRoute) return RoutePaths.login;
    return null;
  }

  // 以下已通过类型提升确认为 AuthStateAuthenticated
  final user = authState.user;
  if (user.mustChangePassword) {
    // 强制改密期间只允许停留在改密页
    if (!isChangePasswordRoute) return RoutePaths.changePassword;
  } else {
    if (isLoginRoute) return RoutePaths.dashboard;
  }

  return null;
}

/// 未实现 Tab 的临时占位页面（不含 Scaffold，由 MainShell 提供）。
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title 模块开发中…', style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// 修改密码页占位（PAGE_SPEC §3.2，ChangePasswordPage 实现前临时使用）。
class _ChangePasswordPlaceholderPage extends StatelessWidget {
  const _ChangePasswordPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: const Center(child: Text('修改密码页开发中…')),
    );
  }
}
