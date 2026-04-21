/// 用户认证数据模型。
/// 包含从 users 表读取的完整认证相关字段，仅在 auth 模块内部流转，
/// 禁止直接序列化到任何 API 响应（password_hash 字段必须在服务层过滤）。
library;

/// 用户完整认证数据——从 users 表映射
class UserAuth {
  final String id;
  final String name;
  final String email;

  /// bcrypt 密码哈希，仅用于验证，禁止输出到响应
  final String passwordHash;
  final String role;
  final String? departmentId;
  final String? departmentName;

  /// 二房东绑定合同 ID（仅 sub_landlord 使用）
  final String? boundContractId;
  final bool isActive;
  final int failedLoginAttempts;

  /// 非空且 > now() 时表示账号处于锁定状态
  final DateTime? lockedUntil;

  /// 首次修改密码后写入；NULL 表示从未主动改过密码
  final DateTime? passwordChangedAt;
  final DateTime? lastLoginAt;

  /// 每次改密/冻结后递增；旧 JWT 的 session_version 不匹配时拒绝刷新
  final int sessionVersion;

  /// 二房东账号被冻结时写入
  final DateTime? frozenAt;
  final String? frozenReason;

  const UserAuth({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.boundContractId,
    required this.isActive,
    required this.failedLoginAttempts,
    this.lockedUntil,
    this.passwordChangedAt,
    this.lastLoginAt,
    required this.sessionVersion,
    this.frozenAt,
    this.frozenReason,
  });

  factory UserAuth.fromColumnMap(Map<String, dynamic> map) {
    return UserAuth(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      departmentId: map['department_id'] as String?,
      departmentName: map['department_name'] as String?,
      boundContractId: map['bound_contract_id'] as String?,
      isActive: map['is_active'] as bool,
      failedLoginAttempts: map['failed_login_attempts'] as int,
      lockedUntil: map['locked_until'] as DateTime?,
      passwordChangedAt: map['password_changed_at'] as DateTime?,
      lastLoginAt: map['last_login_at'] as DateTime?,
      sessionVersion: map['session_version'] as int,
      frozenAt: map['frozen_at'] as DateTime?,
      frozenReason: map['frozen_reason'] as String?,
    );
  }
}

/// 登录/刷新响应中的用户简报（已脱敏，不含敏感字段）
class UserBrief {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;

  /// 是否需要强制修改密码（sub_landlord 且从未改过密码）
  final bool mustChangePassword;

  const UserBrief({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.mustChangePassword,
  });

  /// 从 UserAuth 派生 UserBrief
  factory UserBrief.fromUserAuth(UserAuth user) {
    return UserBrief(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      departmentId: user.departmentId,
      departmentName: user.departmentName,
      mustChangePassword:
          user.role == 'sub_landlord' && user.passwordChangedAt == null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (departmentId != null) 'department_id': departmentId,
        if (departmentName != null) 'department_name': departmentName,
        'must_change_password': mustChangePassword,
      };
}

/// 登录成功响应（POST /api/auth/login）
class LoginResponse {
  final String accessToken;
  final String refreshToken;

  /// JWT 有效期秒数（= jwtExpiresInHours * 3600）
  final int expiresIn;

  /// Refresh token 到期时刻（UTC），客户端据此判断是否需要提前续期。
  final DateTime refreshTokenExpiresAt;
  final UserBrief user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'refresh_token_expires_at': refreshTokenExpiresAt.toUtc().toIso8601String(),
        'user': user.toJson(),
      };
}

/// GET /api/auth/me 响应数据
class CurrentUserResponse {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final bool mustChangePassword;

  /// 基于角色派生的权限字符串列表
  final List<String> permissions;
  final DateTime? lastLoginAt;

  const CurrentUserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.mustChangePassword,
    required this.permissions,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (departmentId != null) 'department_id': departmentId,
        if (departmentName != null) 'department_name': departmentName,
        'must_change_password': mustChangePassword,
        'permissions': permissions,
        if (lastLoginAt != null)
          'last_login_at': lastLoginAt!.toUtc().toIso8601String(),
      };
}

/// POST /api/auth/refresh 和 POST /api/auth/change-password 的令牌对响应
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  /// Refresh token 到期时刻（UTC）。
  final DateTime refreshTokenExpiresAt;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshTokenExpiresAt,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'refresh_token_expires_at': refreshTokenExpiresAt.toUtc().toIso8601String(),
      };
}
