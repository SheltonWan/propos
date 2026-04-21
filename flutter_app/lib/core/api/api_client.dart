import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';
import 'api_list_response.dart';
import 'api_paths.dart';

/// Central HTTP client wrapping [Dio].
///
/// Provides typed helpers that automatically unpack the server envelope
/// `{ "data": ..., "meta": ... }` and convert errors to [ApiException].
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Token refresh lock to prevent concurrent refresh attempts.
  Completer<void>? _refreshCompleter;

  ApiClient(this._dio, this._storage) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  // ── Public API helpers ──

  /// GET single object. Unwraps `body['data']` and passes to [fromJson].
  Future<T> apiGet<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParams,
    );
    final data = response.data!['data'];
    if (fromJson != null) return fromJson(data);
    return data as T;
  }

  /// GET paginated list. Returns [ApiListResponse] with items + meta.
  Future<ApiListResponse<T>> apiGetList<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    required T Function(dynamic) fromJson,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParams,
    );
    final body = response.data!;
    final rawList = body['data'] as List<dynamic>;
    final items = rawList.map(fromJson).toList();
    final meta = body['meta'] != null
        ? PaginationMeta.fromJson(body['meta'] as Map<String, dynamic>)
        : const PaginationMeta(page: 1, pageSize: 20, total: 0);
    return ApiListResponse<T>(items: items, meta: meta);
  }

  /// POST (create resource). Unwraps `body['data']`.
  Future<T> apiPost<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
    );
    final payload = response.data!['data'];
    if (fromJson != null) return fromJson(payload);
    return payload as T;
  }

  /// PATCH (partial update). Unwraps `body['data']`.
  Future<T> apiPatch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      path,
      data: data,
    );
    final payload = response.data!['data'];
    if (fromJson != null) return fromJson(payload);
    return payload as T;
  }

  /// DELETE resource.
  Future<void> apiDelete(String path) async {
    await _dio.delete<void>(path);
  }

  // ── Interceptors ──

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Attempt token refresh on 401
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiPaths.authRefresh &&
        err.requestOptions.path != ApiPaths.authLogin) {
      try {
        await _refreshToken();
        // Retry the original request with the new token
        final token = await _storage.read(key: 'access_token');
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (_) {
        // Refresh failed — clear tokens and let error propagate
        await _storage.deleteAll();
      }
    }

    handler.reject(_toDioExceptionWithApiException(err));
  }

  Future<void> _refreshToken() async {
    // If already refreshing, wait for existing refresh to complete.
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw const ApiException(
          code: 'TOKEN_EXPIRED',
          message: '登录已过期，请重新登录',
          statusCode: 401,
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      await _storage.write(
        key: 'access_token',
        value: data['access_token'] as String,
      );
      await _storage.write(
        key: 'refresh_token',
        value: data['refresh_token'] as String,
      );
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Convert [DioException] to carry an [ApiException] in its `error` field.
  DioException _toDioExceptionWithApiException(DioException err) {
    final response = err.response;
    String code = 'INTERNAL_ERROR';
    String message = '网络请求失败，请稍后重试';
    int statusCode = response?.statusCode ?? 0;

    DateTime? lockedUntil;
    if (response?.data is Map<String, dynamic>) {
      final body = response!.data as Map<String, dynamic>;
      if (body.containsKey('error') && body['error'] is Map<String, dynamic>) {
        final errorBody = body['error'] as Map<String, dynamic>;
        code = (errorBody['code'] as String?) ?? code;
        message = (errorBody['message'] as String?) ?? message;
        // 解析账号锁定截止时间（仅 ACCOUNT_LOCKED 时后端附加此字段）
        final rawLockedUntil = errorBody['locked_until'] as String?;
        if (rawLockedUntil != null) {
          lockedUntil = DateTime.tryParse(rawLockedUntil);
        }
      }
    }

    return err.copyWith(
      error: ApiException(
        code: code,
        message: message,
        statusCode: statusCode,
        lockedUntil: lockedUntil,
      ),
    );
  }
}
