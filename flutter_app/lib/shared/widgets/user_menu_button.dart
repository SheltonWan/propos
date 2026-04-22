import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// 顶部导航栏右侧用户菜单按钮（苹果风格）。
///
/// 展示当前登录用户头像首字母，点击弹出 [CupertinoActionSheet] 提供「退出登录」入口。
/// 退出前弹出 [CupertinoAlertDialog] 确认，防止误操作。
class UserMenuButton extends StatelessWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = switch (state) {
          AuthStateAuthenticated(:final user) => user.name,
          _ => '',
        };
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onPressed: () => _showMenu(context, name),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name[0],
              style: TextStyle(
                color: CupertinoTheme.of(context).primaryColor,
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
              // showCupertinoModalPopup 默认 useRootNavigator: true，须用根 Navigator 关闭
              Navigator.of(context, rootNavigator: true).pop();
              _showLogoutDialog(context);
            },
            child: const Text('退出登录'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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

/// 顶部导航栏右侧用户菜单按钮。
///
/// 展示当前登录用户头像首字母，点击弹出菜单提供「退出登录」入口。
/// 退出前弹出确认对话框，防止误操作。
