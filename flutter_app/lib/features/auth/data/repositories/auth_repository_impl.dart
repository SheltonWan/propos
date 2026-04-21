import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_paths.dart';
import '../../../../core/constants/business_rules.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] using [ApiClient] and secure storage.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._apiClient, this._storage);

  @override
  Future<(AuthTokens, User)> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);
    final data = await _apiClient.apiPost<Map<String, dynamic>>(
      ApiPaths.authLogin,
      data: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    final tokensModel = AuthTokensModel.fromJson(data);
    final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    // 将令牌持久化到安全存储
    await _storage.write(key: 'access_token', value: tokensModel.accessToken);
    await _storage.write(key: 'refresh_token', value: tokensModel.refreshToken);
    // 存储 refresh token 到期时刻，用于后续自动续期判断
    final rawExpiresAt = data['refresh_token_expires_at'] as String?;
    if (rawExpiresAt != null) {
      await _storage.write(key: 'refresh_token_expires_at', value: rawExpiresAt);
    }

    return (tokensModel.toEntity(), userModel.toEntity());
  }

  @override
  Future<AuthTokens> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw const ApiException(
        code: 'SESSION_EXPIRED',
        message: '会话已过期，请重新登录',
        statusCode: 401,
      );
    }
    final data = await _apiClient.apiPost<Map<String, dynamic>>(
      ApiPaths.authRefresh,
      data: {'refresh_token': refreshToken},
      fromJson: (json) => json as Map<String, dynamic>,
    );

    final tokensModel = AuthTokensModel.fromJson(data);
    await _storage.write(key: 'access_token', value: tokensModel.accessToken);
    await _storage.write(key: 'refresh_token', value: tokensModel.refreshToken);
    // 同步更新 refresh token 到期时刻
    final rawExpiresAt = data['refresh_token_expires_at'] as String?;
    if (rawExpiresAt != null) {
      await _storage.write(key: 'refresh_token_expires_at', value: rawExpiresAt);
    }

    return tokensModel.toEntity();
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await _apiClient.apiPost<void>(
          ApiPaths.authLogout,
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Best effort — clear local tokens regardless
      }
    }
    await _storage.deleteAll();
  }

  @override
  Future<CurrentUser> getCurrentUser() async {
    return _apiClient.apiGet<CurrentUser>(
      ApiPaths.authMe,
      fromJson: (json) =>
          CurrentUserModel.fromJson(json as Map<String, dynamic>).toEntity(),
    );
  }

  @override
  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;
    // Refresh token 剩余有效期不足时自动静默续期，避免用户被强制登出
    await _maybeProlongSession();
    return true;
  }

  /// 若 refresh token 剩余有效期不足 [BusinessRules.refreshTokenWarnDays] 天，
  /// 则静默调用 [refreshToken] 完成无感知续期。续期失败时不抛出异常。
  Future<void> _maybeProlongSession() async {
    try {
      final expiresAtStr = await _storage.read(key: 'refresh_token_expires_at');
      if (expiresAtStr == null) return;
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null) return;
      final remaining = expiresAt.toUtc().difference(DateTime.now().toUtc());
      if (remaining.inDays < BusinessRules.refreshTokenWarnDays) {
        await refreshToken();
      }
    } catch (_) {
      // Best-effort：续期失败不影响当前登录状态判断
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.apiPost<void>(
      ApiPaths.authForgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.apiPost<void>(
      ApiPaths.authResetPassword,
      data: {'email': email, 'otp': otp, 'new_password': newPassword},
    );
  }
}
