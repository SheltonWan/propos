import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/pagination.dart';
import '../models/user_admin.dart';
import '../repositories/user_admin_repository.dart';

/// UserAdminService — 用户 CRUD 业务逻辑。
///
/// 约束：
///   1. 创建/变更角色到 sub_landlord 时，bound_contract_id 必填
///   2. 邮箱唯一；新用户邮箱重复直接抛 EMAIL_ALREADY_EXISTS
///   3. 密码复杂度：≥8 位 + 大小写 + 数字
///   4. 不直接返回 Response；错误通过 AppException 抛出
class UserAdminService {
  final Pool _db;

  UserAdminService(this._db);

  static const _validRoles = {
    'super_admin',
    'operations_manager',
    'leasing_specialist',
    'finance_staff',
    'maintenance_staff',
    'property_inspector',
    'report_viewer',
    'sub_landlord',
  };

  static const int _bcryptRounds = 12;

  // ─── 查询 ───────────────────────────────────────────────────────────────

  Future<PaginatedResult<UserSummary>> list({
    String? search,
    String? role,
    String? departmentId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (role != null) _validateRole(role);
    return UserAdminRepository(_db).findAll(
      search: search,
      role: role,
      departmentId: departmentId,
      isActive: isActive,
      page: page,
      pageSize: pageSize.clamp(1, 100),
    );
  }

  Future<UserDetail> getById(String id) async {
    final user = await UserAdminRepository(_db).findById(id);
    if (user == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return user;
  }

  // ─── 写入 ───────────────────────────────────────────────────────────────

  Future<UserDetail> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? boundContractId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    _validateRole(role);
    _validatePasswordStrength(password);
    if (role == 'sub_landlord' && (boundContractId == null || boundContractId.isEmpty)) {
      throw const ValidationException(
          'BOUND_CONTRACT_REQUIRED', '二房东角色必须绑定主合同');
    }

    final repo = UserAdminRepository(_db);
    if (await repo.emailExists(cleanEmail)) {
      throw const ConflictException('EMAIL_ALREADY_EXISTS', '邮箱已被注册');
    }

    final hash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _bcryptRounds));
    return repo.create(
      name: name.trim(),
      email: cleanEmail,
      passwordHash: hash,
      role: role,
      departmentId: departmentId,
      boundContractId: boundContractId,
    );
  }

  Future<UserDetail> updateBasic(
    String id, {
    String? name,
    String? email,
  }) async {
    final repo = UserAdminRepository(_db);
    String? cleanEmail;
    if (email != null && email.trim().isNotEmpty) {
      cleanEmail = email.trim().toLowerCase();
      // 排除当前用户自身
      final existingUser = await repo.findById(id);
      if (existingUser == null) {
        throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
      }
      if (existingUser.email != cleanEmail && await repo.emailExists(cleanEmail)) {
        throw const ConflictException('EMAIL_ALREADY_EXISTS', '邮箱已被注册');
      }
    }
    final updated = await repo.updateBasic(
      id,
      name: name?.trim().isEmpty ?? true ? null : name!.trim(),
      email: cleanEmail,
    );
    if (updated == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return updated;
  }

  Future<UserDetail> updateStatus(String id, bool isActive) async {
    final updated =
        await UserAdminRepository(_db).updateStatus(id, isActive);
    if (updated == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return updated;
  }

  Future<UserDetail> updateRole(
    String id, {
    required String role,
    String? boundContractId,
    bool boundContractIdSet = false,
  }) async {
    _validateRole(role);
    if (role == 'sub_landlord') {
      if (!boundContractIdSet || boundContractId == null || boundContractId.isEmpty) {
        throw const ValidationException(
            'BOUND_CONTRACT_REQUIRED', '二房东角色必须绑定主合同');
      }
    }
    final updated = await UserAdminRepository(_db).updateRole(
      id,
      role: role,
      boundContractId: role == 'sub_landlord' ? boundContractId : null,
      boundContractIdSet: true, // 始终覆写：非二房东角色清空
    );
    if (updated == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return updated;
  }

  Future<UserDetail> updateDepartment(String id, String departmentId) async {
    if (departmentId.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', 'department_id 不能为空');
    }
    final updated =
        await UserAdminRepository(_db).updateDepartment(id, departmentId);
    if (updated == null) {
      throw const NotFoundException('USER_NOT_FOUND', '用户不存在');
    }
    return updated;
  }

  // ─── 校验 ───────────────────────────────────────────────────────────────

  void _validateRole(String role) {
    if (!_validRoles.contains(role)) {
      throw ValidationException('VALIDATION_ERROR', '无效角色: $role');
    }
  }

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
}
