import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold, Theme;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/business_rules.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/cupertino_text_form_field.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

// 安全存储 key 常量（记住账号与密码）
const _kRememberFlag = 'login_remember_me';
const _kRememberEmail = 'login_remembered_email';
const _kRememberPwd = 'login_remembered_pwd';

/// 登录页面（苹果风格）。
///
/// Widget 树结构遵循 PAGE_SPEC_FLUTTER v1.9 §3.1：
/// - 渐变背景 + 居中 iOS 风格卡片
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        // 渐变背景：对齐 uni-app 的 linear-gradient(135deg, primary-soft, background, muted-soft)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.surface,
              scheme.surfaceContainerHighest,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                // iOS 风格卡片：圆角 + 柔和阴影，无边框
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey4.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 品牌区域：图标盒 + 标题 + 副标题
                    _buildBrand(),
                    const SizedBox(height: 32),
                    // 表单区域
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 邮箱输入框
                          CupertinoTextFormField(
                            controller: _emailController,
                            placeholder: '邮箱',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefix: const Icon(
                              CupertinoIcons.mail,
                              size: 18,
                              color: CupertinoColors.secondaryLabel,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          // 密码输入框（含明暗切换）
                          CupertinoTextFormField(
                            controller: _passwordController,
                            placeholder: '密码',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefix: const Icon(
                              CupertinoIcons.lock,
                              size: 18,
                              color: CupertinoColors.secondaryLabel,
                            ),
                            suffix: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                size: 18,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 8),
                          // 记住账号与密码
                          Row(
                            children: [
                              CupertinoCheckbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: const Text(
                                  '记住账号与密码',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // 忘记密码入口
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => context.push(RoutePaths.forgotPassword),
                              child: const Text('忘记密码？', style: TextStyle(fontSize: 13)),
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
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                size: 14,
                                color: CupertinoColors.destructiveRed,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: CupertinoColors.destructiveRed,
                                    fontSize: 12,
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
                          child: CupertinoButton.filled(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
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
    );
  }

  /// 品牌区域：图标盒（对齐 uni-app .login__icon-box）+ 标题 + 副标题。
  Widget _buildBrand() {
    return Column(
      children: [
        // iOS 风格图标盒：圆角方形 + 阴影
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.building_2_fill, size: 32, color: CupertinoColors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'PropOS',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '物业运营管理平台',
          style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
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

