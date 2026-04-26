import 'package:postgres/postgres.dart';

import '../../../core/pagination.dart';
import '../models/user_admin.dart';

/// UserAdminRepository — 用户 CRUD 与查询（与认证用 UserAuthRepository 分离）。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数
///   2. 所有列表查询不返回 password_hash
///   3. 模糊搜索只用 ILIKE，参数化绑定
class UserAdminRepository {
  final Session _db;

  UserAdminRepository(this._db);

  static const _summaryFields = '''
    u.id::TEXT, u.name, u.email, u.role::TEXT AS role,
    u.department_id::TEXT, d.name AS department_name,
    u.is_active, u.last_login_at, u.created_at
  ''';

  static const _detailFields = '''
    u.id::TEXT, u.name, u.email, u.role::TEXT AS role,
    u.department_id::TEXT, d.name AS department_name,
    u.is_active, u.bound_contract_id::TEXT,
    u.failed_login_attempts, u.locked_until,
    u.password_changed_at, u.last_login_at,
    u.frozen_at, u.frozen_reason,
    u.created_at, u.updated_at
  ''';

  /// 列表查询（含 search/role/department/is_active 过滤 + 分页）。
  Future<PaginatedResult<UserSummary>> findAll({
    String? search,
    String? role,
    String? departmentId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;
    final like = (search == null || search.trim().isEmpty)
        ? null
        : '%${search.trim()}%';

    final countResult = await _db.execute(
      Sql.named('''
        SELECT COUNT(*) AS total
        FROM users u
        LEFT JOIN departments d ON d.id = u.department_id
        WHERE (@like::TEXT IS NULL OR u.name ILIKE @like OR u.email ILIKE @like)
          AND (@role::TEXT IS NULL OR u.role::TEXT = @role)
          AND (@departmentId::UUID IS NULL OR u.department_id = @departmentId::UUID)
          AND (@isActive::BOOLEAN IS NULL OR u.is_active = @isActive)
      '''),
      parameters: {
        'like': like,
        'role': role,
        'departmentId': departmentId,
        'isActive': isActive,
      },
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final dataResult = await _db.execute(
      Sql.named('''
        SELECT $_summaryFields
        FROM users u
        LEFT JOIN departments d ON d.id = u.department_id
        WHERE (@like::TEXT IS NULL OR u.name ILIKE @like OR u.email ILIKE @like)
          AND (@role::TEXT IS NULL OR u.role::TEXT = @role)
          AND (@departmentId::UUID IS NULL OR u.department_id = @departmentId::UUID)
          AND (@isActive::BOOLEAN IS NULL OR u.is_active = @isActive)
        ORDER BY u.created_at DESC, u.id
        LIMIT @pageSize OFFSET @offset
      '''),
      parameters: {
        'like': like,
        'role': role,
        'departmentId': departmentId,
        'isActive': isActive,
        'pageSize': pageSize,
        'offset': offset,
      },
    );

    final items = dataResult
        .map((r) => UserSummary.fromColumnMap(r.toColumnMap()))
        .toList();
    return PaginatedResult(
      items: items,
      meta: PaginationMeta(page: page, pageSize: pageSize, total: total),
    );
  }

  /// 详情。
  Future<UserDetail?> findById(String id, {Session? tx}) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        SELECT $_detailFields
        FROM users u
        LEFT JOIN departments d ON d.id = u.department_id
        WHERE u.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return UserDetail.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建用户（password_hash 由 Service 计算并传入）。
  Future<UserDetail> create({
    required String name,
    required String email,
    required String passwordHash,
    required String role,
    String? departmentId,
    String? boundContractId,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        INSERT INTO users (
          name, email, password_hash, role,
          department_id, bound_contract_id
        )
        VALUES (
          @name, @email, @passwordHash, @role::user_role,
          @departmentId::UUID, @boundContractId::UUID
        )
        RETURNING id::TEXT
      '''),
      parameters: {
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
        'departmentId': departmentId,
        'boundContractId': boundContractId,
      },
    );
    final id = result.first.toColumnMap()['id'] as String;
    return (await findById(id, tx: tx))!;
  }

  /// 更新基本信息（name / email）。
  Future<UserDetail?> updateBasic(
    String id, {
    String? name,
    String? email,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE users SET
          name       = COALESCE(@name, name),
          email      = COALESCE(@email, email),
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'name': name, 'email': email},
    );
    return findById(id);
  }

  /// 切换启停状态；停用时 session_version 自增以使旧 token 失效。
  Future<UserDetail?> updateStatus(String id, bool isActive) async {
    await _db.execute(
      Sql.named('''
        UPDATE users SET
          is_active       = @isActive,
          session_version = CASE WHEN @isActive THEN session_version
                                 ELSE session_version + 1 END,
          updated_at      = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'isActive': isActive},
    );
    return findById(id);
  }

  /// 变更角色（同时维护 bound_contract_id）。
  Future<UserDetail?> updateRole(
    String id, {
    required String role,
    String? boundContractId,
    bool boundContractIdSet = false,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE users SET
          role              = @role::user_role,
          bound_contract_id = CASE WHEN @boundContractIdSet
                                   THEN @boundContractId::UUID
                                   ELSE bound_contract_id END,
          session_version   = session_version + 1,
          updated_at        = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'role': role,
        'boundContractId': boundContractId,
        'boundContractIdSet': boundContractIdSet,
      },
    );
    return findById(id);
  }

  /// 变更所属部门。
  Future<UserDetail?> updateDepartment(String id, String? departmentId) async {
    await _db.execute(
      Sql.named('''
        UPDATE users SET
          department_id = @departmentId::UUID,
          updated_at    = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'departmentId': departmentId},
    );
    return findById(id);
  }

  /// 邮箱是否存在（用于创建查重）。
  Future<bool> emailExists(String email, {Session? tx}) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('SELECT 1 FROM users WHERE email = @email LIMIT 1'),
      parameters: {'email': email},
    );
    return result.isNotEmpty;
  }
}
