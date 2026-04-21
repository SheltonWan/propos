import 'package:postgres/postgres.dart';

import '../models/user_auth.dart';

/// UserAuth Repository — 用户认证相关 SQL 查询。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + named parameters，禁止字符串拼接
///   2. findByEmail 查询 password_hash，外部调用方负责不将其序列化到响应
///   3. 账号锁定和失败次数更新必须原子执行（单条 UPDATE）
class UserAuthRepository {
  final Session _db;

  UserAuthRepository(this._db);

  /// 根据邮箱查询用户（JOIN departments 获取 department_name）。
  /// 返回 null 表示用户不存在；is_active = false 时同样返回对象（由服务层判断状态）。
  Future<UserAuth?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT
          u.id,
          u.name,
          u.email,
          u.password_hash,
          u.role::TEXT          AS role,
          u.department_id,
          d.name               AS department_name,
          u.bound_contract_id,
          u.is_active,
          u.failed_login_attempts,
          u.locked_until,
          u.password_changed_at,
          u.last_login_at,
          u.session_version,
          u.frozen_at,
          u.frozen_reason
        FROM users u
        LEFT JOIN departments d ON d.id = u.department_id
        WHERE u.email = @email
        LIMIT 1
      '''),
      parameters: {'email': email},
    );
    if (result.isEmpty) return null;
    return UserAuth.fromColumnMap(result.first.toColumnMap());
  }

  /// 根据用户 ID 查询用户（用于 GET /api/auth/me 和 change-password 验证）。
  Future<UserAuth?> findById(String userId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT
          u.id,
          u.name,
          u.email,
          u.password_hash,
          u.role::TEXT          AS role,
          u.department_id,
          d.name               AS department_name,
          u.bound_contract_id,
          u.is_active,
          u.failed_login_attempts,
          u.locked_until,
          u.password_changed_at,
          u.last_login_at,
          u.session_version,
          u.frozen_at,
          u.frozen_reason
        FROM users u
        LEFT JOIN departments d ON d.id = u.department_id
        WHERE u.id = @userId
        LIMIT 1
      '''),
      parameters: {'userId': userId},
    );
    if (result.isEmpty) return null;
    return UserAuth.fromColumnMap(result.first.toColumnMap());
  }

  /// 登录成功后调用：重置失败次数、清除锁定时间、更新最后登录时间。
  Future<void> resetLoginFailures(String userId) async {
    await _db.execute(
      Sql.named('''
        UPDATE users
        SET failed_login_attempts = 0,
            locked_until          = NULL,
            last_login_at         = NOW(),
            updated_at            = NOW()
        WHERE id = @userId
      '''),
      parameters: {'userId': userId},
    );
  }

  /// 登录失败后调用：失败次数 +1，超过阈值时同步写入锁定到期时间。
  ///
  /// [lockedUntil] 非 null 时表示本次失败触发了锁定。
  Future<void> incrementLoginFailure(
    String userId, {
    DateTime? lockedUntil,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE users
        SET failed_login_attempts = failed_login_attempts + 1,
            locked_until          = @lockedUntil,
            updated_at            = NOW()
        WHERE id = @userId
      '''),
      parameters: {
        'userId': userId,
        'lockedUntil': lockedUntil,
      },
    );
  }

  /// 更新密码哈希、递增 session_version、写入 password_changed_at。
  /// 必须在事务中调用（由 LoginService.changePassword 的 runTx 保证）。
  ///
  /// [tx] 事务 session，由调用方传入
  Future<void> updatePassword(
    String userId,
    String newPasswordHash, {
    required Session tx,
  }) async {
    await tx.execute(
      Sql.named('''
        UPDATE users
        SET password_hash       = @newHash,
            session_version     = session_version + 1,
            password_changed_at = NOW(),
            updated_at          = NOW()
        WHERE id = @userId
      '''),
      parameters: {
        'userId': userId,
        'newHash': newPasswordHash,
      },
    );
  }
}
