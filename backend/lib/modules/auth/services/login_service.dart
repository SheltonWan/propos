import 'dart:convert';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';

import '../../../config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../models/user_auth.dart';
import '../repositories/user_auth_repository.dart';
import '../repositories/refresh_token_repository.dart';

/// 登录认证服务 — 负责登录/刷新/登出/改密/查当前用户五个核心业务流程。
///
/// 安全规则（严格遵守）：
///   1. JWT 签名算法固定 HS256（JWTAlgorithm.HS256），prohibit alg:none
///   2. bcrypt 验证使用 BCrypt.checkpw()，cost=12；哈希使用 BCrypt.hashpw()
///   3. 登录失败累计 ≥ _maxFailedAttempts 时锁定账号 _lockDuration
///   4. 用户不存在时执行假 bcrypt 比较，防止时序攻击揭露账号存在性
///   5. refreshToken 执行旋转：旧 token 立即撤销，新 token 签发
///   6. changePassword 在事务中同时更新密码 + 撤销全部 refresh token
///   7. 审计日志记录 change-password 操作（密码变更审计）
class LoginService {
  final Pool _db;
  final AppConfig _config;
  final UserAuthRepository _userRepo;
  final RefreshTokenRepository _refreshTokenRepo;

  /// 账号锁定阈值：连续失败次数
  static const int _maxFailedAttempts = 5;

  /// 锁定时长
  static const Duration _lockDuration = Duration(minutes: 30);

  /// Refresh Token 有效期
  static const Duration _refreshTokenTtl = Duration(days: 30);

  /// bcrypt 工作因子（≥12）
  static const int _bcryptRounds = 12;

  /// 用于 timing attack 防护的假用户密码哈希（bcrypt cost=_bcryptRounds）
  /// 在用户不存在时执行一次 checkpw，使响应时间与真实验证一致。
  static final String _dummyHash =
      BCrypt.hashpw('DumMy@Pr0pOS!2026#sentinel', BCrypt.gensalt(logRounds: _bcryptRounds));

  LoginService(this._db, this._config, this._userRepo, this._refreshTokenRepo);

  // ─── 公开业务方法 ────────────────────────────────────────────────────────

  /// 邮箱 + 密码登录，返回 access_token、refresh_token、用户简报。
  ///
  /// 抛出：
  ///   [AccountLockedException]  — 账号已锁定（含解锁时间）
  ///   [UnauthorizedException]   — 邮箱不存在或密码错误（统一 INVALID_CREDENTIALS）
  ///   [AppException ACCOUNT_DISABLED] — 账号已停用
  ///   [AppException ACCOUNT_FROZEN]   — 二房东账号已冻结
  Future<LoginResponse> login({
    required String email,
    required String password,
    String? deviceInfo,
  }) async {
    // 1. 查询用户（不区分是否存在，先统一执行后续检查）
    final user = await _userRepo.findByEmail(email);

    // 2. 用户不存在：执行假 bcrypt 比较后返回统一错误（防时序攻击）
    if (user == null) {
      BCrypt.checkpw(password, _dummyHash); // 时序对齐
      throw const UnauthorizedException(
          'INVALID_CREDENTIALS', '邮箱或密码错误');
    }

    // 3. 账号停用检查
    if (!user.isActive) {
      throw const AppException('ACCOUNT_DISABLED', '账号已停用，请联系管理员', 403);
    }

    // 4. 二房东冻结检查
    if (user.frozenAt != null) {
      throw const AppException('ACCOUNT_FROZEN', '账号已冻结，请联系管理员', 403);
    }

    // 5. 账号锁定检查
    final lockedUntil = user.lockedUntil;
    if (lockedUntil != null &&
        lockedUntil.toUtc().isAfter(DateTime.now().toUtc())) {
      BCrypt.checkpw(password, _dummyHash); // 时序对齐
      throw AccountLockedException(lockedUntil);
    }

    // 6. bcrypt 密码验证（恒定时间比较）
    final isValid = BCrypt.checkpw(password, user.passwordHash);
    if (!isValid) {
      await _handleLoginFailure(user);
      throw const UnauthorizedException(
          'INVALID_CREDENTIALS', '邮箱或密码错误');
    }

    // 7. 登录成功：重置失败计数 + 更新 last_login_at
    await _userRepo.resetLoginFailures(user.id);

    // 8. 签发 JWT + refresh token
    final pair = await _issueTokenPair(user, deviceInfo: deviceInfo);

    return LoginResponse(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
      expiresIn: pair.expiresIn,
      user: UserBrief.fromUserAuth(user),
    );
  }

  /// 使用 refresh token 换取新的 access_token + refresh_token（旋转刷新）。
  ///
  /// 抛出：
  ///   [UnauthorizedException TOKEN_REVOKED] — token 已撤销或不存在
  ///   [UnauthorizedException TOKEN_EXPIRED] — token 已过期
  ///   [UnauthorizedException ACCOUNT_DISABLED / ACCOUNT_FROZEN] — 账号状态异常
  Future<TokenPair> refresh({
    required String rawRefreshToken,
    String? deviceInfo,
  }) async {
    final hash = _sha256Hex(rawRefreshToken);
    final stored = await _refreshTokenRepo.findByHash(hash);

    if (stored == null || stored.revoked) {
      throw const UnauthorizedException('TOKEN_REVOKED', '刷新令牌已失效，请重新登录');
    }
    if (stored.isExpired) {
      // 过期 token 顺手撤销
      await _refreshTokenRepo.revoke(stored.id);
      throw const UnauthorizedException('TOKEN_EXPIRED', '刷新令牌已过期，请重新登录');
    }

    // 验证用户当前状态
    final user = await _userRepo.findById(stored.userId);
    if (user == null || !user.isActive) {
      await _refreshTokenRepo.revoke(stored.id);
      throw const UnauthorizedException('ACCOUNT_DISABLED', '账号已停用，请联系管理员');
    }
    if (user.frozenAt != null) {
      await _refreshTokenRepo.revoke(stored.id);
      throw const UnauthorizedException('ACCOUNT_FROZEN', '账号已冻结，请联系管理员');
    }

    // 旋转：先撤销旧 token，再签发新 token 对
    await _refreshTokenRepo.revoke(stored.id);
    return _issueTokenPair(user, deviceInfo: deviceInfo);
  }

  /// 登出：撤销当前 refresh token（access token 等待 TTL 自然失效）。
  ///
  /// [userId] 来自 JWT RequestContext，用于写入审计日志。
  /// 幂等：无论 refresh token 是否有效均返回成功，避免泄露 token 状态。
  Future<void> logout({
    required String rawRefreshToken,
    required String userId,
  }) async {
    final hash = _sha256Hex(rawRefreshToken);
    final stored = await _refreshTokenRepo.findByHash(hash);
    // 不论 token 是否有效都返回成功（幂等），避免泄露 token 状态
    if (stored != null && !stored.revoked) {
      await _refreshTokenRepo.revoke(stored.id);
    }
    // 写登出审计日志（无论 refresh token 是否已失效，登出操作本身均需记录）
    await _db.execute(
      Sql.named('''
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id)
        VALUES (@userId, 'USER_LOGOUT', 'users', @userId)
      '''),
      parameters: {'userId': userId},
    );
  }

  /// 修改密码（已登录用户，需提供旧密码验证）。
  /// 修改成功后撤销该用户所有 refresh token，并签发新的令牌对。
  ///
  /// 抛出：
  ///   [UnauthorizedException INVALID_CREDENTIALS] — 旧密码错误
  ///   [ValidationException PASSWORD_TOO_WEAK]      — 新密码不符合复杂度要求
  ///   [ValidationException PASSWORD_SAME_AS_OLD]   — 新旧密码相同
  Future<TokenPair> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? deviceInfo,
  }) async {
    // 1. 查询用户并验证旧密码
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw const UnauthorizedException('INVALID_CREDENTIALS', '旧密码错误');
    }

    final isValidOld = BCrypt.checkpw(oldPassword, user.passwordHash);
    if (!isValidOld) {
      throw const UnauthorizedException('INVALID_CREDENTIALS', '旧密码错误');
    }

    // 2. 校验新密码复杂度
    _validatePasswordStrength(newPassword);

    // 3. 新旧密码相同校验
    if (BCrypt.checkpw(newPassword, user.passwordHash)) {
      throw const ValidationException(
          'PASSWORD_SAME_AS_OLD', '新密码不能与旧密码相同');
    }

    // 4. 哈希新密码
    final newHash =
        BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: _bcryptRounds));

    // 5. 事务：更新密码 + 撤销全部 refresh token
    await _db.runTx((tx) async {
      await _userRepo.updatePassword(userId, newHash, tx: tx);
      await _refreshTokenRepo.revokeAllForUser(userId, tx: tx);
      // 写改密审计日志
      await tx.execute(
        Sql.named('''
          INSERT INTO audit_logs (user_id, action, resource_type, resource_id)
          VALUES (@userId, 'USER_PASSWORD_CHANGED', 'users', @userId)
        '''),
        parameters: {'userId': userId},
      );
    });

    // 6. 签发新令牌对（改密后需重新登录，此处直接提供便捷令牌）
    return _issueTokenPair(user, deviceInfo: deviceInfo);
  }

  /// 获取当前登录用户详情（GET /api/auth/me）。
  ///
  /// 抛出：
  ///   [NotFoundException USER_NOT_FOUND] — userId 对应账号不存在
  Future<CurrentUserResponse> getMe({required String userId}) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return CurrentUserResponse(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      departmentId: user.departmentId,
      departmentName: user.departmentName,
      mustChangePassword:
          user.role == 'sub_landlord' && user.passwordChangedAt == null,
      permissions: _permissionsForRole(user.role),
      lastLoginAt: user.lastLoginAt,
    );
  }

  // ─── 私有辅助 ────────────────────────────────────────────────────────────

  /// 签发 JWT（HS256）+ 创建 refresh token 记录，返回令牌对。
  Future<TokenPair> _issueTokenPair(
    UserAuth user, {
    String? deviceInfo,
  }) async {
    final expiresIn = _config.jwtExpiresInHours * 3600;
    final accessToken = _signJwt(user, expiresInSeconds: expiresIn);

    // 生成 32 字节随机 raw refresh token（hex = 64 字符）
    final rawRefreshToken = _generateSecureToken();
    final tokenHash = _sha256Hex(rawRefreshToken);
    final expiresAt = DateTime.now().toUtc().add(_refreshTokenTtl);

    await _refreshTokenRepo.create(
      userId: user.id,
      tokenHash: tokenHash,
      expiresAt: expiresAt,
      deviceInfo: deviceInfo,
    );

    return TokenPair(
      accessToken: accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: expiresIn,
    );
  }

  /// 签发 JWT，算法固定 HS256，禁止使用其他算法。
  String _signJwt(UserAuth user, {required int expiresInSeconds}) {
    final jwt = JWT(
      {
        'sub': user.id,
        'role': user.role,
        if (user.boundContractId != null)
          'bound_contract_id': user.boundContractId,
        'session_version': user.sessionVersion,
      },
      // issuer / audience 按需启用后可在 auth_middleware 验证
    );
    return jwt.sign(
      SecretKey(_config.jwtSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: Duration(seconds: expiresInSeconds),
    );
  }

  /// 处理登录失败：累计次数，超限时锁定账号。
  Future<void> _handleLoginFailure(UserAuth user) async {
    final newCount = user.failedLoginAttempts + 1;
    DateTime? lockUntil;
    if (newCount >= _maxFailedAttempts) {
      lockUntil = DateTime.now().toUtc().add(_lockDuration);
    }
    await _userRepo.incrementLoginFailure(user.id, lockedUntil: lockUntil);
    if (lockUntil != null) {
      // 锁定后抛出 AccountLockedException（由调用方在密码错误分支之前处理）
      // 此处不再抛出，由 login() 在密码验证后的分支统一处理 INVALID_CREDENTIALS
      // 但调用方下次调用时锁定状态已生效（步骤 5 会拦截）
    }
  }

  /// 生成 32 字节加密安全随机 token（hex 编码，64 字符）。
  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// SHA-256 hex 摘要（用于 refresh token 存储）。
  String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// 密码复杂度校验：≥8位，含大小写字母 + 数字
  void _validatePasswordStrength(String password) {
    if (password.length < 8) {
      throw const ValidationException('PASSWORD_TOO_WEAK', '密码长度至少 8 位');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw const ValidationException('PASSWORD_TOO_WEAK', '密码必须包含大写字母');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw const ValidationException('PASSWORD_TOO_WEAK', '密码必须包含小写字母');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw const ValidationException('PASSWORD_TOO_WEAK', '密码必须包含数字');
    }
  }

  /// 根据角色返回权限字符串列表（来自 RBAC_MATRIX.md）。
  static List<String> _permissionsForRole(String role) {
    return _rolePermissions[role] ?? const [];
  }

  /// 角色 → 权限映射表（严格按 docs/backend/RBAC_MATRIX.md 定义）
  static const Map<String, List<String>> _rolePermissions = {
    'super_admin': [
      'org.read', 'org.manage',
      'assets.read', 'assets.write',
      'contracts.read', 'contracts.write',
      'deposit.read', 'deposit.write',
      'finance.read', 'finance.write',
      'kpi.view', 'kpi.manage', 'kpi.appeal',
      'meterReading.write', 'turnoverReview.approve',
      'workorders.read', 'workorders.write',
      'sublease.read', 'sublease.write',
      'alerts.read', 'alerts.write',
      'ops.read', 'ops.write', 'import.execute',
      'notifications.read', 'approvals.manage', 'dashboard.read',
    ],
    'operations_manager': [
      'org.read', 'org.manage',
      'assets.read', 'assets.write',
      'contracts.read', 'contracts.write',
      'deposit.read', 'deposit.write',
      'finance.read',
      'kpi.view', 'kpi.manage', 'kpi.appeal',
      'meterReading.write', 'turnoverReview.approve',
      'workorders.read', 'workorders.write',
      'sublease.read', 'sublease.write',
      'alerts.read', 'alerts.write',
      'ops.read', 'import.execute',
      'notifications.read', 'approvals.manage', 'dashboard.read',
    ],
    'leasing_specialist': [
      'org.read',
      'assets.read',
      'contracts.read', 'contracts.write',
      'deposit.read',
      'finance.read',
      'kpi.view', 'kpi.appeal',
      'meterReading.write',
      'workorders.read',
      'sublease.read', 'sublease.write',
      'alerts.read', 'import.execute',
      'notifications.read', 'dashboard.read',
    ],
    'finance_staff': [
      'org.read',
      'assets.read',
      'contracts.read',
      'deposit.read', 'deposit.write',
      'finance.read', 'finance.write',
      'kpi.view', 'kpi.appeal',
      'meterReading.write', 'turnoverReview.approve',
      'sublease.read',
      'alerts.read', 'import.execute',
      'notifications.read', 'dashboard.read',
    ],
    'maintenance_staff': [
      'workorders.read', 'workorders.write',
      'meterReading.write',
      'kpi.view', 'kpi.appeal',
      'notifications.read', 'dashboard.read',
    ],
    'property_inspector': [
      'org.read',
      'assets.read',
      'contracts.read',
      'workorders.read',
      'meterReading.write',
      'kpi.view', 'kpi.appeal',
      'notifications.read', 'dashboard.read',
    ],
    'report_viewer': [
      'org.read',
      'assets.read',
      'contracts.read',
      'deposit.read',
      'finance.read',
      'sublease.read',
      'alerts.read',
      'kpi.view',
      'notifications.read', 'dashboard.read',
    ],
    'sub_landlord': [
      'sublease.portal',
      'notifications.read',
    ],
  };
}
