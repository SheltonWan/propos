import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/presentation/bloc/asset_overview_cubit.dart';
import '../../features/assets/presentation/bloc/building_detail_cubit.dart';
import '../../features/assets/presentation/bloc/floor_map_cubit.dart';
import '../../features/assets/presentation/bloc/unit_detail_cubit.dart';
import '../../features/assets/presentation/bloc/unit_list_cubit.dart';
import '../../features/assets/presentation/pages/assets_page.dart';
import '../../features/assets/presentation/pages/building_detail_page.dart';
import '../../features/assets/presentation/pages/floor_plan_page.dart';
import '../../features/assets/presentation/pages/unit_detail_page.dart';
import '../../features/assets/presentation/pages/unit_list_page.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../di/injection.dart';
import '../logging/app_logger.dart';
import 'route_paths.dart';

/// Auth 状态变更通知器，供 GoRouter.refreshListenable 使用。
///
/// 订阅 [AuthCubit] 的状态流，每次状态变化时触发路由守卫重新评估。
/// 持有 [StreamSubscription] 引用，在 [dispose] 时取消，防止内存泄漏。
class _AuthRouterNotifier extends ChangeNotifier {
  late final StreamSubscription<void> _sub;

  _AuthRouterNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
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
      pageBuilder: (_, state) => CupertinoPage(key: state.pageKey, child: const LoginPage()),
        ),
    GoRoute(
      path: RoutePaths.changePassword,
      pageBuilder: (_, state) =>
          CupertinoPage(key: state.pageKey, child: const _ChangePasswordPlaceholderPage()),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      pageBuilder: (_, state) =>
          CupertinoPage(key: state.pageKey, child: const ForgotPasswordPage()),
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
              builder: (_, _) => const DashboardPage(),
                ),
              ],
            ),
            // Tab 2: Assets
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.assets,
                  builder: (_, _) => BlocProvider(
                    create: (_) => getIt<AssetOverviewCubit>(),
                    child: const AssetsPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'buildings/:id',
                      pageBuilder: (ctx, state) => CupertinoPage(
                        key: state.pageKey,
                        child: BlocProvider(
                          create: (_) => getIt<BuildingDetailCubit>(),
                          child: BuildingDetailPage(
                            buildingId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'floors/:fid',
                          pageBuilder: (ctx, state) => CupertinoPage(
                            key: state.pageKey,
                            child: BlocProvider(
                              create: (_) => getIt<FloorMapCubit>(),
                              child: FloorPlanPage(
                                buildingId: state.pathParameters['id']!,
                                floorId: state.pathParameters['fid']!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'units',
                      pageBuilder: (ctx, state) => CupertinoPage(
                        key: state.pageKey,
                        child: BlocProvider(
                          create: (_) => getIt<UnitListCubit>()
                            ..load(),
                          child: UnitListPage(
                            buildingId: state.uri.queryParameters['building_id'],
                          ),
                        ),
                  ),
                    ),
                    GoRoute(
                      path: 'units/:uid',
                      pageBuilder: (ctx, state) => CupertinoPage(
                        key: state.pageKey,
                        child: BlocProvider(
                          create: (_) => getIt<UnitDetailCubit>(),
                          child: UnitDetailPage(
                            unitId: state.pathParameters['uid']!,
                          ),
                        ),
                      ),
                    ),
                  ],
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
  // 记录路由跳转（仅路径，不记录 query 参数防止敏感数据泵漏）
  getIt<AppLogger>().debug('[Router] navigate → ${state.matchedLocation}');

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
    return Center(
      child: Text(
        '$title 模块开发中…',
        style: const TextStyle(
          fontSize: 15,
          color: CupertinoColors.secondaryLabel,
        ),
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
      appBar: CupertinoNavigationBar(
        middle: const Text('修改密码'),
        leading: CupertinoNavigationBarBackButton(onPressed: () => context.pop()),
      ),
      body: const Center(child: Text('修改密码页开发中…')),
    );
  }
}
