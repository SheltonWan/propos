import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../repositories/password_reset_token_repository.dart';
import '../../../shared/email_service.dart';

/// Auth Service — 忘记密码 / 重置密码业务逻辑。
///
/// 安全规则（严格遵守）：
///   1. forgotPassword — 不论邮箱是否存在均不抛出异常（防止枚举）
///   2. 同一邮箱 5 分钟内最多申请 3 次，超出则静默忽略（仍返回正常）
///   3. token 为 32 字节随机串，SHA-256 哈希后入库，明文只在邮件链接中出现一次
///   4. resetPassword — token 使用后立即标记，不可二次提交
///   5. 重置成功后 session_version += 1（使所有旧 JWT 失效）
///   6. 二房东角色不允许自助重置（由管理员重置）
class AuthService {
  final Connection _db;
  final PasswordResetTokenRepository _tokenRepo;
  final EmailService _emailService;

  /// 速率限制：5 分钟内最多申请次数
  static const int _rateLimit = 3;
  static const Duration _rateWindow = Duration(minutes: 5);

  AuthService(this._db, this._tokenRepo, this._emailService);

  /// 申请密码重置邮件。
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
    await _tokenRepo.deleteStaleByUserId(userId);

    // 速率限制检查
    final recentCount = await _tokenRepo.countRecentByUserId(userId, _rateWindow);
    if (recentCount >= _rateLimit) {
      // 超限则静默忽略，不暴露给调用方
      return;
    }

    // 生成 32 字节随机 token（cryptographically secure）
    final rawToken = _generateSecureToken();
    final tokenHash = _sha256Hex(rawToken);

    // 持久化 token 记录
    await _tokenRepo.create(userId: userId, tokenHash: tokenHash);

    // 发送邮件（失败不影响主流程响应，记录日志）
    try {
      await _emailService.sendPasswordResetEmail(
        email: email,
        rawToken: rawToken,
      );
    } catch (e) {
      // 邮件发送失败 — 不对外抛出，只打日志
      print('[AuthService] 发送重置邮件失败: $e');
    }
  }

  /// 通过重置 token 设置新密码。
  /// 成功后 session_version 递增（使所有旧 JWT 失效）。
  Future<void> resetPassword({
    required String rawToken,
    required String newPassword,
  }) async {
    // 校验密码复杂度
    _validatePasswordStrength(newPassword);

    final tokenHash = _sha256Hex(rawToken);
    final tokenRecord = await _tokenRepo.findByHash(tokenHash);

    if (tokenRecord == null || tokenRecord.isUsed) {
      throw ValidationException('RESET_TOKEN_INVALID', 'token 不存在或已使用');
    }
    if (tokenRecord.isExpired) {
      throw ValidationException('RESET_TOKEN_EXPIRED', 'token 已过期（> 2 小时）');
    }

    // 取出用户当前密码哈希，校验新密码不与旧密码相同
    final userResult = await _db.execute(
      Sql.named('SELECT password_hash FROM users WHERE id = @id LIMIT 1'),
      parameters: {'id': tokenRecord.userId},
    );
    if (userResult.isEmpty) {
      // 用户已被删除 — token 视为无效
      throw ValidationException('RESET_TOKEN_INVALID', 'token 不存在或已使用');
    }

    final currentHash = userResult.first.toColumnMap()['password_hash'] as String;
    final newHash = _bcryptHash(newPassword);

    // 检查是否与旧密码相同（简化：仅比对 bcrypt hash，实际应使用 bcrypt.verify）
    if (_isSamePassword(newPassword, currentHash)) {
      throw ValidationException('PASSWORD_SAME_AS_OLD', '新密码不能与旧密码相同');
    }

    // 更新密码 + session_version 递增（事务保证原子性）
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
          'userId': tokenRecord.userId,
        },
      );
      // 标记 token 已使用（防止二次提交）
      await _tokenRepo.markUsed(tokenRecord.id);
    });
  }

  // ─── 私有辅助方法 ─────────────────────────────────────────────────────

  /// 生成 32 字节 URL-safe Base64 随机 token
  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
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
