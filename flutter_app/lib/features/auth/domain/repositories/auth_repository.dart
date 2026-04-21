import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// Abstract auth repository interface (domain layer).
///
/// Implementation lives in `data/repositories/auth_repository_impl.dart`.
/// BLoC/Cubit injects this interface — never the implementation directly.
abstract class AuthRepository {
  /// Login with email and password. Returns tokens + user.
  Future<(AuthTokens, User)> login({
    required String email,
    required String password,
  });

  /// Refresh the current access token.
  Future<AuthTokens> refreshToken();

  /// Logout and invalidate the current session.
  Future<void> logout();

  /// Fetch the current authenticated user profile.
  Future<CurrentUser> getCurrentUser();

  /// Check if the user has a stored access token.
  Future<bool> get isLoggedIn;

  /// Retrieve the stored access token (if any).
  Future<String?> getAccessToken();

  /// 发送忘记密码 OTP 验证码邮件。无论邮箱是否存在均静默成功（防枚举）。
  Future<void> forgotPassword({required String email});

  /// 通过 OTP 验证码重置密码（忘记密码第二步）。
  ///
  /// 参数：
  ///   [email]       — 用户邮箱
  ///   [otp]         — 6 位数字验证码
  ///   [newPassword] — 新密码
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
