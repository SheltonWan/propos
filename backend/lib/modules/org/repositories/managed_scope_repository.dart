import 'package:postgres/postgres.dart';

import '../models/managed_scope.dart';

/// ManagedScopeRepository — `user_managed_scopes` 表 CRUD（覆写写入）。
class ManagedScopeRepository {
  final Session _db;

  ManagedScopeRepository(this._db);

  /// 按 department_id 或 user_id 过滤查询。
  /// 至少需指定其中一个。
  Future<List<ManagedScope>> find({
    String? departmentId,
    String? userId,
  }) async {
    if (departmentId == null && userId == null) {
      return const [];
    }
    final result = await _db.execute(
      Sql.named('''
        SELECT
          s.id::TEXT,
          s.department_id::TEXT,
          s.user_id::TEXT,
          s.building_id::TEXT,
          b.name AS building_name,
          s.floor_id::TEXT,
          f.floor_name,
          s.property_type::TEXT
        FROM user_managed_scopes s
        LEFT JOIN buildings b ON b.id = s.building_id
        LEFT JOIN floors    f ON f.id = s.floor_id
        WHERE (@departmentId::UUID IS NULL OR s.department_id = @departmentId::UUID)
          AND (@userId::UUID       IS NULL OR s.user_id       = @userId::UUID)
        ORDER BY s.department_id NULLS LAST, s.user_id NULLS LAST,
                 s.building_id   NULLS LAST, s.floor_id   NULLS LAST
      '''),
      parameters: {
        'departmentId': departmentId,
        'userId': userId,
      },
    );
    return result
        .map((r) => ManagedScope.fromColumnMap(r.toColumnMap()))
        .toList();
  }

  /// 删除某个范围拥有者的所有现有记录。
  Future<void> deleteByOwner({
    String? departmentId,
    String? userId,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    if (departmentId != null) {
      await db.execute(
        Sql.named('DELETE FROM user_managed_scopes WHERE department_id = @id'),
        parameters: {'id': departmentId},
      );
    } else if (userId != null) {
      await db.execute(
        Sql.named('DELETE FROM user_managed_scopes WHERE user_id = @id'),
        parameters: {'id': userId},
      );
    }
  }

  /// 写入一条范围记录。
  Future<void> insert({
    String? departmentId,
    String? userId,
    String? buildingId,
    String? floorId,
    String? propertyType,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    await db.execute(
      Sql.named('''
        INSERT INTO user_managed_scopes
          (department_id, user_id, building_id, floor_id, property_type)
        VALUES
          (@departmentId::UUID, @userId::UUID, @buildingId::UUID,
           @floorId::UUID, @propertyType::property_type)
      '''),
      parameters: {
        'departmentId': departmentId,
        'userId': userId,
        'buildingId': buildingId,
        'floorId': floorId,
        'propertyType': propertyType,
      },
    );
  }
}
