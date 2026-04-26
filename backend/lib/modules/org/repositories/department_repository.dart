import 'package:postgres/postgres.dart';

import '../models/department.dart';

/// DepartmentRepository — `departments` 表 CRUD。
///
/// 安全规则：所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接。
class DepartmentRepository {
  final Session _db;

  DepartmentRepository(this._db);

  static const _selectFields = '''
    id::TEXT, name, parent_id::TEXT, level, sort_order,
    is_active, created_at, updated_at
  ''';

  /// 全表查询（按 level、sort_order、name 排序）。
  /// 调用方负责构建树结构。
  Future<List<Department>> findAll({bool includeInactive = true}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT $_selectFields
        FROM departments
        WHERE (@includeInactive OR is_active = TRUE)
        ORDER BY level, sort_order, name
      '''),
      parameters: {'includeInactive': includeInactive},
    );
    return result
        .map((r) => Department.fromColumnMap(r.toColumnMap()))
        .toList();
  }

  /// 根据 ID 查询单条记录（不含 children）。
  Future<Department?> findById(String id, {Session? tx}) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        SELECT $_selectFields
        FROM departments
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Department.fromColumnMap(result.first.toColumnMap());
  }

  /// 按名称 + parent_id 查询（路径解析、导入查重）。
  Future<Department?> findByNameUnderParent(
    String name,
    String? parentId, {
    Session? tx,
  }) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        SELECT $_selectFields
        FROM departments
        WHERE name = @name
          AND (
            (@parentId::UUID IS NULL AND parent_id IS NULL)
            OR parent_id = @parentId::UUID
          )
        LIMIT 1
      '''),
      parameters: {'name': name, 'parentId': parentId},
    );
    if (result.isEmpty) return null;
    return Department.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建部门。
  Future<Department> create({
    required String name,
    String? parentId,
    required int level,
    int sortOrder = 0,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        INSERT INTO departments (name, parent_id, level, sort_order)
        VALUES (@name, @parentId::UUID, @level, @sortOrder)
        RETURNING $_selectFields
      '''),
      parameters: {
        'name': name,
        'parentId': parentId,
        'level': level,
        'sortOrder': sortOrder,
      },
    );
    return Department.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新部门（仅更新非 null 字段）；返回更新后的记录。
  Future<Department?> update(
    String id, {
    String? name,
    String? parentId,
    bool parentIdSet = false,
    int? level,
    int? sortOrder,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        UPDATE departments SET
          name       = COALESCE(@name, name),
          parent_id  = CASE WHEN @parentIdSet THEN @parentId::UUID ELSE parent_id END,
          level      = COALESCE(@level, level),
          sort_order = COALESCE(@sortOrder, sort_order),
          updated_at = NOW()
        WHERE id = @id
        RETURNING $_selectFields
      '''),
      parameters: {
        'id': id,
        'name': name,
        'parentId': parentId,
        'parentIdSet': parentIdSet,
        'level': level,
        'sortOrder': sortOrder,
      },
    );
    if (result.isEmpty) return null;
    return Department.fromColumnMap(result.first.toColumnMap());
  }

  /// 逻辑停用（is_active = false）。
  Future<bool> deactivate(String id) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE departments
        SET is_active = FALSE, updated_at = NOW()
        WHERE id = @id AND is_active = TRUE
        RETURNING id
      '''),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// 是否存在活跃子部门。
  Future<bool> hasActiveChildren(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT 1 FROM departments
        WHERE parent_id = @id AND is_active = TRUE
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// 是否存在在职员工。
  Future<bool> hasActiveUsers(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE department_id = @id AND is_active = TRUE
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// 检查 [ancestorId] 是否为 [descendantId] 的祖先（或自身）。
  /// 用于 update parent_id 时防止形成环。
  Future<bool> isDescendantOf(
    String ancestorId,
    String descendantId,
  ) async {
    if (ancestorId == descendantId) return true;
    final result = await _db.execute(
      Sql.named('''
        WITH RECURSIVE ancestors AS (
          SELECT id, parent_id FROM departments WHERE id = @descendantId
          UNION ALL
          SELECT d.id, d.parent_id FROM departments d
          INNER JOIN ancestors a ON d.id = a.parent_id
        )
        SELECT 1 FROM ancestors WHERE id = @ancestorId LIMIT 1
      '''),
      parameters: {
        'ancestorId': ancestorId,
        'descendantId': descendantId,
      },
    );
    return result.isNotEmpty;
  }
}
