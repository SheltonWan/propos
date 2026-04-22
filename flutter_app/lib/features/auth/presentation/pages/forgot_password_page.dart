import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/cupertino_text_form_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/forgot_password_cubit.dart';
import '../bloc/forgot_password_state.dart';

/// 忘记密码页面（苹果风格）— 两步 OTP 验证码流程。
///
/// 第一步：输入邮箱，点击"发送验证码"；
/// 第二步：输入 6 位 OTP + 新密码，点击"重置密码"；
/// 成功后展示完成状态，返回登录页。
/// 错误通过 BlocBuilder 内联展示，不使用 SnackBar。
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordCubit(getIt<AuthRepository>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  /// 第一步表单
  final _step1Key = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// 第二步表单
  final _step2Key = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  /// 重新发送倒计时（秒），大于 0 时禁用重发按钮，防止频繁发送。
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 启动 60 秒重发倒计时，防止用户频繁请求验证码。
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('忘记密码'),
        leading: CupertinoNavigationBarBackButton(onPressed: () => context.pop()),
      ),
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          // 验证码发送成功后启动倒计时，防止用户频繁重发
          if (state is ForgotPasswordStateCodeSent) {
            _startResendCountdown();
          }
          // 错误通过 BlocBuilder 内联展示，无需 SnackBar
        },
        builder: (context, state) {
          return switch (state) {
            ForgotPasswordStateSuccess() => _buildSuccessView(context),
            ForgotPasswordStateCodeSent(:final email) =>
              _buildStep2View(context, email: email, state: state),
            // 步骤 2 出错时 email 非 null，停留在 OTP 输入界面而非退回步骤 1
            ForgotPasswordStateError(:final email) when email != null =>
              _buildStep2View(context, email: email, state: state),
            _ => _buildStep1View(context, state),
          };
        },
      ),
    );
  }

  // ── 第一步：输入邮箱 ────────────────────────────────────────────────────

  Widget _buildStep1View(BuildContext context, ForgotPasswordState state) {
    final isLoading = state is ForgotPasswordStateLoading;
    final errorMsg = state is ForgotPasswordStateError ? state.message : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('重置密码', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '输入账号邮箱，我们将向您发送 6 位验证码',
              style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 32),
            CupertinoTextFormField(
              controller: _emailController,
              placeholder: '邮箱地址',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefix: const Icon(
                CupertinoIcons.mail,
                size: 18,
                color: CupertinoColors.secondaryLabel,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入邮箱';
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(v.trim())) return '请输入有效的邮箱地址';
                return null;
              },
              onFieldSubmitted: (_) => _submitStep1(context),
            ),
            // 步骤 1 内联错误展示
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 14,
                    color: CupertinoColors.destructiveRed,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMsg,
                      style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: isLoading ? null : () => _submitStep1(context),
                child: isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('发送验证码'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitStep1(BuildContext context) {
    if (!_step1Key.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().sendOtp(
          email: _emailController.text.trim().toLowerCase());
  }

  // ── 第二步：输入 OTP + 新密码 ───────────────────────────────────────────

  Widget _buildStep2View(
    BuildContext context, {
    required String email,
    required ForgotPasswordState state,
  }) {
    final isLoading = state is ForgotPasswordStateLoading;
    final errorMsg = state is ForgotPasswordStateError ? state.message : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '输入验证码',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '验证码已发送至 $email，10 分钟内有效',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 32),
            CupertinoTextFormField(
              controller: _otpController,
              placeholder: '6 位验证码',
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.next,
              prefix: const Icon(
                CupertinoIcons.number,
                size: 18,
                color: CupertinoColors.secondaryLabel,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入验证码';
                if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return '验证码为 6 位数字';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CupertinoTextFormField(
              controller: _newPasswordController,
              placeholder: '新密码',
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              prefix: const Icon(
                CupertinoIcons.lock,
                size: 18,
                color: CupertinoColors.secondaryLabel,
              ),
              suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                child: Icon(
                  _obscureNew ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 18,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入新密码';
                if (v.length < 8) return '密码至少 8 位';
                if (!v.contains(RegExp(r'[A-Z]'))) return '密码须含大写字母';
                if (!v.contains(RegExp(r'[a-z]'))) return '密码须含小写字母';
                if (!v.contains(RegExp(r'[0-9]'))) return '密码须含数字';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CupertinoTextFormField(
              controller: _confirmPasswordController,
              placeholder: '确认新密码',
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              prefix: const Icon(
                CupertinoIcons.lock,
                size: 18,
                color: CupertinoColors.secondaryLabel,
              ),
              suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 18,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请确认新密码';
                if (v != _newPasswordController.text) return '两次密码输入不一致';
                return null;
              },
              onFieldSubmitted: (_) => _submitStep2(context, email),
            ),
            // 步骤 2 内联错误展示
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 14,
                    color: CupertinoColors.destructiveRed,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMsg,
                      style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: isLoading ? null : () => _submitStep2(context, email),
                child: isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('重置密码'),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: (isLoading || _resendCountdown > 0)
                  ? null
                  : () => _submitStep1(context),
              child: Text(
                _resendCountdown > 0
                    ? '重新发送验证码（$_resendCountdown 秒）'
                    : '重新发送验证码',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitStep2(BuildContext context, String email) {
    if (!_step2Key.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().resetPassword(
      email: email,
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );
  }

  // ── 成功状态 ────────────────────────────────────────────────────────────

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.check_mark_circled,
              size: 72,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '密码已重置',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '请使用新密码重新登录',
              style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () => context.go(RoutePaths.login),
                child: const Text('前往登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// 忘记密码页面 — 两步 OTP 验证码流程。
///
/// 第一步：输入邮箱，点击"发送验证码"；
/// 第二步：输入 6 位 OTP + 新密码，点击"重置密码"；
