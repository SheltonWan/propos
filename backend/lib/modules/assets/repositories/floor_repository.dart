import 'package:postgres/postgres.dart';

import '../models/floor.dart';
import '../models/floor_plan.dart';

/// FloorRepository — floors 表 + floor_plans 表的 CRUD 操作。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接
///   2. floor_plans 的 is_current 唯一索引保证同楼层只有一条生效版本
class FloorRepository {
  final Session _db;

  FloorRepository(this._db);

  // ─── floors ─────────────────────────────────────────────────────────────

  /// 查询楼层列表，可按 building_id 过滤，按楼层号升序
  Future<List<Floor>> findAll({String? buildingId}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT f.id::TEXT, f.building_id::TEXT,
               b.name AS building_name,
               f.floor_number, f.floor_name,
               f.svg_path, f.png_path, f.nla,
               f.render_mode, f.floor_map_schema_version, f.floor_map_updated_at,
               f.created_at, f.updated_at
        FROM floors f
        JOIN buildings b ON b.id = f.building_id
        WHERE (@buildingId::UUID IS NULL OR f.building_id = @buildingId::UUID)
        ORDER BY f.building_id, f.floor_number
      '''),
      parameters: {'buildingId': buildingId},
    );
    return result.map((r) => Floor.fromColumnMap(r.toColumnMap())).toList();
  }

  /// 根据 ID 查询楼层（含楼栋名），不存在返回 null
  Future<Floor?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT f.id::TEXT, f.building_id::TEXT,
               b.name AS building_name,
               f.floor_number, f.floor_name,
               f.svg_path, f.png_path, f.nla,
               f.render_mode, f.floor_map_schema_version, f.floor_map_updated_at,
               f.created_at, f.updated_at
        FROM floors f
        JOIN buildings b ON b.id = f.building_id
        WHERE f.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Floor.fromColumnMap(result.first.toColumnMap());
  }

  /// 检查楼层是否存在（按 building_id + floor_number 去重）
  Future<bool> existsByBuildingAndNumber(
      String buildingId, int floorNumber) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT 1 FROM floors
        WHERE building_id = @buildingId AND floor_number = @floorNumber
        LIMIT 1
      '''),
      parameters: {'buildingId': buildingId, 'floorNumber': floorNumber},
    );
    return result.isNotEmpty;
  }

  /// 创建楼层，返回新记录（含楼栋名）
  Future<Floor> create({
    required String buildingId,
    required int floorNumber,
    String? floorName,
    double? nla,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        WITH inserted AS (
          INSERT INTO floors (building_id, floor_number, floor_name, nla)
          VALUES (@buildingId::UUID, @floorNumber, @floorName, @nla)
          RETURNING *
        )
        SELECT i.id::TEXT, i.building_id::TEXT,
               b.name AS building_name,
               i.floor_number, i.floor_name,
               i.svg_path, i.png_path, i.nla,
               i.render_mode, i.floor_map_schema_version, i.floor_map_updated_at,
               i.created_at, i.updated_at
        FROM inserted i
        JOIN buildings b ON b.id = i.building_id
      '''),
      parameters: {
        'buildingId': buildingId,
        'floorNumber': floorNumber,
        'floorName': floorName,
        'nla': nla,
      },
    );
    return Floor.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新楼层的 svg_path / png_path（CAD 转换完成后调用）
  Future<void> updatePaths(
      String id, {required String? svgPath, String? pngPath}) async {
    await _db.execute(
      Sql.named('''
        UPDATE floors SET
          svg_path   = @svgPath,
          png_path   = @pngPath,
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'svgPath': svgPath, 'pngPath': pngPath},
    );
  }

  /// 切换楼层渲染模式（vector / semantic）。
  /// 同时推进 floor_map_updated_at，作为乐观锁版本号。
  Future<void> updateRenderMode(String floorId, String renderMode) async {
    await _db.execute(
      Sql.named('''
        UPDATE floors SET
          render_mode          = @renderMode,
          floor_map_updated_at = NOW(),
          updated_at           = NOW()
        WHERE id = @floorId
      '''),
      parameters: {'floorId': floorId, 'renderMode': renderMode},
    );
  }

  /// 仅推进楼层的 floor_map 版本号与 schema 版本（保存 structures 后同步调用）。
  /// 返回调整后的 floor_map_updated_at，用于作为 ETag 返回。
  Future<DateTime> bumpFloorMapVersion(
    String floorId, {
    String schemaVersion = '2.0',
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE floors SET
          floor_map_schema_version = @schemaVersion,
          floor_map_updated_at     = NOW(),
          updated_at               = NOW()
        WHERE id = @floorId
        RETURNING floor_map_updated_at
      '''),
      parameters: {'floorId': floorId, 'schemaVersion': schemaVersion},
    );
    return result.first.toColumnMap()['floor_map_updated_at'] as DateTime;
  }

  /// 读取楼层的当前 floor_map_updated_at（用于乐观锁比对）。
  /// 楼层不存在时返回 null。
  Future<DateTime?> findFloorMapVersion(String floorId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT floor_map_updated_at FROM floors
        WHERE id = @floorId
        LIMIT 1
      '''),
      parameters: {'floorId': floorId},
    );
    if (result.isEmpty) return null;
    return result.first.toColumnMap()['floor_map_updated_at'] as DateTime?;
  }

  // ─── 热区查询（跨合同/租客数据，仅读取 units 及当前合同快照）────────────

  /// 获取楼层热区数据：楼层基本信息 + 所有单元状态快照
  Future<FloorHeatmap?> getHeatmap(String floorId) async {
    // 先查楼层是否存在
    final floorResult = await _db.execute(
      Sql.named('''
        SELECT id::TEXT AS floor_id, svg_path
        FROM floors
        WHERE id = @floorId
        LIMIT 1
      '''),
      parameters: {'floorId': floorId},
    );
    if (floorResult.isEmpty) return null;

    final floorMap = floorResult.first.toColumnMap();
    final svgPath = floorMap['svg_path'] as String?;

    // 查询该楼层所有单元及其当前合同/租客快照
    final unitResult = await _db.execute(
      Sql.named('''
        SELECT
          u.id::TEXT             AS unit_id,
          u.unit_number,
          u.current_status::TEXT AS current_status,
          u.property_type::TEXT  AS property_type,
          t.name              AS tenant_name,
          c.end_date             AS contract_end_date
        FROM units u
        LEFT JOIN contracts c ON c.id = u.current_contract_id
            AND c.status IN ('active','expiring_soon')
        LEFT JOIN tenants t ON t.id = c.tenant_id
        WHERE u.floor_id = @floorId
          AND u.archived_at IS NULL
        ORDER BY u.unit_number
      '''),
      parameters: {'floorId': floorId},
    );

    final units = unitResult
        .map((r) => HeatmapUnit.fromColumnMap(r.toColumnMap()))
        .toList();

    return FloorHeatmap(
      floorId: floorMap['floor_id'] as String,
      svgPath: svgPath,
      units: units,
    );
  }

  /// 在事务中级联删除楼栋下所有图纸版本和楼层记录。
  ///
  /// 必须在外部事务上下文中调用（通过 `FloorRepository(tx)` 构造）。
  /// 删除顺序：先删 floor_plans（外键约束依赖 floors.id），再删 floors。
  Future<void> deleteByBuildingId(String buildingId) async {
    await _db.execute(
      Sql.named('''
        DELETE FROM floor_plans
        WHERE floor_id IN (
          SELECT id FROM floors WHERE building_id = @buildingId::UUID
        )
      '''),
      parameters: {'buildingId': buildingId},
    );
    await _db.execute(
      Sql.named('DELETE FROM floors WHERE building_id = @buildingId::UUID'),
      parameters: {'buildingId': buildingId},
    );
  }

  // ─── floor_plans ─────────────────────────────────────────────────────────

  /// 列出楼层所有图纸版本（含上传人姓名），按创建时间倒序
  Future<List<FloorPlan>> findPlansByFloor(String floorId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT fp.id::TEXT, fp.floor_id::TEXT,
               fp.version_label, fp.svg_path, fp.png_path,
               fp.is_current,
               fp.uploaded_by::TEXT,
               u.name AS uploaded_by_name,
               fp.created_at
        FROM floor_plans fp
        LEFT JOIN users u ON u.id = fp.uploaded_by
        WHERE fp.floor_id = @floorId
        ORDER BY fp.created_at DESC
      '''),
      parameters: {'floorId': floorId},
    );
    return result.map((r) => FloorPlan.fromColumnMap(r.toColumnMap())).toList();
  }

  /// 根据 plan ID 查询图纸版本
  Future<FloorPlan?> findPlanById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT fp.id::TEXT, fp.floor_id::TEXT,
               fp.version_label, fp.svg_path, fp.png_path,
               fp.is_current,
               fp.uploaded_by::TEXT,
               u.name AS uploaded_by_name,
               fp.created_at
        FROM floor_plans fp
        LEFT JOIN users u ON u.id = fp.uploaded_by
        WHERE fp.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return FloorPlan.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建图纸版本记录（新版本默认不为 current，由调用方控制）
  Future<FloorPlan> createPlan({
    required String floorId,
    required String versionLabel,
    required String svgPath,
    String? pngPath,
    bool isCurrent = false,
    String? uploadedBy,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO floor_plans (floor_id, version_label, svg_path, png_path, is_current, uploaded_by)
        VALUES (@floorId::UUID, @versionLabel, @svgPath, @pngPath, @isCurrent, @uploadedBy::UUID)
        RETURNING id::TEXT, floor_id::TEXT, version_label, svg_path, png_path,
                  is_current, uploaded_by::TEXT, NULL AS uploaded_by_name, created_at
      '''),
      parameters: {
        'floorId': floorId,
        'versionLabel': versionLabel,
        'svgPath': svgPath,
        'pngPath': pngPath,
        'isCurrent': isCurrent,
        'uploadedBy': uploadedBy,
      },
    );
    return FloorPlan.fromColumnMap(result.first.toColumnMap());
  }

  /// 将指定 plan 设为当前生效版本（原子操作：先清空再设置）
  Future<FloorPlan?> setCurrentPlan(String planId) async {
    // 先查出 floor_id，再原子更新
    final planResult = await _db.execute(
      Sql.named('SELECT floor_id::TEXT, svg_path, png_path FROM floor_plans WHERE id = @id LIMIT 1'),
      parameters: {'id': planId},
    );
    if (planResult.isEmpty) return null;

    final map = planResult.first.toColumnMap();
    final floorId = map['floor_id'] as String;
    final svgPath = map['svg_path'] as String;
    final pngPath = map['png_path'] as String?;

    // 清空同楼层其他版本的 is_current
    await _db.execute(
      Sql.named('''
        UPDATE floor_plans SET is_current = FALSE
        WHERE floor_id = @floorId AND id != @id
      '''),
      parameters: {'floorId': floorId, 'id': planId},
    );

    // 设置当前版本
    await _db.execute(
      Sql.named('UPDATE floor_plans SET is_current = TRUE WHERE id = @id'),
      parameters: {'id': planId},
    );

    // 同步更新 floors 表的快捷路径
    await updatePaths(floorId, svgPath: svgPath, pngPath: pngPath);

    return findPlanById(planId);
  }
}
