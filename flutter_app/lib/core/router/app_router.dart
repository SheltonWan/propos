import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../di/injection.dart';
import 'route_paths.dart';

/// Application router configured with [GoRouter].
///
/// Uses [StatefulShellRoute] to maintain independent page stacks per tab.
/// Auth guard redirects unauthenticated users to the login page.
GoRouter buildAppRouter() => GoRouter(
      initialLocation: RoutePaths.dashboard,
      redirect: _authGuard,
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (_, _) => const LoginPage(),
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

/// Auth guard: redirect to login if not authenticated.
String? _authGuard(BuildContext context, GoRouterState state) {
  final authState = getIt<AuthCubit>().state;
  final isAuthenticated = authState is AuthStateAuthenticated;
  final isLoginRoute = state.matchedLocation == RoutePaths.login;

  if (!isAuthenticated && !isLoginRoute) return RoutePaths.login;
  if (isAuthenticated && isLoginRoute) return RoutePaths.dashboard;
  return null;
}

/// Temporary placeholder page for unimplemented tabs.
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title 模块开发中…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
