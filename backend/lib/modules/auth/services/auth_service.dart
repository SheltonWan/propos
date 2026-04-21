import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../repositories/password_reset_otp_repository.dart';
import '../../../shared/email_service.dart';

/// Auth Service — 忘记密码 / OTP 验证码重置密码业务逻辑。
///
/// 安全规则（严格遵守）：
///   1. forgotPassword — 不论邮箱是否存在均不抛出异常（防枚举）
///   2. 同一账号 5 分钟内最多发送 3 次 OTP，超出则静默忽略
///   3. OTP 为 6 位数字，SHA-256 哈希后入库，明文仅在邮件中出现一次
///   4. resetPassword — OTP 验证失败累计 5 次则耗尽，不可继续使用
///   5. OTP 使用后立即标记，不可二次提交
///   6. 重置成功后 session_version += 1（使所有旧 JWT 失效）
///   7. 二房东角色不允许自助重置（由管理员重置）
class AuthService {
  final Connection _db;
  final PasswordResetOtpRepository _otpRepo;
  final EmailService _emailService;

  /// 速率限制：5 分钟内最多申请次数
  static const int _rateLimit = 3;
  static const Duration _rateWindow = Duration(minutes: 5);

  /// OTP 有效期（分钟）
  static const int _otpExpiryMinutes = 10;

  AuthService(this._db, this._otpRepo, this._emailService);

  /// 发送 OTP 验证码邮件（忘记密码第一步）。
  /// 此方法永远不抛出业务异常 — 对外只有"已发送"或"静默忽略"。
  Future<void> forgotPassword({required String email}) async {
    // 查询该邮箱是否存在（不对外暴露结果）
    final userResult = await _db.execute(
      Sql.named('''
        SELECT id, role
        FROM users
        WHERE email = @email AND is_active = true
        LIMIT 1
      '''),
      parameters: {'email': email},
    );

    // 邮箱不存在 — 静默返回
    if (userResult.isEmpty) return;

    final row = userResult.first.toColumnMap();
    final userId = row['id'] as String;
    final role = row['role'] as String;

    // 二房东角色不支持自助重置 — 静默忽略（不暴露原因）
    if (role == 'sub_landlord') return;

    // 清理历史过期/已使用记录
    await _otpRepo.deleteStaleByUserId(userId);

    // 速率限制检查
    final recentCount = await _otpRepo.countRecentByUserId(userId, _rateWindow);
    if (recentCount >= _rateLimit) return;

    // 生成 6 位数字 OTP
    final otp = _generateOtp();
    final codeHash = _sha256Hex(otp);

    // 持久化 OTP 记录
    await _otpRepo.create(
      userId: userId,
      email: email,
      codeHash: codeHash,
      expiryMinutes: _otpExpiryMinutes,
    );

    // 发送邮件（失败不影响主流程响应，记录日志）
    try {
      await _emailService.sendOtpEmail(
        email: email,
        otp: otp,
        expireMinutes: _otpExpiryMinutes,
      );
    } catch (e) {
      // 邮件发送失败 — 不对外抛出，只打日志
      print('[AuthService] 发送 OTP 邮件失败: $e');
    }
  }

  /// 通过 OTP 验证码重置密码（忘记密码第二步）。
  ///
  /// 参数：
  ///   [email]       — 用户邮箱（与发送 OTP 时相同）
  ///   [otp]         — 用户输入的 6 位数字验证码
  ///   [newPassword] — 新密码
  ///
  /// 成功后 session_version 递增（使所有旧 JWT 失效）。
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    // 校验密码复杂度（快速失败，避免不必要的 DB 查询）
    _validatePasswordStrength(newPassword);

    // 查询该邮箱最新一条有效 OTP 记录
    final otpRecord = await _otpRepo.findLatestByEmail(email);

    if (otpRecord == null || otpRecord.isUsed) {
      throw const ValidationException('OTP_INVALID', '验证码无效或已使用，请重新获取');
    }
    if (otpRecord.isExpired) {
      throw const ValidationException('OTP_EXPIRED', '验证码已过期，请重新获取');
    }
    if (otpRecord.isExhausted) {
      throw const ValidationException(
        'RESET_PASSWORD_EXHAUSTED',
        '验证码已失效（验证次数过多），请重新获取',
      );
    }

    // 验证 OTP 哈希是否匹配
    final inputHash = _sha256Hex(otp);
    if (inputHash != otpRecord.codeHash) {
      // 累加失败次数（异步，不阻塞响应）
      await _otpRepo.incrementFailed(otpRecord.id);
      throw const ValidationException('OTP_INVALID', '验证码错误');
    }

    // 取出用户当前密码哈希，校验新密码不与旧密码相同
    final userResult = await _db.execute(
      Sql.named('SELECT password_hash FROM users WHERE id = @id LIMIT 1'),
      parameters: {'id': otpRecord.userId},
    );
    if (userResult.isEmpty) {
      throw const ValidationException('OTP_INVALID', '验证码无效或已使用，请重新获取');
    }

    final currentHash = userResult.first.toColumnMap()['password_hash'] as String;
    final newHash = _bcryptHash(newPassword);

    if (_isSamePassword(newPassword, currentHash)) {
      throw const ValidationException('PASSWORD_SAME_AS_OLD', '新密码不能与旧密码相同');
    }

    // 更新密码 + session_version 递增 + 标记 OTP 已使用（事务保证原子性）
    await _db.runTx((session) async {
      await session.execute(
        Sql.named('''
          UPDATE users
          SET password_hash = @newHash,
              session_version = session_version + 1,
              updated_at = now()
          WHERE id = @userId
        '''),
        parameters: {
          'newHash': newHash,
          'userId': otpRecord.userId,
        },
      );
      // 标记 OTP 已使用（防止二次提交）
      await _otpRepo.markUsed(otpRecord.id);
    });
  }

  // ─── 私有辅助方法 ─────────────────────────────────────────────────────

  /// 生成 6 位随机数字 OTP（cryptographically secure）
  String _generateOtp() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000–999999
    return code.toString();
  }

  /// SHA-256 hex 摘要
  String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// 简化版 bcrypt hash（实际项目中应引入 bcrypt 包）
  /// 当前占位实现：使用 SHA-256 + 固定盐（TODO: 替换为真实 bcrypt）
  String _bcryptHash(String password) {
    // TODO: 引入 bcrypt 包后替换此实现
    return sha256.convert(utf8.encode('propos_salt_$password')).toString();
  }

  /// 校验新密码是否与当前密码相同
  bool _isSamePassword(String newPassword, String currentHash) {
    // TODO: 引入 bcrypt 包后替换为 bcrypt.checkpw
    return _bcryptHash(newPassword) == currentHash;
  }

  /// 密码复杂度校验：≥8位，含大小写字母 + 数字
  void _validatePasswordStrength(String password) {
    if (password.length < 8) {
      throw ValidationException('PASSWORD_TOO_WEAK', '密码长度至少 8 位');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw ValidationException('PASSWORD_TOO_WEAK', '密码必须包含大写字母');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw ValidationException('PASSWORD_TOO_WEAK', '密码必须包含小写字母');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw ValidationException('PASSWORD_TOO_WEAK', '密码必须包含数字');
    }
  }
}
