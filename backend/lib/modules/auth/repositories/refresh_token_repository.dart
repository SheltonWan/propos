import 'package:postgres/postgres.dart';

import '../models/refresh_token.dart';

/// RefreshToken Repository — refresh_tokens 表 CRUD 操作。
///
/// 安全规则：
///   1. 只存储 SHA-256(raw token)，明文不落库
///   2. 所有查询通过命名参数，禁止字符串拼接
///   3. 撤销操作优先使用软删除（revoked = true），不依赖物理删除
class RefreshTokenRepository {
  final Session _db;

  RefreshTokenRepository(this._db);

  /// 创建新 refresh token 记录（already-hashed token_hash）。
  Future<RefreshToken> create({
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
    String? deviceInfo,
    Session? tx,
  }) async {
    final conn = tx ?? _db;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO refresh_tokens (user_id, token_hash, expires_at, device_info)
        VALUES (@userId, @tokenHash, @expiresAt, @deviceInfo)
        RETURNING id, user_id, token_hash, expires_at, revoked, device_info, created_at
      '''),
      parameters: {
        'userId': userId,
        'tokenHash': tokenHash,
        'expiresAt': expiresAt,
        'deviceInfo': deviceInfo,
      },
    );
    return RefreshToken.fromColumnMap(result.first.toColumnMap());
  }

  /// 根据 token_hash 查询 refresh token 记录（含用户 JOIN 验证）。
  Future<RefreshToken?> findByHash(String tokenHash) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT id, user_id, token_hash, expires_at, revoked, device_info, created_at
        FROM refresh_tokens
        WHERE token_hash = @tokenHash
        LIMIT 1
      '''),
      parameters: {'tokenHash': tokenHash},
    );
    if (result.isEmpty) return null;
    return RefreshToken.fromColumnMap(result.first.toColumnMap());
  }

  /// 撤销单条 refresh token（用于旋转刷新：新 token 签发后撤销旧 token）。
  Future<void> revoke(String id, {Session? tx}) async {
    final conn = tx ?? _db;
    await conn.execute(
      Sql.named('''
        UPDATE refresh_tokens
        SET revoked = TRUE
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  /// 撤销某用户的全部 refresh token（改密/冻结场景：使所有已签发令牌失效）。
  Future<void> revokeAllForUser(String userId, {Session? tx}) async {
    final conn = tx ?? _db;
    await conn.execute(
      Sql.named('''
        UPDATE refresh_tokens
        SET revoked = TRUE
        WHERE user_id = @userId
          AND revoked = FALSE
      '''),
      parameters: {'userId': userId},
    );
  }

  /// 清理已过期且已撤销的历史记录（定时任务调用，防止表膨胀）。
  Future<void> deleteExpiredAndRevoked() async {
    await _db.execute(
      Sql.named('''
        DELETE FROM refresh_tokens
        WHERE (expires_at < NOW() OR revoked = TRUE)
          AND created_at < NOW() - INTERVAL '30 days'
      '''),
    );
  }
}
