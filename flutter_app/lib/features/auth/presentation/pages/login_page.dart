import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/business_rules.dart';
import '../../../../core/router/route_paths.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

// 安全存储 key 常量（记住账号与密码）
const _kRememberFlag = 'login_remember_me';
const _kRememberEmail = 'login_remembered_email';
const _kRememberPwd = 'login_remembered_pwd';

/// 登录页面——对齐 uni-app 设计风格。
///
/// Widget 树结构遵循 PAGE_SPEC_FLUTTER v1.9 §3.1：
/// - 渐变背景 + 居中卡片布局
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
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// 从安全存储恢复上次记住的凭据。
  Future<void> _loadSavedCredentials() async {
    final remembered = await _storage.read(key: _kRememberFlag);
    if (remembered == 'true' && mounted) {
      final email = await _storage.read(key: _kRememberEmail);
      final pwd = await _storage.read(key: _kRememberPwd);
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email ?? '';
          _passwordController.text = pwd ?? '';
        });
      }
    }
  }

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
      body: Container(
        // 渐变背景：对齐 uni-app 的 linear-gradient(135deg, primary-soft, background, muted-soft)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                elevation: 2,
                surfaceTintColor: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 品牌区域：图标盒 + 标题 + 副标题
                      _buildBrand(colorScheme, theme),
                      const SizedBox(height: 32),
                      // 表单区域
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 邮箱输入框
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: '邮箱',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            // 密码输入框（含明暗切换）
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: '密码',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 4),
                            // 记住账号与密码
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Text(
                                    '记住账号与密码',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
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
                      // 错误内联展示（PAGE_SPEC §3.1：BlocBuilder 显示错误文本，非 Snackbar）
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) => switch (state) {
                          AuthStateError(:final message) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
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
                                  : const Text('登 录'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 品牌区域：图标盒（对齐 uni-app .login__icon-box）+ 标题 + 副标题。
  Widget _buildBrand(ColorScheme colorScheme, ThemeData theme) {
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

  /// 认证状态变化处理：登录成功后保存凭据，并按 mustChangePassword 决定跳转目标。
  void _onAuthStateChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthStateAuthenticated(:final user):
        _persistCredentials();
        if (user.mustChangePassword) {
          context.go(RoutePaths.changePassword);
        } else {
          context.go(RoutePaths.dashboard);
        }
      case _:
        break;
    }
  }

  /// 根据 _rememberMe 保存或清除安全存储中的凭据。
  ///
  /// 注意：必须在第一个 await 之前同步捕获 Controller 文本，
  /// 否则导航触发 dispose() 后 Controller 已销毁，读取将得到空值。
  Future<void> _persistCredentials() async {
    if (_rememberMe) {
      // 在任何 await 之前同步读取，防止 dispose 后 Controller 已销毁
      final email = _emailController.text.trim();
      final pwd = _passwordController.text;
      await _storage.write(key: _kRememberFlag, value: 'true');
      await _storage.write(key: _kRememberEmail, value: email);
      await _storage.write(key: _kRememberPwd, value: pwd);
    } else {
      await _storage.delete(key: _kRememberFlag);
      await _storage.delete(key: _kRememberEmail);
      await _storage.delete(key: _kRememberPwd);
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
