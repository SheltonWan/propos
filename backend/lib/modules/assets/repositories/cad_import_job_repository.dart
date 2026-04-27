import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/cad_import_job.dart';

/// CadImportJobRepository — cad_import_jobs 表的 CRUD。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接
///   2. unmatched_svgs 以 JSONB 存储，写入时序列化为 JSON 字符串
class CadImportJobRepository {
  final Session _db;

  CadImportJobRepository(this._db);

  /// 创建任务（status 默认 'uploaded'）
  Future<CadImportJob> create({
    required String buildingId,
    required String dxfPath,
    required String prefix,
    String? createdBy,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        WITH inserted AS (
          INSERT INTO cad_import_jobs (building_id, dxf_path, prefix, created_by)
          VALUES (@buildingId::UUID, @dxfPath, @prefix, @createdBy::UUID)
          RETURNING *
        )
        SELECT i.id::TEXT, i.building_id::TEXT, i.status,
               i.dxf_path, i.prefix, i.matched_count, i.unmatched_svgs,
               i.error_message, i.created_by::TEXT, u.name AS created_by_name,
               i.created_at, i.updated_at
        FROM inserted i
        LEFT JOIN users u ON u.id = i.created_by
      '''),
      parameters: {
        'buildingId': buildingId,
        'dxfPath': dxfPath,
        'prefix': prefix,
        'createdBy': createdBy,
      },
    );
    return CadImportJob.fromColumnMap(result.first.toColumnMap());
  }

  /// 根据 ID 查询任务（含上传人姓名），不存在返回 null
  Future<CadImportJob?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT j.id::TEXT, j.building_id::TEXT, j.status,
               j.dxf_path, j.prefix, j.matched_count, j.unmatched_svgs,
               j.error_message, j.created_by::TEXT, u.name AS created_by_name,
               j.created_at, j.updated_at
        FROM cad_import_jobs j
        LEFT JOIN users u ON u.id = j.created_by
        WHERE j.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return CadImportJob.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新状态（不修改 unmatched_svgs / matched_count / error_message）
  Future<void> updateStatus(String id, String status) async {
    await _db.execute(
      Sql.named('''
        UPDATE cad_import_jobs SET
          status     = @status,
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'status': status},
    );
  }

  /// 切分完成后写入结果（done / failed 时调用）
  Future<void> updateResult(
    String id, {
    required String status,
    required int matchedCount,
    required List<UnmatchedSvg> unmatchedSvgs,
    String? errorMessage,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE cad_import_jobs SET
          status         = @status,
          matched_count  = @matchedCount,
          unmatched_svgs = @unmatchedSvgs::jsonb,
          error_message  = @errorMessage,
          updated_at     = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'status': status,
        'matchedCount': matchedCount,
        'unmatchedSvgs':
            jsonEncode(unmatchedSvgs.map((e) => e.toJson()).toList()),
        'errorMessage': errorMessage,
      },
    );
  }

  /// 仅更新 unmatched_svgs 与 matched_count（管理员手动指派后调用）
  Future<void> updateAssignments(
    String id, {
    required int matchedCount,
    required List<UnmatchedSvg> unmatchedSvgs,
  }) async {
    await _db.execute(
      Sql.named('''
        UPDATE cad_import_jobs SET
          matched_count  = @matchedCount,
          unmatched_svgs = @unmatchedSvgs::jsonb,
          updated_at     = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'matchedCount': matchedCount,
        'unmatchedSvgs':
            jsonEncode(unmatchedSvgs.map((e) => e.toJson()).toList()),
      },
    );
  }
}
