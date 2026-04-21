import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_state.freezed.dart';

/// 忘记密码流程的状态 — 独立于主 AuthState。
@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState.initial() = ForgotPasswordStateInitial;
  const factory ForgotPasswordState.loading() = ForgotPasswordStateLoading;
  /// 邮件已发送（防枚举：无论邮箱是否存在均进入此状态）
  const factory ForgotPasswordState.sent() = ForgotPasswordStateSent;
  const factory ForgotPasswordState.error(String message) = ForgotPasswordStateError;
}
