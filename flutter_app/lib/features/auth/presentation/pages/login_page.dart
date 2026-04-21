import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/business_rules.dart';
import '../../../../core/router/route_paths.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// 登录页面。
///
/// Widget 树结构遵循 PAGE_SPEC_FLUTTER v1.9 §3.1：
/// - [BlocBuilder] 在表单下方内联展示错误文本（非 Snackbar）
/// - [BlocConsumer] 仅包裹登录按钮，listener 处理导航及强制改密跳转
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo 图片，文件未就绪时显示占位图标
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.apartment, size: 80, color: colorScheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  'PropOS',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '物业资产运营管理平台',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                // 表单区域
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 忘记密码入口（不在已知密码流程内）
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                    child: const Text('忘记密码？'),
                  ),
                ),
                // 错误内联展示（PAGE_SPEC §3.1：BlocBuilder 显示错误文本）
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) => switch (state) {
                    AuthStateError(:final message) => Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(message, style: TextStyle(color: colorScheme.error)),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
                const SizedBox(height: 24),
                // 登录按钮：listener 处理导航，含 must_change_password 强制改密跳转
                BlocConsumer<AuthCubit, AuthState>(
                  listener: _onAuthStateChanged,
                  builder: (context, state) {
                    final isLoading = state is AuthStateLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('登录'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 认证状态变化处理：成功时检测 mustChangePassword 决定跳转目标。
  void _onAuthStateChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthStateAuthenticated(:final user):
        if (user.mustChangePassword) {
          context.go(RoutePaths.changePassword);
        } else {
          context.go(RoutePaths.dashboard);
        }
      case _:
        break;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入邮箱';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return '请输入有效邮箱地址';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < BusinessRules.passwordMinLength) {
      return '密码至少 ${BusinessRules.passwordMinLength} 位';
    }
    return null;
  }
}
