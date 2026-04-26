/// 用户管理（CRUD）模型 — 与认证模型分离，避免与 UserAuth 耦合。
library;

/// 列表项 / 详情共用基础（按 API_CONTRACT §1.5 / §1.6）。
class UserSummary {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.isActive,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory UserSummary.fromColumnMap(Map<String, dynamic> m) {
    return UserSummary(
      id: m['id'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      role: m['role'] as String,
      departmentId: m['department_id'] as String?,
      departmentName: m['department_name'] as String?,
      isActive: m['is_active'] as bool,
      lastLoginAt: m['last_login_at'] as DateTime?,
      createdAt: m['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'department_id': departmentId,
        'department_name': departmentName,
        'is_active': isActive,
        'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

/// 详情（API_CONTRACT §1.6）。
class UserDetail {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final bool isActive;
  final String? boundContractId;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime? passwordChangedAt;
  final DateTime? lastLoginAt;
  final DateTime? frozenAt;
  final String? frozenReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.isActive,
    this.boundContractId,
    required this.failedLoginAttempts,
    this.lockedUntil,
    this.passwordChangedAt,
    this.lastLoginAt,
    this.frozenAt,
    this.frozenReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDetail.fromColumnMap(Map<String, dynamic> m) {
    return UserDetail(
      id: m['id'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      role: m['role'] as String,
      departmentId: m['department_id'] as String?,
      departmentName: m['department_name'] as String?,
      isActive: m['is_active'] as bool,
      boundContractId: m['bound_contract_id'] as String?,
      failedLoginAttempts: (m['failed_login_attempts'] as num).toInt(),
      lockedUntil: m['locked_until'] as DateTime?,
      passwordChangedAt: m['password_changed_at'] as DateTime?,
      lastLoginAt: m['last_login_at'] as DateTime?,
      frozenAt: m['frozen_at'] as DateTime?,
      frozenReason: m['frozen_reason'] as String?,
      createdAt: m['created_at'] as DateTime,
      updatedAt: m['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'department_id': departmentId,
        'department_name': departmentName,
        'is_active': isActive,
        'bound_contract_id': boundContractId,
        'failed_login_attempts': failedLoginAttempts,
        'locked_until': lockedUntil?.toUtc().toIso8601String(),
        'password_changed_at': passwordChangedAt?.toUtc().toIso8601String(),
        'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
        'frozen_at': frozenAt?.toUtc().toIso8601String(),
        'frozen_reason': frozenReason,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
