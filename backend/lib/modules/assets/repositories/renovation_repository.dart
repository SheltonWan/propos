import 'package:postgres/postgres.dart';

import '../../../core/pagination.dart';
import '../models/renovation_record.dart';

/// RenovationRepository — renovation_records 表的 CRUD 操作。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接
///   2. 照片路径由服务层构建，Repository 仅做数组追加
class RenovationRepository {
  final Session _db;

  RenovationRepository(this._db);

  /// 分页查询改造记录，可按 unit_id 过滤（含单元编号）
  Future<PaginatedResult<RenovationRecord>> findAll({
    String? unitId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;

    final countResult = await _db.execute(
      Sql.named('''
        SELECT COUNT(*)::INT AS total
        FROM renovation_records
        WHERE (@unitId::UUID IS NULL OR unit_id = @unitId::UUID)
      '''),
      parameters: {'unitId': unitId},
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final dataResult = await _db.execute(
      Sql.named('''
        SELECT r.id::TEXT, r.unit_id::TEXT,
               u.unit_number,
               r.renovation_type,
               r.started_at, r.completed_at,
               r.cost, r.contractor, r.description,
               r.before_photo_paths, r.after_photo_paths,
               r.created_by::TEXT,
               r.created_at, r.updated_at
        FROM renovation_records r
        JOIN units u ON u.id = r.unit_id
        WHERE (@unitId::UUID IS NULL OR r.unit_id = @unitId::UUID)
        ORDER BY r.created_at DESC
        LIMIT @pageSize OFFSET @offset
      '''),
      parameters: {
        'unitId': unitId,
        'pageSize': pageSize,
        'offset': offset,
      },
    );

    final items = dataResult
        .map((r) => RenovationRecord.fromColumnMap(r.toColumnMap()))
        .toList();
    return PaginatedResult(
      items: items,
      meta: PaginationMeta(page: page, pageSize: pageSize, total: total),
    );
  }

  /// 根据 ID 查询改造记录（含单元编号）
  Future<RenovationRecord?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT r.id::TEXT, r.unit_id::TEXT,
               u.unit_number,
               r.renovation_type,
               r.started_at, r.completed_at,
               r.cost, r.contractor, r.description,
               r.before_photo_paths, r.after_photo_paths,
               r.created_by::TEXT,
               r.created_at, r.updated_at
        FROM renovation_records r
        JOIN units u ON u.id = r.unit_id
        WHERE r.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return RenovationRecord.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建改造记录，返回新记录
  Future<RenovationRecord> create({
    required String unitId,
    required String renovationType,
    required DateTime startedAt,
    DateTime? completedAt,
    double? cost,
    String? contractor,
    String? description,
    String? createdBy,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        WITH inserted AS (
          INSERT INTO renovation_records (
            unit_id, renovation_type, started_at, completed_at,
            cost, contractor, description, created_by
          )
          VALUES (
            @unitId::UUID, @renovationType, @startedAt::DATE, @completedAt::DATE,
            @cost, @contractor, @description, @createdBy::UUID
          )
          RETURNING *
        )
        SELECT i.id::TEXT, i.unit_id::TEXT,
               u.unit_number,
               i.renovation_type,
               i.started_at, i.completed_at,
               i.cost, i.contractor, i.description,
               i.before_photo_paths, i.after_photo_paths,
               i.created_by::TEXT,
               i.created_at, i.updated_at
        FROM inserted i
        JOIN units u ON u.id = i.unit_id
      '''),
      parameters: {
        'unitId': unitId,
        'renovationType': renovationType,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'cost': cost,
        'contractor': contractor,
        'description': description,
        'createdBy': createdBy,
      },
    );
    return RenovationRecord.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新改造记录（仅 PATCH 允许的字段），返回更新后记录
  Future<RenovationRecord?> update(
    String id, {
    String? renovationType,
    DateTime? startedAt,
    DateTime? completedAt,
    bool completedAtSet = false,
    double? cost,
    String? contractor,
    String? description,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE renovation_records SET
          renovation_type = COALESCE(@renovationType, renovation_type),
          started_at      = COALESCE(@startedAt::DATE, started_at),
          completed_at    = CASE WHEN @completedAtSet THEN @completedAt::DATE ELSE completed_at END,
          cost            = COALESCE(@cost,        cost),
          contractor      = COALESCE(@contractor,  contractor),
          description     = COALESCE(@description, description),
          updated_at      = NOW()
        WHERE id = @id
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'renovationType': renovationType,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'completedAtSet': completedAtSet,
        'cost': cost,
        'contractor': contractor,
        'description': description,
      },
    );
    if (result.isEmpty) return null;
    return findById(id);
  }

  /// 追加照片路径到 before_photo_paths（改造前）或 after_photo_paths（改造后）
  /// 使用 array_append 原子追加，避免并发覆盖；isBefore 由调用层保证合法性
  Future<void> appendBeforePhotoPath(String id, String path) async {
    await _db.execute(
      Sql.named('''
        UPDATE renovation_records
        SET before_photo_paths = array_append(COALESCE(before_photo_paths, '{}'), @path),
            updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'path': path},
    );
  }

  Future<void> appendAfterPhotoPath(String id, String path) async {
    await _db.execute(
      Sql.named('''
        UPDATE renovation_records
        SET after_photo_paths = array_append(COALESCE(after_photo_paths, '{}'), @path),
            updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'path': path},
    );
  }
}
