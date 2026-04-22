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
    // 仅删除 session token key，不清除 remember-me 条目
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
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
    // 登出：有 refresh_token 则先通知服务端撤销，仅删除 session token（保留 remember-me 条目）

    group('logout', () {
      // 正常流程：发送 POST /api/auth/logout（带 refresh_token）→ 删除三个 session key
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
        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token_expires_at')).called(1);
      });

      // 服务端撤销接口失败（网络异常）→ 仍删除本地 session token，保证会话被清除
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

        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token_expires_at')).called(1);
      });

      // storage 中无 refresh_token → 跳过网络请求，直接删除三个 session key
      test('skips API call and clears storage when no refresh token', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => null);

        await repository.logout();

        verifyNever(() => mockApiClient.apiPost<void>(
              any(),
              data: any<Map<String, dynamic>>(named: 'data'),
            ));
        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token_expires_at')).called(1);
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

    // ── login with refresh_token_expires_at ──
    // 登录响应包含 refresh_token_expires_at 时应一并写入 storage

    group('login with refresh_token_expires_at', () {
      test('persists refresh_token_expires_at when present in response', () async {
        const responseWithExpiry = <String, dynamic>{
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
          'expires_in': 3600,
          'refresh_token_expires_at': '2026-04-30T00:00:00Z',
          'user': {
            'id': 'user-1',
            'name': '张三',
            'email': 'zhangsan@propos.com',
            'role': 'operations_manager',
            'department_id': 'dept-1',
            'must_change_password': false,
          },
        };

        when(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            ApiPaths.authLogin,
            data: any<Map<String, dynamic>>(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((_) async => responseWithExpiry);

        await repository.login(email: 'zhangsan@propos.com', password: 'password123');

        verify(
          () => mockStorage.write(key: 'refresh_token_expires_at', value: '2026-04-30T00:00:00Z'),
        ).called(1);
      });

      // 响应中无 refresh_token_expires_at → 不写 storage，不抛出异常
      test('does not write refresh_token_expires_at when absent', () async {
        when(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            ApiPaths.authLogin,
            data: any<Map<String, dynamic>>(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': 'access',
            'refresh_token': 'refresh',
            'expires_in': 3600,
            'user': {
              'id': 'u1',
              'name': '张三',
              'email': 'z@propos.com',
              'role': 'operations_manager',
              'must_change_password': false,
            },
          },
        );

        await repository.login(email: 'z@propos.com', password: 'p');

        verifyNever(
          () => mockStorage.write(
            key: 'refresh_token_expires_at',
            value: any(named: 'value'),
          ),
        );
      });
    });

    // ── isLoggedIn – 近期满期自动续期 ──
    // refresh_token_expires_at 剩余不足 BusinessRules.refreshTokenWarnDays 天时
    // 应静默调用 refreshToken；若续期失败则吞掉异常，仍返回 true

    group('isLoggedIn – near expiry prolongs session', () {
      // 剩余有效期 < 3 天 → 静默触发 refreshToken
      test('calls refreshToken when refresh_token_expires_at is within warn window', () async {
        when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'valid-token');
        final nearExpiry = DateTime.now().toUtc().add(const Duration(days: 2)).toIso8601String();
        when(
          () => mockStorage.read(key: 'refresh_token_expires_at'),
        ).thenAnswer((_) async => nearExpiry);
        when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'old-refresh');
        when(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            ApiPaths.authRefresh,
            data: any<Map<String, dynamic>>(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          },
        );

        expect(await repository.isLoggedIn, true);

        verify(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            ApiPaths.authRefresh,
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      // 剩余有效期 > 3 天 → 不触发 refreshToken
      test('does not call refreshToken when refresh_token_expires_at is far away', () async {
        when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'valid-token');
        final farExpiry = DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String();
        when(
          () => mockStorage.read(key: 'refresh_token_expires_at'),
        ).thenAnswer((_) async => farExpiry);

        expect(await repository.isLoggedIn, true);

        verifyNever(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        );
      });

      // refreshToken 续期本身失败 → 吞掉异常，isLoggedIn 仍返回 true
      test('returns true even when silent refreshToken throws', () async {
        when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'valid-token');
        final nearExpiry = DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String();
        when(
          () => mockStorage.read(key: 'refresh_token_expires_at'),
        ).thenAnswer((_) async => nearExpiry);
        when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'stale-refresh');
        when(
          () => mockApiClient.apiPost<Map<String, dynamic>>(
            ApiPaths.authRefresh,
            data: any<Map<String, dynamic>>(named: 'data'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenThrow(
          const ApiException(code: 'INVALID_REFRESH_TOKEN', message: '刷新令牌无效', statusCode: 401),
        );

        // 续期失败不影响 isLoggedIn 判断
        expect(await repository.isLoggedIn, true);
      });
    });

    // ── forgotPassword ──
    // 防枚举设计：POST /api/auth/forgot-password，后端无论邮箱是否存在均200

    group('forgotPassword', () {
      // 正常请求 → 调用 POST /api/auth/forgot-password，传入 email
      test('calls apiPost with email payload', () async {
        when(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authForgotPassword,
            data: any<Map<String, dynamic>>(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        await repository.forgotPassword(email: 'user@propos.com');

        verify(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authForgotPassword,
            data: {'email': 'user@propos.com'},
          ),
        ).called(1);
      });

      // 接口抛出异常（限流等）→ 向上透传，由 Cubit 处理
      test('propagates ApiException on failure', () async {
        when(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authForgotPassword,
            data: any<Map<String, dynamic>>(named: 'data'),
          ),
        ).thenThrow(
          const ApiException(code: 'RATE_LIMIT_EXCEEDED', message: '请求过于频繁', statusCode: 429),
        );

        await expectLater(
          () => repository.forgotPassword(email: 'user@propos.com'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'RATE_LIMIT_EXCEEDED')),
        );
      });
    });

    // ── resetPassword ──
    // 提交 OTP 验证码 + 新密码完成密码重置

    group('resetPassword', () {
      // 正确 OTP → POST /api/auth/reset-password，携带 email + otp + new_password
      test('calls apiPost with correct payload', () async {
        when(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authResetPassword,
            data: any<Map<String, dynamic>>(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        await repository.resetPassword(
          email: 'user@propos.com',
          otp: '123456',
          newPassword: 'NewPass@123',
        );

        verify(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authResetPassword,
            data: {'email': 'user@propos.com', 'otp': '123456', 'new_password': 'NewPass@123'},
          ),
        ).called(1);
      });

      // OTP 错误或已过期 → 服务端返回 INVALID_OTP → 向上透传
      test('propagates ApiException when OTP is invalid', () async {
        when(
          () => mockApiClient.apiPost<void>(
            ApiPaths.authResetPassword,
            data: any<Map<String, dynamic>>(named: 'data'),
          ),
        ).thenThrow(const ApiException(code: 'INVALID_OTP', message: '验证码错误或已过期', statusCode: 400));

        await expectLater(
          () => repository.resetPassword(
            email: 'user@propos.com',
            otp: '000000',
            newPassword: 'NewPass@123',
          ),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_OTP')),
        );
      });
    });
  });
}
