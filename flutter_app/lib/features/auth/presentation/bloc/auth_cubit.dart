import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// 账号锁定时间格式（本地时区，精确到分钟）。
final _lockTimeFormat = DateFormat('HH:mm');

/// Auth cubit handling login, logout, and session check.
///
/// Injected via get_it. Depends on [AuthRepository] interface.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthState.initial());

  /// Check if there is a persisted session.
  Future<void> checkAuth() async {
    if (isClosed) return;
    emit(const AuthState.loading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn;
      if (isClosed) return;
      if (!isLoggedIn) {
        emit(const AuthState.initial());
        return;
      }
      final currentUser = await _authRepository.getCurrentUser();
      if (isClosed) return;
      emit(AuthState.authenticated(currentUser));
    } catch (e) {
      if (isClosed) return;
      emit(const AuthState.initial());
    }
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (isClosed) return;
    emit(const AuthState.loading());
    try {
      final (_, loginUser) = await _authRepository.login(
        email: email,
        password: password,
      );
      final currentUser = await _authRepository.getCurrentUser();
      if (isClosed) return;
      // 将登录响应中的 mustChangePassword 标志透传至 CurrentUser
      emit(
        AuthState.authenticated(
          loginUser.mustChangePassword
              ? currentUser.copyWith(mustChangePassword: true)
              : currentUser,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (e is ApiException) {
        // ACCOUNT_LOCKED 时在提示文本中附加解锁时间，方便用户了解何时可重试
        if (e.code == 'ACCOUNT_LOCKED' && e.lockedUntil != null) {
          final unlockTime = _lockTimeFormat.format(e.lockedUntil!.toLocal());
          emit(AuthState.error('账号已锁定，请于 $unlockTime 后重试'));
        } else {
          emit(AuthState.error(e.message));
        }
      } else {
        emit(const AuthState.error('登录失败，请重试'));
      }
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Best effort
    }
    if (isClosed) return;
    emit(const AuthState.initial());
  }

  /// 强制注销（不请求网络），用于 token 刷新失败后由基础设施层触发。
  ///
  /// 与 [logout] 的区别：不调用后端注销接口（令牌已失效）。
  void forceLogout() {
    if (isClosed) return;
    emit(const AuthState.initial());
  }
}
