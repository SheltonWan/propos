/// AuthService 单元测试
///
/// 覆盖场景：
///   forgotPassword() — 邮箱不存在（静默）/ sub_landlord 角色（静默）/ 速率限制（静默）/
///                      成功发送 / 邮件发送失败（静默）
///   resetPassword()  — 密码强度不足（快速失败）/ OTP 不存在 / OTP 已使用 /
///                      OTP 已过期 / OTP 已耗尽 / OTP 哈希不匹配（累计失败次数）/
///                      新旧密码相同 / 重置成功
library;

import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/auth/services/auth_service.dart';

import 'helpers/fakes.dart';

// ─── 测试内 SHA-256 辅助（与 AuthService._sha256Hex 实现一致） ──────────────
String _sha256Hex(String input) =>
    sha256.convert(utf8.encode(input)).toString();

void main() {
  const testEmail = 'test@propos.com';
  const testOtp = '123456';
  late String testOtpHash;

  late FakeOtpRepository otpRepo;
  late FakeEmailService emailSvc;
  late FakePool pool;
  late AuthService svc;

  setUpAll(() {
    testOtpHash = _sha256Hex(testOtp);
  });

  setUp(() {
    otpRepo = FakeOtpRepository();
    emailSvc = FakeEmailService();
    pool = FakePool();
    svc = AuthService(pool, otpRepo, emailSvc);
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('forgotPassword()', () {
    test('邮箱在数据库中不存在 → 静默返回，不抛出任何异常，不创建 OTP', () async {
      // FakePool.execute 默认返回空 Result（邮箱不存在场景）
      await svc.forgotPassword(email: testEmail);

      expect(otpRepo.createCalled, isFalse);
    });

    test('邮箱属于 sub_landlord 角色 → 静默返回，不创建 OTP', () async {
      pool.executeHandler = (q, p) =>
          makeResult(['id', 'role'], [['user-1', 'sub_landlord']]);

      await svc.forgotPassword(email: testEmail);

      expect(otpRepo.createCalled, isFalse);
    });

    test('速率限制（5 分钟内已发 3 次）→ 静默返回，不创建 OTP', () async {
      pool.executeHandler = (q, p) =>
          makeResult(['id', 'role'], [['user-1', 'admin']]);
      otpRepo.recentCount = 3; // >= AuthService._rateLimit

      await svc.forgotPassword(email: testEmail);

      expect(otpRepo.createCalled, isFalse);
    });

    test('邮箱存在且未超速率限制 → 创建 OTP 记录并发送邮件', () async {
      pool.executeHandler = (q, p) =>
          makeResult(['id', 'role'], [['user-1', 'admin']]);
      otpRepo.recentCount = 0;

      await svc.forgotPassword(email: testEmail);

      expect(otpRepo.createCalled, isTrue);
      expect(otpRepo.createdEmail, testEmail);
      expect(emailSvc.lastRecipient, testEmail);
      // OTP 是 6 位数字字符串
      expect(emailSvc.lastOtp, matches(r'^\d{6}$'));
    });

    test('邮件发送抛出异常 → 吞下异常，不对外传播', () async {
      pool.executeHandler = (q, p) =>
          makeResult(['id', 'role'], [['user-1', 'admin']]);
      otpRepo.recentCount = 0;
      emailSvc.shouldThrow = true;

      // 不抛出任何异常（邮件故障不影响主流程响应）
      await expectLater(
        svc.forgotPassword(email: testEmail),
        completes,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('resetPassword()', () {
    // 为慢速 bcrypt（12 轮）测试预先用 4 轮生成对照哈希（fast，约 50ms）
    late String oldPassHash; // OldPass1! 的哈希 — 用于"成功"路径的 currentHash
    late String samePassHash; // NewPass1! 的哈希 — 用于"新旧相同"路径的 currentHash

    setUpAll(() {
      oldPassHash =
          BCrypt.hashpw('OldPass1!', BCrypt.gensalt(logRounds: 4));
      samePassHash =
          BCrypt.hashpw('NewPass1!', BCrypt.gensalt(logRounds: 4));
    });

    test('新密码强度不足（全小写）→ PASSWORD_TOO_WEAK（快速失败，无 DB 访问）',
        () async {
      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'nouppercase123',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'PASSWORD_TOO_WEAK'),
        ),
      );
    });

    test('OTP 记录不存在 → OTP_INVALID', () async {
      otpRepo.latestOtp = null;

      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'NewPass1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'OTP_INVALID'),
        ),
      );
    });

    test('OTP 已使用（usedAt 非 null）→ OTP_INVALID', () async {
      otpRepo.latestOtp = makeOtp(codeHash: testOtpHash, used: true);

      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'NewPass1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'OTP_INVALID'),
        ),
      );
    });

    test('OTP 已过期（expiresAt 在过去）→ OTP_EXPIRED', () async {
      otpRepo.latestOtp = makeOtp(codeHash: testOtpHash, expired: true);

      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'NewPass1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'OTP_EXPIRED'),
        ),
      );
    });

    test('OTP 失败次数已耗尽（failedAttempts >= 5）→ RESET_PASSWORD_EXHAUSTED',
        () async {
      otpRepo.latestOtp = makeOtp(
        codeHash: testOtpHash,
        failedAttempts: 5, // 达到 maxFailedAttempts
      );

      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'NewPass1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'RESET_PASSWORD_EXHAUSTED'),
        ),
      );
    });

    test('OTP 哈希不匹配 → OTP_INVALID，incrementFailed 被调用', () async {
      // OTP 记录对应正确 OTP='123456'，但用户输入错误 OTP '999999'
      otpRepo.latestOtp = makeOtp(codeHash: testOtpHash); // 正确哈希

      await expectLater(
        svc.resetPassword(
          email: testEmail,
          otp: '999999', // 故意提交错误 OTP
          newPassword: 'NewPass1!',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.code, 'code', 'OTP_INVALID'),
        ),
      );
      // 必须累加失败次数
      expect(otpRepo.incrementFailedCalled, isTrue);
    });

    // 以下两个测试内部调用 AuthService._bcryptHash(newPassword, rounds=12)，
    // 在普通开发机上约需 3-10 秒，延长超时避免 CI 误报。
    test(
      '新旧密码相同 → PASSWORD_SAME_AS_OLD',
      () async {
        otpRepo.latestOtp = makeOtp(codeHash: testOtpHash);
        // DB 返回当前密码哈希（与 newPassword 相同，用 logRounds=4 加速检查）
        pool.executeHandler = (q, p) =>
            makeResult(['password_hash'], [[samePassHash]]);

        await expectLater(
          svc.resetPassword(
            email: testEmail,
            otp: testOtp,
            newPassword: 'NewPass1!', // 与 samePassHash 对应的明文密码相同
          ),
          throwsA(
            isA<ValidationException>()
                .having((e) => e.code, 'code', 'PASSWORD_SAME_AS_OLD'),
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      '所有校验通过 → markUsed 被调用，runTx 执行（密码更新事务）',
      () async {
        otpRepo.latestOtp = makeOtp(codeHash: testOtpHash);
        // DB 返回的 currentHash 对应 'OldPass1!'（与 newPassword='NewPass1!' 不同）
        pool.executeHandler = (q, p) =>
            makeResult(['password_hash'], [[oldPassHash]]);

        await svc.resetPassword(
          email: testEmail,
          otp: testOtp,
          newPassword: 'NewPass1!',
        );

        // OTP 必须被标记为已使用
        expect(otpRepo.markUsedCalled, isTrue);
        // 密码更新事务必须执行
        expect(pool.runTxCalled, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
