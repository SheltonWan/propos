import 'package:flutter/material.dart';

/// 登录页品牌区域：图标盒（对齐 uni-app .login__icon-box）+ 标题 + 副标题。
///
/// 遵循 PAGE_SPEC_FLUTTER v1.9 §3.1：primary 色方形图标盒 + headlineMedium 标题。
class LoginBrandWidget extends StatelessWidget {
  const LoginBrandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        // Primary 色背景方形图标盒，内嵌楼宇图标
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.apartment, size: 32, color: colorScheme.onPrimary),
        ),
        const SizedBox(height: 16),
        Text(
          'PropOS',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '物业运营管理平台',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
