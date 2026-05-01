import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/floor_map.dart';

/// FloorMapRepository — floor_maps 表（migration 027）的 CRUD 操作。
///
/// 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接。
/// JSONB 字段通过 jsonEncode 序列化为字符串后写入。
class FloorMapRepository {
  final Session _db;

  FloorMapRepository(this._db);

  /// 读取已审核的楼层结构（PUT 保存后的数据）。不存在返回 null。
  Future<FloorMap?> findByFloorId(String floorId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT floor_id::TEXT, schema_version,
               viewport, outline, structures, windows, north,
               candidates, candidates_extracted_at,
               updated_at, updated_by::TEXT
        FROM floor_maps
        WHERE floor_id = @floorId
        LIMIT 1
      '''),
      parameters: {'floorId': floorId},
    );
    if (result.isEmpty) return null;
    return FloorMap.fromColumnMap(result.first.toColumnMap());
  }

  /// 仅读取候选项（DXF 抽取写入的 candidates 列）。
  /// 行不存在或 candidates 为 NULL 时返回 null。
  Future<Map<String, dynamic>?> findCandidates(String floorId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT candidates
        FROM floor_maps
        WHERE floor_id = @floorId
        LIMIT 1
      '''),
      parameters: {'floorId': floorId},
    );
    if (result.isEmpty) return null;
    final raw = result.first.toColumnMap()['candidates'];
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// 覆盖写入 viewport / outline / structures / windows / north。
  /// updated_at 由 NOW() 推进，作为乐观锁版本号；返回完整 FloorMap。
  Future<FloorMap> upsert({
    required String floorId,
    required String schemaVersion,
    required Map<String, dynamic>? viewport,
    required Map<String, dynamic>? outline,
    required List<Map<String, dynamic>> structures,
    required List<Map<String, dynamic>> windows,
    required Map<String, dynamic>? north,
    required String updatedBy,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO floor_maps (
          floor_id, schema_version, viewport, outline,
          structures, windows, north,
          updated_at, updated_by
        )
        VALUES (
          @floorId::UUID, @schemaVersion,
          @viewport::JSONB, @outline::JSONB,
          @structures::JSONB, @windows::JSONB, @north::JSONB,
          NOW(), @updatedBy::UUID
        )
        ON CONFLICT (floor_id) DO UPDATE SET
          schema_version = EXCLUDED.schema_version,
          viewport       = EXCLUDED.viewport,
          outline        = EXCLUDED.outline,
          structures     = EXCLUDED.structures,
          windows        = EXCLUDED.windows,
          north          = EXCLUDED.north,
          updated_at     = NOW(),
          updated_by     = EXCLUDED.updated_by
        RETURNING floor_id::TEXT, schema_version,
                  viewport, outline, structures, windows, north,
                  candidates, candidates_extracted_at,
                  updated_at, updated_by::TEXT
      '''),
      parameters: {
        'floorId': floorId,
        'schemaVersion': schemaVersion,
        'viewport': viewport == null ? null : jsonEncode(viewport),
        'outline': outline == null ? null : jsonEncode(outline),
        'structures': jsonEncode(structures),
        'windows': jsonEncode(windows),
        'north': north == null ? null : jsonEncode(north),
        'updatedBy': updatedBy,
      },
    );
    return FloorMap.fromColumnMap(result.first.toColumnMap());
  }

  /// 写入 / 更新候选结构（由 Python 抽取流水线调用，DB 直写场景）。
  /// 同时刷新 candidates_extracted_at；不修改人工保存的 structures。
  Future<void> upsertCandidates(
    String floorId,
    Map<String, dynamic> candidates,
  ) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO floor_maps (floor_id, candidates, candidates_extracted_at, updated_at)
        VALUES (@floorId::UUID, @candidates::JSONB, NOW(), NOW())
        ON CONFLICT (floor_id) DO UPDATE SET
          candidates              = EXCLUDED.candidates,
          candidates_extracted_at = NOW()
      '''),
      parameters: {
        'floorId': floorId,
        'candidates': jsonEncode(candidates),
      },
    );
  }
}
