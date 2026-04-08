import 'package:dio/dio.dart';
import 'api_exception.dart';

/// Dio HTTP 客户端封装 + JWT 拦截器
/// 所有 Repository 通过此类发起请求，不直接使用 Dio
class ApiClient {
  final Dio _dio;
  String? _accessToken;

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'content-type': 'application/json'},
        )) {
    _dio.interceptors.add(_AuthInterceptor(this));
    _dio.interceptors.add(_ResponseInterceptor());
  }

  void setToken(String token) => _accessToken = token;
  void clearToken() => _accessToken = null;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? params}) async {
    final resp = await _dio.get<Map<String, dynamic>>(path,
        queryParameters: params);
    return resp.data!;
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final resp = await _dio.post<Map<String, dynamic>>(path, data: data);
    return resp.data!;
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final resp = await _dio.put<Map<String, dynamic>>(path, data: data);
    return resp.data!;
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    final resp = await _dio.patch<Map<String, dynamic>>(path, data: data);
    return resp.data!;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_client._accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_client._accessToken}';
    }
    handler.next(options);
  }
}

class _ResponseInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        throw ApiException.fromResponse(data, response.statusCode ?? 500);
      }
      throw ApiException(
        code: 'HTTP_ERROR',
        message: '请求失败 (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    throw const ApiException(code: 'NETWORK_ERROR', message: '网络连接失败');
  }
}
