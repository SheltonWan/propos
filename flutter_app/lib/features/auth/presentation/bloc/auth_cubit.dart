import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Auth cubit handling login, logout, and session check.
///
/// Injected via get_it. Depends on [AuthRepository] interface.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthState.initial());

  /// Check if there is a persisted session.
  Future<void> checkAuth() async {
    emit(const AuthState.loading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn;
      if (!isLoggedIn) {
        emit(const AuthState.initial());
        return;
      }
      final currentUser = await _authRepository.getCurrentUser();
      emit(AuthState.authenticated(currentUser));
    } catch (e) {
      emit(const AuthState.initial());
    }
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.login(
        email: email,
        password: password,
      );
      final currentUser = await _authRepository.getCurrentUser();
      emit(AuthState.authenticated(currentUser));
    } catch (e) {
      emit(AuthState.error(
        e is ApiException ? e.message : '登录失败，请重试',
      ));
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Best effort
    }
    emit(const AuthState.initial());
  }
}
