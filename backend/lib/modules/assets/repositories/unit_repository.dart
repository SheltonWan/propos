import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../../../core/pagination.dart';
import '../models/unit.dart';

/// UnitRepository — units 表的 CRUD 操作及聚合统计。
///
/// 安全规则：
///   1. 所有 SQL 使用 Sql.named() + 命名参数，禁止字符串拼接
///   2. 列表按楼栋→楼层→单元号固定排序，不接受外部排序参数
///   3. 归档单元默认不在列表中返回（archived_at IS NULL）
class UnitRepository {
  final Session _db;

  UnitRepository(this._db);

  /// 分页查询单元列表（含楼栋/楼层名），支持多维过滤
  Future<PaginatedResult<Unit>> findAll({
    String? buildingId,
    String? floorId,
    String? propertyType,
    String? currentStatus,
    bool? isLeasable,
    bool includeArchived = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final offset = (page - 1) * pageSize;

    final countResult = await _db.execute(
      Sql.named('''
        SELECT COUNT(*) AS total
        FROM units u
        WHERE (@buildingId::UUID   IS NULL OR u.building_id   = @buildingId::UUID)
          AND (@floorId::UUID      IS NULL OR u.floor_id      = @floorId::UUID)
          AND (@propertyType::TEXT IS NULL OR u.property_type::TEXT = @propertyType)
          AND (@currentStatus::TEXT IS NULL OR u.current_status::TEXT = @currentStatus)
          AND (@isLeasable::BOOLEAN IS NULL OR u.is_leasable   = @isLeasable)
          AND (@includeArchived OR u.archived_at IS NULL)
      '''),
      parameters: {
        'buildingId': buildingId,
        'floorId': floorId,
        'propertyType': propertyType,
        'currentStatus': currentStatus,
        'isLeasable': isLeasable,
        'includeArchived': includeArchived,
      },
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final dataResult = await _db.execute(
      Sql.named('''
        SELECT u.id::TEXT, u.building_id::TEXT,
               b.name AS building_name,
               u.floor_id::TEXT, f.floor_name,
               u.unit_number, u.property_type::TEXT,
               u.gross_area, u.net_area, u.orientation, u.ceiling_height,
               u.decoration_status::TEXT, u.current_status::TEXT,
               u.is_leasable, u.ext_fields,
               u.current_contract_id::TEXT, u.qr_code,
               u.market_rent_reference,
               u.predecessor_unit_ids::TEXT[],
               u.archived_at,
               u.created_at, u.updated_at
        FROM units u
        JOIN buildings b ON b.id = u.building_id
        JOIN floors   f ON f.id = u.floor_id
        WHERE (@buildingId::UUID   IS NULL OR u.building_id   = @buildingId::UUID)
          AND (@floorId::UUID      IS NULL OR u.floor_id      = @floorId::UUID)
          AND (@propertyType::TEXT IS NULL OR u.property_type::TEXT = @propertyType)
          AND (@currentStatus::TEXT IS NULL OR u.current_status::TEXT = @currentStatus)
          AND (@isLeasable::BOOLEAN IS NULL OR u.is_leasable   = @isLeasable)
          AND (@includeArchived OR u.archived_at IS NULL)
        ORDER BY u.building_id, f.floor_number, u.unit_number
        LIMIT @pageSize OFFSET @offset
      '''),
      parameters: {
        'buildingId': buildingId,
        'floorId': floorId,
        'propertyType': propertyType,
        'currentStatus': currentStatus,
        'isLeasable': isLeasable,
        'includeArchived': includeArchived,
        'pageSize': pageSize,
        'offset': offset,
      },
    );

    final items = dataResult.map((r) => Unit.fromColumnMap(r.toColumnMap())).toList();
    return PaginatedResult(
      items: items,
      meta: PaginationMeta(page: page, pageSize: pageSize, total: total),
    );
  }

  /// 根据 ID 查询单元详情（含楼栋/楼层名）
  Future<Unit?> findById(String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT u.id::TEXT, u.building_id::TEXT,
               b.name AS building_name,
               u.floor_id::TEXT, f.floor_name,
               u.unit_number, u.property_type::TEXT,
               u.gross_area, u.net_area, u.orientation, u.ceiling_height,
               u.decoration_status::TEXT, u.current_status::TEXT,
               u.is_leasable, u.ext_fields,
               u.current_contract_id::TEXT, u.qr_code,
               u.market_rent_reference,
               u.predecessor_unit_ids::TEXT[],
               u.archived_at,
               u.created_at, u.updated_at
        FROM units u
        JOIN buildings b ON b.id = u.building_id
        JOIN floors   f ON f.id = u.floor_id
        WHERE u.id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Unit.fromColumnMap(result.first.toColumnMap());
  }

  /// 创建单元，返回新记录（含楼栋/楼层名）
  Future<Unit> create({
    required String floorId,
    required String buildingId,
    required String unitNumber,
    required String propertyType,
    double? grossArea,
    double? netArea,
    String? orientation,
    double? ceilingHeight,
    String decorationStatus = 'blank',
    bool isLeasable = true,
    Map<String, dynamic>? extFields,
    double? marketRentReference,
    String? qrCode,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        WITH inserted AS (
          INSERT INTO units (
            floor_id, building_id, unit_number, property_type,
            gross_area, net_area, orientation, ceiling_height,
            decoration_status, is_leasable, ext_fields,
            market_rent_reference, qr_code
          )
          VALUES (
            @floorId::UUID, @buildingId::UUID, @unitNumber,
            @propertyType::property_type,
            @grossArea, @netArea, @orientation, @ceilingHeight,
            @decorationStatus::unit_decoration, @isLeasable,
            @extFields::JSONB,
            @marketRentReference, @qrCode
          )
          RETURNING *
        )
        SELECT i.id::TEXT, i.building_id::TEXT,
               b.name AS building_name,
               i.floor_id::TEXT, f.floor_name,
               i.unit_number, i.property_type::TEXT,
               i.gross_area, i.net_area, i.orientation, i.ceiling_height,
               i.decoration_status::TEXT, i.current_status::TEXT,
               i.is_leasable, i.ext_fields,
               i.current_contract_id::TEXT, i.qr_code,
               i.market_rent_reference,
               i.predecessor_unit_ids::TEXT[],
               i.archived_at,
               i.created_at, i.updated_at
        FROM inserted i
        JOIN buildings b ON b.id = i.building_id
        JOIN floors   f ON f.id = i.floor_id
      '''),
      parameters: {
        'floorId': floorId,
        'buildingId': buildingId,
        'unitNumber': unitNumber,
        'propertyType': propertyType,
        'grossArea': grossArea,
        'netArea': netArea,
        'orientation': orientation,
        'ceilingHeight': ceilingHeight,
        'decorationStatus': decorationStatus,
        'isLeasable': isLeasable,
        'extFields': jsonEncode(extFields ?? {}),
        'marketRentReference': marketRentReference,
        'qrCode': qrCode,
      },
    );
    return Unit.fromColumnMap(result.first.toColumnMap());
  }

  /// 更新单元（仅更新 PATCH 中允许的字段），返回更新后记录
  Future<Unit?> update(
    String id, {
    String? unitNumber,
    double? grossArea,
    double? netArea,
    String? orientation,
    double? ceilingHeight,
    String? decorationStatus,
    bool? isLeasable,
    Map<String, dynamic>? extFields,
    double? marketRentReference,
    List<String>? predecessorUnitIds,
    DateTime? archivedAt,
    bool archivedAtSet = false,
  }) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE units SET
          unit_number           = COALESCE(@unitNumber, unit_number),
          gross_area            = COALESCE(@grossArea, gross_area),
          net_area              = COALESCE(@netArea, net_area),
          orientation           = COALESCE(@orientation, orientation),
          ceiling_height        = COALESCE(@ceilingHeight, ceiling_height),
          decoration_status     = COALESCE(@decorationStatus::unit_decoration, decoration_status),
          is_leasable           = COALESCE(@isLeasable, is_leasable),
          ext_fields            = CASE WHEN @extFieldsSet THEN @extFields::JSONB ELSE ext_fields END,
          market_rent_reference = COALESCE(@marketRentRef, market_rent_reference),
          predecessor_unit_ids  = CASE WHEN @predSet THEN @predIds::UUID[] ELSE predecessor_unit_ids END,
          archived_at           = CASE WHEN @archivedAtSet THEN @archivedAt ELSE archived_at END,
          updated_at            = NOW()
        WHERE id = @id
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'unitNumber': unitNumber,
        'grossArea': grossArea,
        'netArea': netArea,
        'orientation': orientation,
        'ceilingHeight': ceilingHeight,
        'decorationStatus': decorationStatus,
        'isLeasable': isLeasable,
        'extFields': extFields != null ? jsonEncode(extFields) : null,
        'extFieldsSet': extFields != null,
        'marketRentRef': marketRentReference,
        'predIds': predecessorUnitIds,
        'predSet': predecessorUnitIds != null,
        'archivedAt': archivedAt,
        'archivedAtSet': archivedAtSet,
      },
    );
    if (result.isEmpty) return null;
    // 重新查询含 JOIN 字段的完整数据
    return findById(id);
  }

  /// 批量插入单元（导入时使用），返回实际成功插入数量。
  /// 由调用方在事务中调用以保证整批回滚（commit 模式）或仅校验（dry-run）。
  Future<int> bulkCreate(List<Map<String, dynamic>> rows, {Session? tx}) async {
    final db = tx ?? _db;
    var inserted = 0;
    for (final row in rows) {
      final extFields = row['ext_fields'];
      final extFieldsJson =
          extFields != null ? jsonEncode(extFields) : jsonEncode({});
      final result = await db.execute(
        Sql.named('''
          INSERT INTO units (
            floor_id, building_id, unit_number, property_type,
            gross_area, net_area, orientation, ceiling_height,
            decoration_status, is_leasable,
            market_rent_reference, ext_fields
          )
          VALUES (
            @floorId::UUID, @buildingId::UUID, @unitNumber,
            @propertyType::property_type,
            @grossArea, @netArea, @orientation, @ceilingHeight,
            @decorationStatus::unit_decoration, @isLeasable,
            @marketRentReference, @extFields::JSONB
          )
          ON CONFLICT (building_id, unit_number) DO NOTHING
        '''),
        parameters: {
          'floorId': row['floor_id'],
          'buildingId': row['building_id'],
          'unitNumber': row['unit_number'],
          'propertyType': row['property_type'],
          'grossArea': row['gross_area'],
          'netArea': row['net_area'],
          'orientation': row['orientation'],
          'ceilingHeight': row['ceiling_height'],
          'decorationStatus': row['decoration_status'] ?? 'blank',
          'isLeasable': row['is_leasable'] ?? true,
          'marketRentReference': row['market_rent_reference'],
          'extFields': extFieldsJson,
        },
      );
      inserted += result.affectedRows;
    }
    return inserted;
  }

  /// 查询所有单元用于导出（可按业态过滤，含楼栋/楼层名）
  Future<List<Unit>> findAllForExport({String? propertyType}) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT u.id::TEXT, u.building_id::TEXT,
               b.name AS building_name,
               u.floor_id::TEXT, f.floor_name,
               u.unit_number, u.property_type::TEXT,
               u.gross_area, u.net_area, u.orientation, u.ceiling_height,
               u.decoration_status::TEXT, u.current_status::TEXT,
               u.is_leasable, u.ext_fields,
               u.current_contract_id::TEXT, u.qr_code,
               u.market_rent_reference,
               u.predecessor_unit_ids::TEXT[],
               u.archived_at,
               u.created_at, u.updated_at
        FROM units u
        JOIN buildings b ON b.id = u.building_id
        JOIN floors    f ON f.id = u.floor_id
        WHERE (@propertyType::TEXT IS NULL OR u.property_type::TEXT = @propertyType)
        ORDER BY b.name, f.floor_number, u.unit_number
      '''),
      parameters: {'propertyType': propertyType},
    );
    return result.map((r) => Unit.fromColumnMap(r.toColumnMap())).toList();
  }

  /// 聚合统计：按业态分组统计套数 + NLA 面积（已归档单元不计入）
  ///
  /// 输出字段（与 PropertyTypeStats.fromColumnMap 对齐）：
  ///   property_type, total_units, leased_units, vacant_units,
  ///   expiring_soon_units, total_nla, leased_nla
  ///
  /// 占用判定：current_status IN ('leased','expiring_soon') 视为「已被占用」。
  /// total_nla 仅统计 is_leasable=true 的单元，避免大堂/机房等公共空间污染。
  Future<List<PropertyTypeStats>> getOverviewStats() async {
    final result = await _db.execute(
      Sql.named('''
        SELECT
          property_type::TEXT AS property_type,
          COUNT(*)::INT                                                                AS total_units,
          COUNT(*) FILTER (WHERE current_status = 'leased')::INT                       AS leased_units,
          COUNT(*) FILTER (WHERE current_status = 'vacant')::INT                       AS vacant_units,
          COUNT(*) FILTER (WHERE current_status = 'expiring_soon')::INT                AS expiring_soon_units,
          COALESCE(
            SUM(net_area) FILTER (WHERE is_leasable),
            0
          )::FLOAT8                                                                    AS total_nla,
          COALESCE(
            SUM(net_area) FILTER (WHERE current_status IN ('leased','expiring_soon')),
            0
          )::FLOAT8                                                                    AS leased_nla
        FROM units
        WHERE archived_at IS NULL
        GROUP BY property_type
        ORDER BY property_type
      '''),
    );
    return result
        .map((r) => PropertyTypeStats.fromColumnMap(r.toColumnMap()))
        .toList();
  }

  /// 计算 WALE（加权平均剩余租期，单位：年），仅纳入 active / expiring_soon 合同
  ///
  /// 公式：
  ///   wale_income = Σ(remaining_years × annual_rent) / Σ(annual_rent)
  ///   wale_area   = Σ(remaining_years × leased_area) / Σ(leased_area)
  ///
  /// annual_rent ≈ contracts.base_monthly_rent × 12
  /// leased_area = 合同下所有 contract_units.billing_area_snapshot 之和
  /// 当无在租合同时返回 (0, 0)。
  Future<WaleStats> getWaleStats() async {
    final result = await _db.execute(
      Sql.named('''
        WITH active_contracts AS (
          SELECT
            c.id,
            (c.base_monthly_rent * 12)::FLOAT8 AS annual_rent,
            GREATEST((c.end_date - CURRENT_DATE), 0)::FLOAT8 / 365.0 AS remaining_years,
            COALESCE(
              (SELECT SUM(cu.billing_area_snapshot)
               FROM contract_units cu
               WHERE cu.contract_id = c.id),
              0
            )::FLOAT8 AS leased_area
          FROM contracts c
          WHERE c.status IN ('active', 'expiring_soon')
        )
        SELECT
          COALESCE(
            SUM(remaining_years * annual_rent) / NULLIF(SUM(annual_rent), 0),
            0
          )::FLOAT8 AS wale_income_weighted,
          COALESCE(
            SUM(remaining_years * leased_area) / NULLIF(SUM(leased_area), 0),
            0
          )::FLOAT8 AS wale_area_weighted
        FROM active_contracts
      '''),
    );
    if (result.isEmpty) return WaleStats.empty;
    final row = result.first.toColumnMap();
    return WaleStats(
      incomeWeighted: (row['wale_income_weighted'] as num?)?.toDouble() ?? 0.0,
      areaWeighted: (row['wale_area_weighted'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 查询指定楼栋中已存在的 unit_number 集合（仅含未归档记录）。
  ///
  /// 用于 DXF 导入时的去重校验：调用方将候选列表传入，返回集合的差集即为需要新建的房间。
  /// 使用 `ANY(@candidates)` 参数化，候选列表可为空（返回空集，不发送 SQL）。
  Future<Set<String>> findExistingUnitNumbers(
    String buildingId,
    List<String> candidates,
  ) async {
    if (candidates.isEmpty) return const {};
    final result = await _db.execute(
      Sql.named('''
        SELECT unit_number
        FROM units
        WHERE building_id = @buildingId::UUID
          AND unit_number = ANY(@candidates)
          AND archived_at IS NULL
      '''),
      parameters: {
        'buildingId': buildingId,
        'candidates': candidates,
      },
    );
    return result.map((r) => r.toColumnMap()['unit_number'] as String).toSet();
  }

  /// 仅当 gross_area 当前为 NULL 时才更新，避免覆盖手动修正值。
  ///
  /// 用于 CAD 重新导入场景：首次导入面积缺失，后续 DXF 补充了标注后
  /// 重新导入可自动回填，同时保护已有非空面积不被意外改写。
  ///
  /// 返回实际更新条数（0 或 1）。
  Future<int> updateGrossAreaIfNull(
    String buildingId,
    String unitNumber,
    double grossArea,
  ) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE units
        SET gross_area = @grossArea,
            updated_at = NOW()
        WHERE building_id = @buildingId::UUID
          AND unit_number = @unitNumber
          AND gross_area IS NULL
          AND archived_at IS NULL
        RETURNING id
      '''),
      parameters: {
        'buildingId': buildingId,
        'unitNumber': unitNumber,
        'grossArea': grossArea,
      },
    );
    return result.length;
  }

  /// 统计可租单元总数：is_leasable=true 且未归档
  ///
  /// 用作 `getOverview` 中分母 `totalLeasableUnits` 的权威口径。
  /// 不能用 byType 累加的 `leased+vacant+expiring_soon` 推导，
  /// 否则当存在缺口业态或异常状态时会偏小，导致 occupancy 失真。
  Future<int> countLeasableUnits() async {
    final result = await _db.execute(
      Sql.named('''
        SELECT COUNT(*)::BIGINT AS cnt
        FROM units
        WHERE is_leasable = TRUE
          AND archived_at IS NULL
      '''),
    );
    if (result.isEmpty) return 0;
    final row = result.first.toColumnMap();
    return (row['cnt'] as num?)?.toInt() ?? 0;
  }
}
