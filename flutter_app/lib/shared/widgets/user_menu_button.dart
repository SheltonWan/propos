import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// 顶部导航栏右侧用户菜单按钮。
///
/// 展示当前登录用户头像首字母，点击弹出菜单提供「退出登录」入口。
/// 退出前弹出确认对话框，防止误操作。
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
        return PopupMenuButton<_MenuAction>(
          tooltip: '账户',
          offset: const Offset(0, 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                name.isEmpty ? '?' : name[0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          itemBuilder: (_) => [
            if (name.isNotEmpty) ...[
              PopupMenuItem<_MenuAction>(
                enabled: false,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem<_MenuAction>(
              value: _MenuAction.logout,
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
            if (action == _MenuAction.logout) {
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
              // 退出后 _AuthRouterNotifier 会触发路由守卫重定向至登录页
              context.read<AuthCubit>().logout();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { logout }
