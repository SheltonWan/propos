import 'package:postgres/postgres.dart';

import '../models/building.dart';

/// BuildingRepository — buildings 表的 CRUD 操作。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接
///   2. 楼栋数量有限（<10），列表不分页
class BuildingRepository {
  final Session _db;

  BuildingRepository(this._db);

  /// 获取所有楼栋列表（按 name 排序）
  Future<List<Building>> findAll() async {
    final result = await _db.execute(
      Sql.named('''
        SELECT id::TEXT, name, property_type::TEXT, total_floors, basement_floors,
               gfa, nla, address, built_year,
               created_at, updated_at
        FROM buildings
        ORDER BY name
      '''),
    );
    return result.map((r) => Building.fromColumnMap(r.toColumnMap())).toList();
  }

  /// 根据 ID 查询楼栋，不存在返回 null
  Future<Building?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT id::TEXT, name, property_type::TEXT, total_floors, basement_floors,
               gfa, nla, address, built_year,
               created_at, updated_at
        FROM buildings
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Building.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建楼栋，返回新记录
  Future<Building> create({
    required String name,
    required String propertyType,
    required int totalFloors,
    int basementFloors = 0,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO buildings (name, property_type, total_floors, basement_floors, gfa, nla, address, built_year)
        VALUES (@name, @propertyType::property_type, @totalFloors, @basementFloors, @gfa, @nla, @address, @builtYear)
        RETURNING id::TEXT, name, property_type::TEXT, total_floors, basement_floors,
                  gfa, nla, address, built_year, created_at, updated_at
      '''),
      parameters: {
        'name': name,
        'propertyType': propertyType,
        'totalFloors': totalFloors,
        'basementFloors': basementFloors,
        'gfa': gfa,
        'nla': nla,
        'address': address,
        'builtYear': builtYear,
      },
    );
    return Building.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新楼栋（仅更新非 null 字段），返回更新后的记录。
  /// [basementFloors] 传 null 时保留原值；传具体数值时直接写入。
  Future<Building?> update(
    String id, {
    String? name,
    String? propertyType,
    int? totalFloors,
    int? basementFloors,
    double? gfa,
    double? nla,
    String? address,
    bool addressSet = false,
    int? builtYear,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE buildings SET
          name            = COALESCE(@name, name),
          property_type   = COALESCE(@propertyType::property_type, property_type),
          total_floors    = COALESCE(@totalFloors, total_floors),
          basement_floors = COALESCE(@basementFloors, basement_floors),
          gfa             = COALESCE(@gfa, gfa),
          nla             = COALESCE(@nla, nla),
          address         = CASE WHEN @addressSet THEN @address ELSE address END,
          built_year      = COALESCE(@builtYear, built_year),
          updated_at      = NOW()
        WHERE id = @id
        RETURNING id::TEXT, name, property_type::TEXT, total_floors, basement_floors,
                  gfa, nla, address, built_year, created_at, updated_at
      '''),
      parameters: {
        'id': id,
        'name': name,
        'propertyType': propertyType,
        'totalFloors': totalFloors,
        'basementFloors': basementFloors,
        'gfa': gfa,
        'nla': nla,
        'address': address,
        'addressSet': addressSet,
        'builtYear': builtYear,
      },
    );
    if (result.isEmpty) return null;
    return Building.fromColumnMap(result.first.toColumnMap());
  }

  /// 删除楼栋（仅删除楼栋本身，调用方应在事务中先删除关联的 floor_plans/floors）。
  /// 返回受影响行数：0 表示不存在，1 表示成功。
  Future<int> delete(String id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM buildings WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows;
  }
}
