import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show BottomNavigationBarItem, kToolbarHeight, Scaffold, Theme;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/custom_colors.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'user_menu_button.dart';

/// 应用主壳体，提供底部 Tab 导航和顶部导航栏（苹果风格）。
///
/// Tab 级页面不应包含自己的 Scaffold，由此 Shell 统一提供。
/// 子页面（通过 push 导航的详情页）应包含自己的 Scaffold 和返回按钮。
/// Dashboard Tab（index 0）使用专属深色 [_DashboardNavBar]；其余 Tab 使用 [CupertinoNavigationBar]。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  /// 各 Tab 对应的标题，与 branches 顺序一致。
  static const _tabTitles = ['首页', '资产', '合同', '工单', '财务'];

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    return Scaffold(
      appBar: index == 0
          ? const _DashboardNavBar() : _StandardNavBar(title: _tabTitles[index]),
      body: navigationShell,
      // 使用 iOS 原生 CupertinoTabBar 替代 Material NavigationBar
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: index,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == index),
        activeColor: CupertinoTheme.of(context).primaryColor,
        inactiveColor: CupertinoColors.inactiveGray,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: '首页',
          ),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.building_2_fill),
            label: '资产',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            activeIcon: Icon(CupertinoIcons.doc_text_fill),
            label: '合同',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.wrench),
            activeIcon: Icon(CupertinoIcons.wrench_fill),
            label: '工单',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            activeIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: '财务',
          ),
        ],
      ),
    );
  }
}

/// 非首页 Tab 使用的 [CupertinoNavigationBar] 包装。
class _StandardNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _StandardNavBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(middle: Text(title), trailing: const UserMenuButton());
  }
}

/// Dashboard 专属深色导航栏（iOS 风格自定义实现）。
///
/// 背景色对齐 [CustomColors.dashboardHeaderBg]（#001D3D）。
/// 包含左侧问候语 + 日期，右侧通知铃铛和用户头像菜单。
class _DashboardNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardNavBar();

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
    // 包含状态栏高度，使背景色延伸至状态栏
    final topPadding = MediaQuery.paddingOf(context).top;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = switch (state) {
          AuthStateAuthenticated(:final user) => user.name,
          _ => '用户',
        };
        final colors = Theme.of(context).extension<CustomColors>()!;
        return Container(
          height: kToolbarHeight + topPadding,
          color: colors.dashboardHeaderBg,
          padding: EdgeInsets.only(top: topPadding),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '你好，$name',
                      style: TextStyle(
                        fontSize: 15,
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
              ),
              _NotificationButton(fgColor: colors.onDashboardHeader),
              _DashboardAvatarButton(colors: colors),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

/// 通知铃铛按钮（iOS 风格 [CupertinoButton]）。
class _NotificationButton extends StatelessWidget {
  final Color fgColor;

  const _NotificationButton({required this.fgColor});

  @override
  Widget build(BuildContext context) {
    // TODO: 接入通知 Store 后替换为真实未读数
    const unreadCount = 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onPressed: () {
            // TODO: 跳转通知中心
          },
          child: Icon(CupertinoIcons.bell, color: fgColor, size: 22),
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

/// Dashboard AppBar 用户头像按钮（圆形首字母）。
///
/// 点击弹出 iOS [CupertinoActionSheet] 操作菜单，提供「退出登录」入口。
class _DashboardAvatarButton extends StatelessWidget {
  final CustomColors colors;

  const _DashboardAvatarButton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = switch (state) {
          AuthStateAuthenticated(:final user) => user.name,
          _ => '',
        };
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          onPressed: () => _showMenu(context, name),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.onDashboardHeader.withValues(alpha: 0.24),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name[0],
              style: TextStyle(
                color: colors.onDashboardHeader,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context, String name) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: name.isNotEmpty ? Text(name) : null,
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showLogoutDialog(context);
            },
            child: const Text('退出登录'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    // 提前捕获 cubit 引用，防止 dialog 内 context 树中无 BLoC
    final authCubit = context.read<AuthCubit>();
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出当前账户？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              // 退出后 _AuthRouterNotifier 触发路由守卫重定向至登录页
              authCubit.logout();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

/// 应用主壳体，提供底部 Tab 导航和顶部导航栏（苹果风格）。
///
/// Tab 级页面不应包含自己的 Scaffold，由此 Shell 统一提供。
/// 子页面（通过 push 导航的详情页）应包含自己的 Scaffold 和返回按钮。
