import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_client.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/core/api/api_paths.dart';
import 'package:propos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:propos_app/features/auth/domain/entities/user.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockApiClient mockApiClient;
  late MockFlutterSecureStorage mockStorage;
  late AuthRepositoryImpl repository;

  const loginResponseData = <String, dynamic>{
    'access_token': 'new-access',
    'refresh_token': 'new-refresh',
    'expires_in': 3600,
    'user': {
      'id': 'user-1',
      'name': '张三',
      'email': 'zhangsan@propos.com',
      'role': 'operations_manager',
      'department_id': 'dept-1',
      'must_change_password': false,
    },
  };

  const refreshResponseData = <String, dynamic>{
    'access_token': 'refreshed-access',
    'refresh_token': 'refreshed-refresh',
    'expires_in': 3600,
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockStorage = MockFlutterSecureStorage();
    repository = AuthRepositoryImpl(mockApiClient, mockStorage);

    // Default storage stubs
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
  });

  // AuthRepositoryImpl 单元测试：验证 API 调用、SecureStorage 读写及异常处理
  group('AuthRepositoryImpl', () {
    // ── login ──
    // 登录成功后将 access_token / refresh_token 写入 SecureStorage

    group('login', () {
      // 正确凭证 → 调用 POST /api/auth/login → 持久化双 token → 返回 (tokens, user)
      test('calls apiPost, persists tokens, returns (tokens, user)', () async {
        when(() => mockApiClient.apiPost<Map<String, dynamic>>(
              ApiPaths.authLogin,
              data: any<Map<String, dynamic>>(named: 'data'),
              fromJson: any(named: 'fromJson'),
            )).thenAnswer((_) async => loginResponseData);

        final (tokens, user) = await repository.login(
          email: 'zhangsan@propos.com',
          password: 'password123',
        );

        expect(tokens.accessToken, 'new-access');
        expect(tokens.refreshToken, 'new-refresh');
        expect(tokens.expiresIn, 3600);
        expect(user.id, 'user-1');
        expect(user.name, '张三');
        expect(user.role, UserRole.operationsManager);

        verify(() => mockStorage.write(key: 'access_token', value: 'new-access'))
            .called(1);
        verify(() => mockStorage.write(key: 'refresh_token', value: 'new-refresh'))
            .called(1);
      });
    });

    // ── refreshToken ──
    // Token 刷新：从 storage 读 refresh_token，换取新双 token 并覆盖写入

    group('refreshToken', () {
      // storage 中无 refresh_token → 提前抛出 SESSION_EXPIRED，不发起网络请求
      test('throws ApiException when no refresh token in storage', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        await expectLater(
          () => repository.refreshToken(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              'SESSION_EXPIRED',
            ),
          ),
        );

        verifyNever(() => mockApiClient.apiPost<Map<String, dynamic>>(
              any(),
              data: any<Map<String, dynamic>>(named: 'data'),
              fromJson: any(named: 'fromJson'),
            ));
      });

      // 存有 refresh_token → POST /api/auth/refresh → 新双 token 覆盖写入 storage
      test('reads refresh token from storage, calls apiPost, persists new tokens',
          () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'old-refresh');
        when(() => mockApiClient.apiPost<Map<String, dynamic>>(
              ApiPaths.authRefresh,
              data: any<Map<String, dynamic>>(named: 'data'),
              fromJson: any(named: 'fromJson'),
            )).thenAnswer((_) async => refreshResponseData);

        final tokens = await repository.refreshToken();

        expect(tokens.accessToken, 'refreshed-access');
        expect(tokens.refreshToken, 'refreshed-refresh');

        verify(() => mockStorage.write(
              key: 'access_token',
              value: 'refreshed-access',
            )).called(1);
        verify(() => mockStorage.write(
              key: 'refresh_token',
              value: 'refreshed-refresh',
            )).called(1);
      });
    });

    // ── logout ──
    // 登出：有 refresh_token 则先通知服务端撤销，最终无论成败都 deleteAll

    group('logout', () {
      // 正常流程：发送 POST /api/auth/logout（带 refresh_token）→ deleteAll
      test('sends logout request and clears storage', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'token-to-revoke');
        when(() => mockApiClient.apiPost<void>(
              ApiPaths.authLogout,
              data: any<Map<String, dynamic>>(named: 'data'),
            )).thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockApiClient.apiPost<void>(
              ApiPaths.authLogout,
              data: {'refresh_token': 'token-to-revoke'},
            )).called(1);
        verify(() => mockStorage.deleteAll()).called(1);
      });

      // 服务端撤销接口失败（网络异常）→ 仍执行 deleteAll，保证本地会话被清除
      test('clears storage even when API call fails', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'token-to-revoke');
        when(() => mockApiClient.apiPost<void>(
              ApiPaths.authLogout,
              data: any<Map<String, dynamic>>(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiPaths.authLogout),
        ));

        await repository.logout();

        verify(() => mockStorage.deleteAll()).called(1);
      });

      // storage 中无 refresh_token → 跳过网络请求，直接 deleteAll
      test('skips API call and clears storage when no refresh token', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        await repository.logout();

        verifyNever(() => mockApiClient.apiPost<void>(
              any(),
              data: any<Map<String, dynamic>>(named: 'data'),
            ));
        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    // ── getCurrentUser ──
    // 拉取当前登录用户信息：验证 fromJson 回调能正确映射所有字段

    group('getCurrentUser', () {
      // GET /api/auth/me → 执行 fromJson 映射 → 返回完整 CurrentUser 实体
      test('calls apiGet with correct path and returns CurrentUser', () async {
        const currentUserData = <String, dynamic>{
          'id': 'user-1',
          'name': '张三',
          'email': 'zhangsan@propos.com',
          'role': 'operations_manager',
          'department_id': 'dept-1',
          'department_name': '运营部',
          'permissions': ['contracts:read', 'invoices:read'],
          'bound_contract_id': null,
          'is_active': true,
          'last_login_at': '2026-04-19T10:00:00Z',
        };

        when(() => mockApiClient.apiGet<CurrentUser>(
              ApiPaths.authMe,
              fromJson: any(named: 'fromJson'),
            )).thenAnswer((invocation) async {
          // Execute the fromJson callback to verify mapping works
          final fromJson =
              invocation.namedArguments[#fromJson] as CurrentUser Function(dynamic);
          return fromJson(currentUserData);
        });

        final user = await repository.getCurrentUser();

        expect(user.id, 'user-1');
        expect(user.name, '张三');
        expect(user.role, UserRole.operationsManager);
        expect(user.departmentName, '运营部');
        expect(user.permissions, ['contracts:read', 'invoices:read']);
        expect(user.isActive, true);
        expect(user.lastLoginAt, isNotNull);
      });
    });

    // ── isLoggedIn ──
    // 通过读取 access_token 是否存在来判断本地会话状态，不发起网络请求

    group('isLoggedIn', () {
      // storage 中有 access_token → true
      test('returns true when access_token exists', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'some-token');

        expect(await repository.isLoggedIn, true);
      });

      // storage 中无 access_token（未登录或已登出）→ false
      test('returns false when access_token is null', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        expect(await repository.isLoggedIn, false);
      });
    });

    // ── getAccessToken ──
    // 供 dio 拦截器使用，直接透传 storage 中的值，不做任何处理

    group('getAccessToken', () {
      // storage 有值 → 原样返回
      test('delegates to secure storage', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'stored-token');

        expect(await repository.getAccessToken(), 'stored-token');
      });

      // storage 无值 → 返回 null（调用方需自行处理未登录场景）
      test('returns null when no token stored', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        expect(await repository.getAccessToken(), null);
      });
    });
  });
}
