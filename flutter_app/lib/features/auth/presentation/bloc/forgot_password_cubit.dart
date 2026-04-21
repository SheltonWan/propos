import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

/// 忘记密码流程的 Cubit，独立于主 [AuthCubit]。
///
/// 负责两步：① 向邮箱发送 OTP 验证码，② 校验 OTP + 重置密码。
/// 注入 [AuthRepository] 接口，禁止直接实例化。
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordCubit(this._authRepository)
      : super(const ForgotPasswordState.initial());

  /// 第一步：请求向邮箱发送 OTP 验证码。
  ///
  /// 后端防枚举：无论邮箱是否存在均显示"已发送"。
  Future<void> sendOtp({required String email}) async {
    emit(const ForgotPasswordState.loading());
    try {
      await _authRepository.forgotPassword(email: email);
      // 防枚举：成功或邮箱不存在均进入 codeSent 状态
      emit(ForgotPasswordState.codeSent(email));
    } catch (e) {
      emit(ForgotPasswordState.error(
        e is ApiException ? e.message : '请求失败，请稍后再试',
      ));
    }
  }

  /// 第二步：提交 OTP 验证码 + 新密码完成密码重置。
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    emit(const ForgotPasswordState.loading());
    try {
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      emit(const ForgotPasswordState.success());
    } catch (e) {
      // 失败时保留 email，使 UI 停留在第二步而非退回步骤 1
      emit(
        ForgotPasswordState.error(
          e is ApiException ? e.message : '操作失败，请稍后再试',
          email: email,
        ),
      );
    }
  }
}
