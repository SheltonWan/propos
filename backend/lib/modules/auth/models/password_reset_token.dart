/// 密码重置 Token 模型。
/// 数据库只存 SHA-256 哈希，原始 token 仅出现在邮件链接中。
class PasswordResetToken {
  final String id;
  final String userId;
  /// SHA-256 哈希后的 token 值
  final String tokenHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  /// null 表示尚未使用
  final DateTime? usedAt;

  const PasswordResetToken({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
  bool get isUsed => usedAt != null;

  factory PasswordResetToken.fromRow(Map<String, dynamic> row) {
    return PasswordResetToken(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tokenHash: row['token_hash'] as String,
      createdAt: (row['created_at'] as DateTime).toUtc(),
      expiresAt: (row['expires_at'] as DateTime).toUtc(),
      usedAt: row['used_at'] != null
          ? (row['used_at'] as DateTime).toUtc()
          : null,
    );
  }
}
