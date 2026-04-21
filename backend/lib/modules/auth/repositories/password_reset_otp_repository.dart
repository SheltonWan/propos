import 'package:postgres/postgres.dart';

import '../models/password_reset_otp.dart';

/// Repository for password_reset_otps 表。
///
/// 核心查询模式：按邮箱查最新未使用 OTP，而非按 code_hash 查询，
/// 这样可在 Service 层完成哈希比对，与 token 方案保持一致的安全边界。
class PasswordResetOtpRepository {
  final Connection _db;

  PasswordResetOtpRepository(this._db);

  /// 创建一条新 OTP 记录（过期时间 = now() + [expiryMinutes] 分钟）。
  Future<PasswordResetOtp> create({
    required String userId,
    required String email,
    required String codeHash,
    int expiryMinutes = 10,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(Duration(minutes: expiryMinutes));
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO password_reset_otps
          (user_id, email, code_hash, expires_at)
        VALUES
          (@userId, @email, @codeHash, @expiresAt)
        RETURNING id, user_id, email, code_hash,
                  created_at, expires_at, used_at, failed_attempts
      '''),
      parameters: {
        'userId': userId,
        'email': email,
        'codeHash': codeHash,
        'expiresAt': expiresAt,
      },
    );
    return PasswordResetOtp.fromRow(result.first.toColumnMap());
  }

  /// 按邮箱查询最新一条未过期且未使用的 OTP 记录（降序取第一条）。
  Future<PasswordResetOtp?> findLatestByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT id, user_id, email, code_hash,
               created_at, expires_at, used_at, failed_attempts
        FROM password_reset_otps
        WHERE email = @email
          AND used_at IS NULL
          AND expires_at > now()
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'email': email},
    );
    if (result.isEmpty) return null;
    return PasswordResetOtp.fromRow(result.first.toColumnMap());
  }

  /// 标记 OTP 已使用（[id] 对应记录写入 used_at）。
  Future<void> markUsed(String id) async {
    await _db.execute(
      Sql.named(
        'UPDATE password_reset_otps SET used_at = now() WHERE id = @id',
      ),
      parameters: {'id': id},
    );
  }

  /// 累加失败次数（验证失败时调用）。
  Future<void> incrementFailed(String id) async {
    await _db.execute(
      Sql.named(
        'UPDATE password_reset_otps SET failed_attempts = failed_attempts + 1 WHERE id = @id',
      ),
      parameters: {'id': id},
    );
  }

  /// 统计某用户在 [window] 时间窗口内发送 OTP 的次数（速率限制用）。
  Future<int> countRecentByUserId(String userId, Duration window) async {
    final since = DateTime.now().toUtc().subtract(window);
    final result = await _db.execute(
      Sql.named('''
        SELECT count(*)::int AS cnt
        FROM password_reset_otps
        WHERE user_id = @userId
          AND created_at >= @since
      '''),
      parameters: {'userId': userId, 'since': since},
    );
    return result.first.toColumnMap()['cnt'] as int? ?? 0;
  }

  /// 清理某用户的过期和已使用记录（节省存储，发新 OTP 前调用）。
  Future<void> deleteStaleByUserId(String userId) async {
    await _db.execute(
      Sql.named('''
        DELETE FROM password_reset_otps
        WHERE user_id = @userId
          AND (expires_at < now() OR used_at IS NOT NULL)
      '''),
      parameters: {'userId': userId},
    );
  }
}
