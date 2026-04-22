import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/custom_colors.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'user_menu_button.dart';

/// 应用主壳体，提供底部导航栏和顶部 AppBar（含用户菜单）。
///
/// Tab 级页面不应包含自己的 Scaffold，由此 Shell 统一提供。
/// 子页面（通过 push 导航的详情页）应包含自己的 Scaffold 和返回按钮。
/// Dashboard Tab（index 0）使用深色专属 [_DashboardAppBar]；其余 Tab 使用标准 AppBar。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  /// 各 Tab 对应的 AppBar 标题，与 branches 顺序一致。
  static const _tabTitles = ['首页', '资产', '合同', '工单', '财务'];

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    return Scaffold(
      appBar: index == 0
          ? const _DashboardAppBar()
          : AppBar(
              title: Text(_tabTitles[index]),
              actions: const [UserMenuButton()],
            ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            navigationShell.goBranch(i, initialLocation: i == index),
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

/// Dashboard 专属深色 AppBar。
///
/// 背景色对齐 uni-app `--color-card-dark`（#001D3D）。
/// 显示问候语（你好，{姓名}）、当前日期，右侧提供通知铃铛和用户头像菜单。
class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _dateStr() {
    final now = clock.now();
    final week = switch (now.weekday) {
      1 => '一',
      2 => '二',
      3 => '三',
      4 => '四',
      5 => '五',
      6 => '六',
      _ => '日',
    };
    return '${now.month}月${now.day}日 周$week';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = switch (state) {
          AuthStateAuthenticated(:final user) => user.name,
          _ => '用户',
        };
        final colors = Theme.of(context).extension<CustomColors>()!;
        return AppBar(
          backgroundColor: colors.dashboardHeaderBg,
          foregroundColor: colors.onDashboardHeader,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '你好，$name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onDashboardHeader,
                ),
              ),
              Text(
                _dateStr(),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onDashboardHeader.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: const [
            _NotificationButton(),
            _DashboardAvatarButton(),
            SizedBox(width: 4),
          ],
        );
      },
    );
  }
}

/// Dashboard AppBar 通知铃铛按钮。
///
/// 待接入通知 Store 后替换 unreadCount 为真实数据。
class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    // TODO: 接入通知 Store 后替换为真实未读数
    const unreadCount = 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            // TODO: 跳转通知中心
          },
          icon: const Icon(Icons.notifications_outlined),
          color: Theme.of(context).extension<CustomColors>()!.onDashboardHeader,
          tooltip: '通知',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dashboard AppBar 用户头像按钮（圆形，首字母）。
///
/// 点击弹出菜单，提供「退出登录」入口，与 [UserMenuButton] 行为一致。
class _DashboardAvatarButton extends StatelessWidget {
  const _DashboardAvatarButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = switch (state) {
          AuthStateAuthenticated(:final user) => user.name,
          _ => '',
        };
        return PopupMenuButton<_DashMenuAction>(
          tooltip: '账户',
          offset: const Offset(0, 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context)
                  .extension<CustomColors>()!
                  .onDashboardHeader
                  .withValues(alpha: 0.24),
              child: Text(
                name.isEmpty ? '?' : name[0],
                style: TextStyle(
                  color:
                      Theme.of(context).extension<CustomColors>()!.onDashboardHeader,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          itemBuilder: (_) => [
            if (name.isNotEmpty) ...[
              PopupMenuItem<_DashMenuAction>(
                enabled: false,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem<_DashMenuAction>(
              value: _DashMenuAction.logout,
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('退出登录'),
                ],
              ),
            ),
          ],
          onSelected: (action) {
            if (action == _DashMenuAction.logout) {
              _showLogoutDialog(context);
            }
          },
        );
      },
    );
  }

  /// 退出登录确认对话框，防止误操作。
  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出当前账户？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

enum _DashMenuAction { logout }
