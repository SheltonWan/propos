import 'package:dio/dio.dart';

import '../api_paths.dart';

/// Mock interceptor for development.
///
/// Enabled when `FLUTTER_USE_MOCK=true` in `.env`.
/// Intercepts matching requests and returns mock data in the standard envelope.
/// Unmatched URLs fall through to real network requests.
class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final mockResponse = _matchMock(options);
    if (mockResponse != null) {
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: mockResponse,
        ),
      );
      return;
    }
    handler.next(options);
  }

  Map<String, dynamic>? _matchMock(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // ── Auth: POST /api/auth/login ──
    if (method == 'POST' && path == ApiPaths.authLogin) {
      return _mockLoginResponse();
    }

    // ── Auth: GET /api/auth/me ──
    if (method == 'GET' && path == ApiPaths.authMe) {
      return _mockCurrentUser();
    }

    // ── Auth: POST /api/auth/refresh ──
    if (method == 'POST' && path == ApiPaths.authRefresh) {
      return _mockRefreshResponse();
    }

    // ── Auth: POST /api/auth/logout ──
    if (method == 'POST' && path == ApiPaths.authLogout) {
      return {
        'data': {'message': '已注销'},
      };
    }

    return null; // Unmatched — fall through to real request
  }

  // ── Mock data generators ──

  Map<String, dynamic> _mockLoginResponse() => {
        'data': {
          'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'expires_in': 86400,
          'user': _mockUserBrief(),
        },
      };

  Map<String, dynamic> _mockRefreshResponse() => {
        'data': {
          'access_token': 'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token': 'mock_new_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'expires_in': 86400,
        },
      };

  Map<String, dynamic> _mockCurrentUser() => {
        'data': {
          'id': '00000000-0000-4000-8000-000000000001',
          'name': '测试管理员',
          'email': 'admin@propos.dev',
          'role': 'super_admin',
          'department_id': null,
          'department_name': null,
          'permissions': [
            'assets.read',
            'assets.write',
            'contracts.read',
            'contracts.write',
            'finance.read',
            'finance.write',
            'workorders.read',
            'workorders.write',
            'sublease.read',
            'sublease.write',
            'kpi.view',
            'kpi.manage',
            'kpi.appeal',
            'alerts.read',
            'alerts.write',
            'org.read',
            'org.manage',
            'ops.read',
            'ops.write',
            'import.execute',
            'notifications.read',
            'approvals.manage',
            'dashboard.read',
            'deposit.read',
            'deposit.write',
            'meterReading.write',
            'turnoverReview.approve',
          ],
          'bound_contract_id': null,
          'is_active': true,
          'last_login_at': '2026-04-20T08:00:00Z',
        },
      };

  Map<String, dynamic> _mockUserBrief() => {
        'id': '00000000-0000-4000-8000-000000000001',
        'name': '测试管理员',
        'email': 'admin@propos.dev',
        'role': 'super_admin',
        'department_id': null,
        'must_change_password': false,
      };
}
