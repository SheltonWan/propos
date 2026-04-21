/// refresh_tokens 表对应数据模型。
/// 存储 JWT refresh token 的哈希值（SHA-256），明文令牌仅在签发时返回给客户端一次。
library;

/// refresh_tokens 表行记录
class RefreshToken {
  final String id;
  final String userId;

  /// SHA-256(raw token)，不存储明文
  final String tokenHash;
  final DateTime expiresAt;

  /// true 表示已被主动撤销（登出、改密、或检测到重用）
  final bool revoked;

  /// 客户端设备标识（来自请求头，便于多设备会话管理）
  final String? deviceInfo;
  final DateTime createdAt;

  const RefreshToken({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.expiresAt,
    required this.revoked,
    this.deviceInfo,
    required this.createdAt,
  });

  factory RefreshToken.fromColumnMap(Map<String, dynamic> map) {
    return RefreshToken(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tokenHash: map['token_hash'] as String,
      expiresAt: map['expires_at'] as DateTime,
      revoked: map['revoked'] as bool,
      deviceInfo: map['device_info'] as String?,
      createdAt: map['created_at'] as DateTime,
    );
  }

  /// 是否已过期
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());
}
