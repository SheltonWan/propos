import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PropOS 路由树（go_router）
/// 模块页面就绪后逐步替换占位页
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  // TODO: 添加路由守卫（JWT 过期跳登录页）
  // redirect: (context, state) { ... },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const _PlaceholderPage(title: '登录', route: '/login'),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (_, __) =>
          const _PlaceholderPage(title: 'Dashboard 总览', route: '/dashboard'),
    ),

    // M1 资产
    GoRoute(
      path: '/assets',
      name: 'assets',
      builder: (_, __) =>
          const _PlaceholderPage(title: '资产概览', route: '/assets'),
      routes: [
        GoRoute(
          path: 'buildings/:buildingId',
          name: 'building-detail',
          builder: (_, state) => _PlaceholderPage(
              title: '楼栋详情',
              route: '/assets/buildings/${state.pathParameters['buildingId']}'),
        ),
        GoRoute(
          path: 'buildings/:buildingId/floors/:floorId',
          name: 'floor-plan',
          builder: (_, state) => _PlaceholderPage(
              title: '楼层热区图',
              route:
                  '/assets/buildings/${state.pathParameters['buildingId']}/floors/${state.pathParameters['floorId']}'),
        ),
        GoRoute(
          path: 'units/:unitId',
          name: 'unit-detail',
          builder: (_, state) => _PlaceholderPage(
              title: '单元详情',
              route: '/assets/units/${state.pathParameters['unitId']}'),
        ),
      ],
    ),

    // M2 合同
    GoRoute(
      path: '/contracts',
      name: 'contracts',
      builder: (_, __) =>
          const _PlaceholderPage(title: '合同列表', route: '/contracts'),
      routes: [
        GoRoute(
          path: ':contractId',
          name: 'contract-detail',
          builder: (_, state) => _PlaceholderPage(
              title: '合同详情',
              route: '/contracts/${state.pathParameters['contractId']}'),
        ),
        GoRoute(
          path: 'new',
          name: 'contract-create',
          builder: (_, __) =>
              const _PlaceholderPage(title: '新建合同', route: '/contracts/new'),
        ),
      ],
    ),

    // M3 财务
    GoRoute(
      path: '/finance',
      name: 'finance',
      builder: (_, __) =>
          const _PlaceholderPage(title: 'NOI 总览', route: '/finance'),
      routes: [
        GoRoute(
          path: 'invoices',
          name: 'invoices',
          builder: (_, __) =>
              const _PlaceholderPage(title: '账单列表', route: '/finance/invoices'),
        ),
        GoRoute(
          path: 'kpi',
          name: 'kpi',
          builder: (_, __) =>
              const _PlaceholderPage(title: 'KPI 考核', route: '/finance/kpi'),
        ),
      ],
    ),

    // M4 工单
    GoRoute(
      path: '/workorders',
      name: 'workorders',
      builder: (_, __) =>
          const _PlaceholderPage(title: '工单列表', route: '/workorders'),
      routes: [
        GoRoute(
          path: ':workorderId',
          name: 'workorder-detail',
          builder: (_, state) => _PlaceholderPage(
              title: '工单详情',
              route: '/workorders/${state.pathParameters['workorderId']}'),
        ),
        GoRoute(
          path: 'new',
          name: 'workorder-create',
          builder: (_, __) =>
              const _PlaceholderPage(title: '新建工单', route: '/workorders/new'),
        ),
      ],
    ),

    // M5 二房东
    GoRoute(
      path: '/subleases',
      name: 'subleases',
      builder: (_, __) =>
          const _PlaceholderPage(title: '二房东管理', route: '/subleases'),
      routes: [
        GoRoute(
          path: ':subleaseId',
          name: 'sublease-detail',
          builder: (_, state) => _PlaceholderPage(
              title: '子租赁详情',
              route: '/subleases/${state.pathParameters['subleaseId']}'),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('页面不存在: ${state.uri.path}')),
  ),
);

/// 占位页面 — 待实现模块页面前使用
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String route;

  const _PlaceholderPage({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(route,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('待实现'),
          ],
        ),
      ),
    );
  }
}
