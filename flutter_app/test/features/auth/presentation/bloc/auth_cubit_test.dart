import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:propos_app/features/auth/domain/entities/user.dart';
import 'package:propos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:propos_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:propos_app/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  const testTokens = AuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresIn: 3600,
  );

  const testUser = User(
    id: 'user-1',
    name: '测试用户',
    email: 'test@propos.com',
    role: UserRole.operationsManager,
  );

  const testCurrentUser = CurrentUser(
    id: 'user-1',
    name: '测试用户',
    email: 'test@propos.com',
    role: UserRole.operationsManager,
    permissions: ['contracts:read', 'invoices:read'],
    isActive: true,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  // AuthCubit 单元测试：验证登录、登出、会话恢复的状态流转
  group('AuthCubit', () {
    // 初始状态应为 initial，未触发任何操作
    test('initial state is AuthState.initial', () {
      final cubit = AuthCubit(mockAuthRepository);
      expect(cubit.state, const AuthState.initial());
      cubit.close();
    });

    // ── checkAuth ──
    // 检查本地是否存有有效 access_token，若存在则拉取用户信息恢复会话

    // 有 token 且 getCurrentUser 成功 → 直接恢复已登录状态
    blocTest<AuthCubit, AuthState>(
      'checkAuth emits [loading, authenticated] when logged in',
      build: () {
        when(() => mockAuthRepository.isLoggedIn)
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testCurrentUser);
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(testCurrentUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.isLoggedIn).called(1);
        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      },
    );

    // 本地无 token → 回到 initial，不调用 getCurrentUser
    blocTest<AuthCubit, AuthState>(
      'checkAuth emits [loading, initial] when not logged in',
      build: () {
        when(() => mockAuthRepository.isLoggedIn)
            .thenAnswer((_) async => false);
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [
        const AuthState.loading(),
        const AuthState.initial(),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.isLoggedIn).called(1);
        verifyNever(() => mockAuthRepository.getCurrentUser());
      },
    );

    // token 存在但 /me 接口返回 401（已过期）→ 静默回到 initial，不展示错误
    blocTest<AuthCubit, AuthState>(
      'checkAuth emits [loading, initial] when getCurrentUser throws',
      build: () {
        when(() => mockAuthRepository.isLoggedIn)
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.getCurrentUser())
            .thenThrow(const ApiException(
          code: 'TOKEN_EXPIRED',
          message: 'Token 已过期',
          statusCode: 401,
        ));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [
        const AuthState.loading(),
        const AuthState.initial(),
      ],
    );

    // 读取 SecureStorage 本身抛出（设备解密异常）→ 同样静默回到 initial
    blocTest<AuthCubit, AuthState>(
      'checkAuth emits [loading, initial] when isLoggedIn throws',
      build: () {
        when(() => mockAuthRepository.isLoggedIn).thenThrow(Exception('storage error'));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [
        const AuthState.loading(),
        const AuthState.initial(),
      ],
    );

    // ── login ──
    // 邮箱+密码登录：成功存 token，失败透传服务端错误消息

    // 凭证正确 → 持久化 token → 拉取用户信息 → 进入 authenticated
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, authenticated] on success',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => (testTokens, testUser));
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testCurrentUser);
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(testCurrentUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.login(
              email: 'test@propos.com',
              password: 'password123',
            )).called(1);
        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      },
    );

    // 服务端返回 ApiException（如 INVALID_CREDENTIALS）→ 将 message 直接透传给 UI
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, error] with ApiException message on API failure',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const ApiException(
          code: 'INVALID_CREDENTIALS',
          message: '邮箱或密码错误',
          statusCode: 401,
        ));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'wrong',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('邮箱或密码错误'),
      ],
    );

    // 非 ApiException（如网络断连）→ 使用固定兜底文案，避免暴露技术细节
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('network down'));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('登录失败，请重试'),
      ],
    );

    // login 接口成功但随后 /me 接口失败 → 仍进入 error（tokens 已存储但会话未建立）
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, error] when getCurrentUser fails after login',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => (testTokens, testUser));
        when(() => mockAuthRepository.getCurrentUser())
            .thenThrow(const ApiException(
          code: 'INTERNAL_ERROR',
          message: '服务器错误',
          statusCode: 500,
        ));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('服务器错误'),
      ],
    );

    // 账号被锁定（多次失败触发）→ 服务端 message 含锁定截止时间，原样透传
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, error] with ACCOUNT_LOCKED message',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const ApiException(
          code: 'ACCOUNT_LOCKED',
          message: '账号已锁定至 2026-04-21 12:00',
          statusCode: 423,
        ));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('账号已锁定至 2026-04-21 12:00'),
      ],
    );

    // 二房东账号被冻结（审核不通过）→ 服务端 message 原样透传
    blocTest<AuthCubit, AuthState>(
      'login emits [loading, error] with ACCOUNT_FROZEN message',
      build: () {
        when(() => mockAuthRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const ApiException(
          code: 'ACCOUNT_FROZEN',
          message: '账号已冻结，请联系管理员',
          statusCode: 403,
        ));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.login(
        email: 'test@propos.com',
        password: 'password123',
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('账号已冻结，请联系管理员'),
      ],
    );

    // ── logout ──
    // 登出：尽力撤销服务端会话，无论结果都清除本地状态

    // 正常登出 → 调用 repository.logout() → 回到 initial
    blocTest<AuthCubit, AuthState>(
      'logout emits [initial] on success',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      seed: () => const AuthState.authenticated(testCurrentUser),
      act: (cubit) => cubit.logout(),
      expect: () => [const AuthState.initial()],
      verify: (_) {
        verify(() => mockAuthRepository.logout()).called(1);
      },
    );

    // 网络异常导致 logout 接口失败 → best-effort，仍清除本地状态回到 initial
    blocTest<AuthCubit, AuthState>(
      'logout emits [initial] even when repository throws',
      build: () {
        when(() => mockAuthRepository.logout())
            .thenThrow(Exception('network error'));
        return AuthCubit(mockAuthRepository);
      },
      seed: () => const AuthState.authenticated(testCurrentUser),
      act: (cubit) => cubit.logout(),
      expect: () => [const AuthState.initial()],
    );
  });
}
