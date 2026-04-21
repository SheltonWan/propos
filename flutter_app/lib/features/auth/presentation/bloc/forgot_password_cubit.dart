import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

/// 忘记密码流程的 Cubit，独立于主 [AuthCubit]。
///
/// 仅负责: 发送重置邮件请求。
/// 注入 [AuthRepository] 接口，禁止直接实例化。
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordCubit(this._authRepository)
      : super(const ForgotPasswordState.initial());

  /// 请求发送密码重置邮件。
  ///
  /// 后端防枚举：无论邮箱是否存在均返回 200。
  /// 此方法对应进入 [ForgotPasswordState.sent()] 无论结果如何（仅网络错误除外）。
  Future<void> sendResetEmail({required String email}) async {
    emit(const ForgotPasswordState.loading());
    try {
      await _authRepository.forgotPassword(email: email);
      // 防枚举：成功或邮箱不存在均显示"已发送"
      emit(const ForgotPasswordState.sent());
    } catch (e) {
      emit(ForgotPasswordState.error(
        e is ApiException ? e.message : '请求失败，请稍后再试',
      ));
    }
  }
}
