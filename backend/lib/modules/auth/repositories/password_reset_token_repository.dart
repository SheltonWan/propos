import 'package:postgres/postgres.dart';

import '../models/password_reset_token.dart';

/// Repository for password_reset_tokens 表。
/// 安全约定：
///   - 存入 token_hash（SHA-256），不存原始 token
///   - 每次发起新请求前先清理同用户的已过期/已使用记录
///   - findByHash 返回 null 视为 token 无效
class PasswordResetTokenRepository {
  final Connection _db;

  PasswordResetTokenRepository(this._db);

  /// 创建重置 token 记录（token 有效期 2 小时）
  Future<PasswordResetToken> create({
    required String userId,
    required String tokenHash,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 2));
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
        VALUES (@userId, @tokenHash, @expiresAt)
        RETURNING id, user_id, token_hash, created_at, expires_at, used_at
      '''),
      parameters: {
        'userId': userId,
        'tokenHash': tokenHash,
        'expiresAt': expiresAt,
      },
    );
    return PasswordResetToken.fromRow(result.first.toColumnMap());
  }

  /// 通过 token_hash 查找（未使用、未过期）
  Future<PasswordResetToken?> findByHash(String tokenHash) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT id, user_id, token_hash, created_at, expires_at, used_at
        FROM password_reset_tokens
        WHERE token_hash = @tokenHash
        LIMIT 1
      '''),
      parameters: {'tokenHash': tokenHash},
    );
    if (result.isEmpty) return null;
    return PasswordResetToken.fromRow(result.first.toColumnMap());
  }

  /// 标记 token 已使用（设置 used_at = 当前时间）
  Future<void> markUsed(String id) async {
    await _db.execute(
      Sql.named('''
        UPDATE password_reset_tokens
        SET used_at = now()
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  /// 统计同一用户在指定时间窗口内的请求数（用于速率限制）
  Future<int> countRecentByUserId(String userId, Duration window) async {
    final since = DateTime.now().toUtc().subtract(window);
    final result = await _db.execute(
      Sql.named('''
        SELECT count(*)::int AS cnt
        FROM password_reset_tokens
        WHERE user_id = @userId
          AND created_at >= @since
      '''),
      parameters: {
        'userId': userId,
        'since': since,
      },
    );
    return result.first.toColumnMap()['cnt'] as int? ?? 0;
  }

  /// 清理同用户的已过期或已使用的历史记录（防止表无限增长）
  Future<void> deleteStaleByUserId(String userId) async {
    await _db.execute(
      Sql.named('''
        DELETE FROM password_reset_tokens
        WHERE user_id = @userId
          AND (expires_at < now() OR used_at IS NOT NULL)
      '''),
      parameters: {'userId': userId},
    );
  }
}
