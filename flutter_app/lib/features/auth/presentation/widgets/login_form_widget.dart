import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/business_rules.dart';
import '../../../../../core/router/route_paths.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// 登录表单区域：邮箱、密码、记住账号、忘记密码、错误提示、登录按钮。
///
/// 遵循 PAGE_SPEC_FLUTTER v1.9 §3.1：BlocBuilder 内联错误（非 Snackbar），
/// BlocConsumer 监听导航并渲染登录按钮。
class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onSubmit,
    required this.onAuthStateChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleRemember;
  final VoidCallback onSubmit;
  final void Function(BuildContext, AuthState) onAuthStateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: onToggleObscure,
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 4),
              // 记住账号与密码
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: (_) => onToggleRemember(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleRemember,
                    child: Text(
                      '记住账号与密码',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              // 忘记密码入口
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.forgotPassword),
                  child: const Text('忘记密码？'),
                ),
              ),
            ],
          ),
        ),
        // 错误内联展示（PAGE_SPEC §3.1：非 Snackbar）
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => switch (state) {
            AuthStateError(:final message) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error)),
                  ),
                ],
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
        // 登录按钮：listener 处理导航，含 must_change_password 强制改密跳转
        BlocConsumer<AuthCubit, AuthState>(
          listener: onAuthStateChanged,
          builder: (context, state) {
            final isLoading = state is AuthStateLoading;
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                      )
                    : const Text('登 录'),
              ),
            );
          },
        ),
      ],
    );
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入邮箱';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return '请输入有效邮箱地址';
    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < BusinessRules.passwordMinLength) return '密码至少 ${BusinessRules.passwordMinLength} 位';
    return null;
  }
}
