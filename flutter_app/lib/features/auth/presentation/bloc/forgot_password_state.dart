import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_state.freezed.dart';

/// 忽记密码流程的状态 — 两步 OTP 验证码流程独立于主 AuthState。
@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState.initial() = ForgotPasswordStateInitial;
  const factory ForgotPasswordState.loading() = ForgotPasswordStateLoading;
  /// OTP 已发送（防枚举：无论邮箱是否存在均进入此状态）
  const factory ForgotPasswordState.codeSent(String email) =
      ForgotPasswordStateCodeSent;

  /// 密码重置成功（展示成功提示）
  const factory ForgotPasswordState.success() = ForgotPasswordStateSuccess;
  /// [email] 非 null 时表示错误发生在第二步（保持停留在 OTP 输入界面）。
  const factory ForgotPasswordState.error(String message, {String? email}) =
      ForgotPasswordStateError;
}
