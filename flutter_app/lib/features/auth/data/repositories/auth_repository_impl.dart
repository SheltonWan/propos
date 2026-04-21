import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_paths.dart';
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

    // Persist tokens securely
    await _storage.write(key: 'access_token', value: tokensModel.accessToken);
    await _storage.write(key: 'refresh_token', value: tokensModel.refreshToken);

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
    return token != null;
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
}
