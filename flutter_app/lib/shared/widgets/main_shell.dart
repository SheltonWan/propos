import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'user_menu_button.dart';

/// 应用主壳体，提供底部导航栏和顶部 AppBar（含用户菜单）。
///
/// Tab 级页面不应包含自己的 Scaffold，由此 Shell 统一提供。
/// 子页面（通过 push 导航的详情页）应包含自己的 Scaffold 和返回按钮。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  /// 各 Tab 对应的 AppBar 标题，与 branches 顺序一致。
  static const _tabTitles = ['首页', '资产', '合同', '工单', '财务'];

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[navigationShell.currentIndex]),
        actions: const [UserMenuButton()],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: '资产',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: '合同',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: '工单',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: '财务',
          ),
        ],
      ),
    );
  }
}
