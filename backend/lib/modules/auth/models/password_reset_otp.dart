/// OTP 密码重置记录模型（对应 password_reset_otps 表）。
///
/// 安全设计：
///   - 6 位数字 OTP 明文仅在邮件中出现一次，数据库只存 SHA-256 哈希
///   - 有效期 10 分钟（[isExpired]）
///   - 最多允许 5 次验证失败尝试（[isExhausted]），超出则作废
///   - 使用后立即标记 [usedAt]，不可二次提交（[isUsed]）
class PasswordResetOtp {
  final String id;
  final String userId;

  /// 冗余存储邮箱，用于按邮箱查询（避免 JOIN users）
  final String email;

  /// SHA-256(OTP 明文) — 不存明文
  final String codeHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;

  /// 累计验证失败次数（达到上限则不可继续使用）
  final int failedAttempts;

  /// 每条 OTP 最多允许的验证失败次数
  static const int maxFailedAttempts = 5;

  const PasswordResetOtp({
    required this.id,
    required this.userId,
    required this.email,
    required this.codeHash,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    required this.failedAttempts,
  });

  /// OTP 是否已过期（超过 10 分钟）
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// OTP 是否已成功使用
  bool get isUsed => usedAt != null;

  /// OTP 失败次数是否已耗尽（>= maxFailedAttempts）
  bool get isExhausted => failedAttempts >= maxFailedAttempts;

  factory PasswordResetOtp.fromRow(Map<String, dynamic> row) {
    return PasswordResetOtp(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      email: row['email'] as String,
      codeHash: row['code_hash'] as String,
      createdAt: (row['created_at'] as DateTime).toUtc(),
      expiresAt: (row['expires_at'] as DateTime).toUtc(),
      usedAt: row['used_at'] != null ? (row['used_at'] as DateTime).toUtc() : null,
      failedAttempts: row['failed_attempts'] as int? ?? 0,
    );
  }
}
