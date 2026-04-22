import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_brand_widget.dart';
import '../widgets/login_form_widget.dart';

// 安全存储 key 常量（记住账号与密码）
const _kRememberFlag = 'login_remember_me';
const _kRememberEmail = 'login_remembered_email';
const _kRememberPwd = 'login_remembered_pwd';

/// 登录页面——PAGE_SPEC_FLUTTER v1.9 §3.1。渐变背景 + 居中卡片布局。
///
/// [LoginPage] 作为 BlocProvider 宿主（StatelessWidget），
/// [_LoginView] 持有表单状态（StatefulWidget）。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
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
    if (await _storage.read(key: _kRememberFlag) != 'true') return;
    final email = await _storage.read(key: _kRememberEmail);
    final pwd = await _storage.read(key: _kRememberPwd);
    if (!mounted) return;
    setState(() {
      _rememberMe = true;
      _emailController.text = email ?? '';
      _passwordController.text = pwd ?? '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        // 渐变背景：对齐 uni-app 的 linear-gradient(135deg, primary-soft, background, muted-soft)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primaryContainer, colorScheme.surface, colorScheme.surfaceContainerHighest],
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
                      const LoginBrandWidget(),
                      const SizedBox(height: 32),
                      LoginFormWidget(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        rememberMe: _rememberMe,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        onToggleRemember: () => setState(() => _rememberMe = !_rememberMe),
                        onSubmit: _submit,
                        onAuthStateChanged: _onAuthStateChanged,
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

  /// 认证状态变化：登录成功后保存凭据，并按 mustChangePassword 决定跳转目标。
  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state case AuthStateAuthenticated(:final user)) {
      _persistCredentials();
      context.go(user.mustChangePassword ? RoutePaths.changePassword : RoutePaths.dashboard);
    }
  }

  /// 根据 _rememberMe 保存或清除安全存储中的凭据。
  ///
  /// 注意：必须在第一个 await 之前同步捕获 Controller 文本，
  /// 否则导航触发 dispose() 后 Controller 已销毁，读取将得到空值。
  Future<void> _persistCredentials() async {
    if (_rememberMe) {
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
    context.read<AuthCubit>().login(email: _emailController.text.trim(), password: _passwordController.text);
  }
}

