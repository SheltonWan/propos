/// LoginService 单元测试
///
/// 覆盖场景：
///   login()          — 成功 / 用户不存在 / 账号停用 / 账号冻结 / 账号锁定 /
///                      密码错误 / 密码错误触发失败计数 / sub_landlord 强制改密标记
///   refresh()        — 有效旋转 / token 已撤销 / token 已过期 / 账号停用
///   logout()         — 成功撤销 / token 不存在（幂等）
///   changePassword() — 成功 / 旧密码错误 / 新密码强度不足 / 新旧密码相同
///   getMe()          — 成功 / 用户不存在
library;

import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/auth/services/login_service.dart';

import 'helpers/fakes.dart';

// ─── 测试内 SHA-256 辅助（与 LoginService 内部算法一致） ────────────────────
String _sha256Hex(String input) =>
    sha256.convert(utf8.encode(input)).toString();

void main() {
  const testEmail = 'test@propos.com';
  const testPassword = 'TestPass123!';

  late String testPasswordHash;
  late FakeUserAuthRepository userRepo;
  late FakeRefreshTokenRepository tokenRepo;
  late FakePool pool;
  late LoginService svc;

  setUpAll(() {
    // logRounds=4 速度约 50ms；BCrypt.checkpw 速度由哈希中记录的轮数决定，
    // 因此后续 checkpw 调用也很快（远快于生产用的 logRounds=12）。
    testPasswordHash =
        BCrypt.hashpw(testPassword, BCrypt.gensalt(logRounds: 4));
  });

  setUp(() {
    userRepo = FakeUserAuthRepository();
    tokenRepo = FakeRefreshTokenRepository();
    pool = FakePool();
    svc = LoginService(pool, makeTestConfig(), userRepo, tokenRepo);
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('login()', () {
    test('有效凭据返回 LoginResponse（含 tokens 和脱敏 user 简报）', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      final result = await svc.login(email: testEmail, password: testPassword);

      expect(result.accessToken, isNotEmpty);
      expect(result.refreshToken, isNotEmpty);
      expect(result.expiresIn, greaterThan(0));
      expect(result.user.email, testEmail);
      // 登录成功后必须重置失败计数
      expect(userRepo.resetLoginFailuresCalled, isTrue);
      // 必须创建一条 refresh token 记录
      expect(tokenRepo.created, hasLength(1));
    });

    test('用户不存在 → INVALID_CREDENTIALS', () async {
      userRepo.user = null; // 模拟用户不存在

      await expectLater(
        svc.login(email: 'nobody@propos.com', password: testPassword),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS'),
        ),
      );
    });

    test('账号已停用（isActive=false）→ ACCOUNT_DISABLED', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        isActive: false,
      );

      await expectLater(
        svc.login(email: testEmail, password: testPassword),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'ACCOUNT_DISABLED')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('二房东账号已冻结（frozenAt 非 null）→ ACCOUNT_FROZEN', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        frozenAt: DateTime.now().toUtc(),
      );

      await expectLater(
        svc.login(email: testEmail, password: testPassword),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'ACCOUNT_FROZEN')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('账号锁定（lockedUntil 在未来）→ AccountLockedException', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        lockedUntil: DateTime.now().toUtc().add(const Duration(minutes: 25)),
      );

      await expectLater(
        svc.login(email: testEmail, password: testPassword),
        throwsA(
          isA<AccountLockedException>()
              .having((e) => e.code, 'code', 'ACCOUNT_LOCKED')
              .having((e) => e.statusCode, 'statusCode', 423),
        ),
      );
    });

    test('密码错误 → INVALID_CREDENTIALS', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      await expectLater(
        svc.login(email: testEmail, password: 'WrongPassword999!'),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS'),
        ),
      );
    });

    test('密码错误 → incrementLoginFailure 被调用', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      try {
        await svc.login(email: testEmail, password: 'WrongPassword999!');
      } catch (_) {}

      expect(userRepo.incrementLoginFailureCalled, isTrue);
    });

    test('sub_landlord 从未改过密码 → user.mustChangePassword=true', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        role: 'sub_landlord',
        // passwordChangedAt=null 触发强制改密标记
        passwordChangedAt: null,
      );

      final result = await svc.login(email: testEmail, password: testPassword);
      expect(result.user.mustChangePassword, isTrue);
    });

    test('普通用户已改过密码 → user.mustChangePassword=false', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        role: 'leasing_specialist',
        passwordChangedAt: DateTime.now().toUtc(),
      );

      final result = await svc.login(email: testEmail, password: testPassword);
      expect(result.user.mustChangePassword, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('refresh()', () {
    const knownRaw = 'known-raw-refresh-token-abc12345678abcdef01234567';
    late String knownHash;

    setUpAll(() {
      knownHash = _sha256Hex(knownRaw);
    });

    setUp(() {
      // 刷新操作需要在 tokenRepo 中查到对应用户
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );
    });

    test('有效 token → 新 TokenPair，旧 token 被撤销', () async {
      tokenRepo.seedToken(
        makeRefreshToken(id: 'rt-seed-1', userId: 'user-1', tokenHash: knownHash),
      );

      final result = await svc.refresh(rawRefreshToken: knownRaw);

      expect(result.accessToken, isNotEmpty);
      expect(result.refreshToken, isNotEmpty);
      // 旧 token 必须被撤销
      expect(tokenRepo.revokedIds, contains('rt-seed-1'));
      // 必须创建一条新 refresh token
      expect(tokenRepo.created, hasLength(1));
    });

    test('已撤销 token → TOKEN_REVOKED', () async {
      tokenRepo.seedToken(
        makeRefreshToken(
          id: 'rt-seed-2',
          userId: 'user-1',
          tokenHash: knownHash,
          revoked: true, // 已主动撤销
        ),
      );

      await expectLater(
        svc.refresh(rawRefreshToken: knownRaw),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'TOKEN_REVOKED'),
        ),
      );
    });

    test('已过期 token → TOKEN_EXPIRED', () async {
      tokenRepo.seedToken(
        makeRefreshToken(
          id: 'rt-seed-3',
          userId: 'user-1',
          tokenHash: knownHash,
          expired: true, // expiresAt 在过去
        ),
      );

      await expectLater(
        svc.refresh(rawRefreshToken: knownRaw),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'TOKEN_EXPIRED'),
        ),
      );
    });

    test('token 有效但对应用户已停用 → ACCOUNT_DISABLED', () async {
      tokenRepo.seedToken(
        makeRefreshToken(id: 'rt-seed-4', userId: 'user-1', tokenHash: knownHash),
      );
      // 将用户切换为停用状态
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        isActive: false,
      );

      await expectLater(
        svc.refresh(rawRefreshToken: knownRaw),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'ACCOUNT_DISABLED'),
        ),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('logout()', () {
    const knownRaw = 'logout-test-raw-token-xyz9876543210fedcba';
    late String knownHash;

    setUpAll(() {
      knownHash = _sha256Hex(knownRaw);
    });

    test('有效 token → token 被撤销', () async {
      tokenRepo.seedToken(
        makeRefreshToken(id: 'rt-logout-1', userId: 'user-1', tokenHash: knownHash),
      );

      await svc.logout(rawRefreshToken: knownRaw);

      expect(tokenRepo.revokedIds, contains('rt-logout-1'));
    });

    test('token 不存在 → 幂等返回成功（不抛出异常）', () async {
      // tokenRepo 为空，不存在任何 token
      await expectLater(
        svc.logout(rawRefreshToken: 'nonexistent-token-abcdef'),
        completes,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('changePassword()', () {
    const newPassword = 'NewPass456!';

    test('旧密码正确、新密码合法 → 返回新 TokenPair', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      final result = await svc.changePassword(
        userId: 'user-1',
        oldPassword: testPassword,
        newPassword: newPassword,
      );

      expect(result.accessToken, isNotEmpty);
      expect(result.refreshToken, isNotEmpty);
      // 密码更新方法必须被调用
      expect(userRepo.updatePasswordCalled, isTrue);
      // 所有旧 token 必须被撤销
      expect(tokenRepo.revokeAllForUserCalled, isTrue);
      // runTx 必须被调用（事务保证原子性）
      expect(pool.runTxCalled, isTrue);
    });

    test('旧密码错误 → INVALID_CREDENTIALS', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      await expectLater(
        svc.changePassword(
          userId: 'user-1',
          oldPassword: 'WrongOldPassword1!',
          newPassword: newPassword,
        ),
        throwsA(
          isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS'),
        ),
      );
    });

    test('新密码无大写字母 → PASSWORD_TOO_WEAK', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      await expectLater(
        svc.changePassword(
          userId: 'user-1',
          oldPassword: testPassword,
          newPassword: 'nouppercase123!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'PASSWORD_TOO_WEAK'),
        ),
      );
    });

    test('新密码少于8位 → PASSWORD_TOO_WEAK', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      await expectLater(
        svc.changePassword(
          userId: 'user-1',
          oldPassword: testPassword,
          newPassword: 'Ab1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'PASSWORD_TOO_WEAK'),
        ),
      );
    });

    test('新旧密码相同 → PASSWORD_SAME_AS_OLD', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
      );

      await expectLater(
        svc.changePassword(
          userId: 'user-1',
          oldPassword: testPassword,
          newPassword: testPassword, // 与旧密码完全相同
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'PASSWORD_SAME_AS_OLD'),
        ),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('getMe()', () {
    test('用户存在 → 返回 CurrentUserResponse（含角色和权限列表）', () async {
      userRepo.user = makeActiveUser(
        email: testEmail,
        passwordHash: testPasswordHash,
        role: 'super_admin',
      );

      final result = await svc.getMe(userId: 'user-1');

      expect(result.id, 'user-1');
      expect(result.email, testEmail);
      expect(result.role, 'super_admin');
      expect(result.permissions, isNotEmpty);
    });

    test('用户不存在 → USER_NOT_FOUND', () async {
      userRepo.user = null;

      await expectLater(
        svc.getMe(userId: 'nonexistent-user'),
        throwsA(
          isA<NotFoundException>()
              .having((e) => e.code, 'code', 'USER_NOT_FOUND'),
        ),
      );
    });
  });
}
