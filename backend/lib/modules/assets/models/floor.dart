/// PostgreSQL NUMERIC 列可能以 String 形式返回，统一兼容转换
double? _pd(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.parse(v.toString());
}

/// Floor 楼层数据模型 — 对应 floors 表（migration 004 + 021）
/// building_name 为 JOIN 冗余字段，仅在列表/详情查询时填充
class Floor {
  final String id;
  final String buildingId;
  /// JOIN buildings.name，列表查询时填充
  final String? buildingName;
  /// 楼层号（负数=地下层，-1=B1）
  final int floorNumber;
  /// 展示名，如 "B1"、"1F"
  final String? floorName;
  /// 当前生效 SVG 路径（floors/{building_id}/{floor_id}.svg）
  final String? svgPath;
  /// 当前生效 PNG 路径（备用）
  final String? pngPath;
  /// 本层净可租面积（m²）
  final double? nla;
  /// 渲染模式：'vector'（默认、SVG 原图）或 'semantic'（按 floor_maps 语义渲染）
  final String renderMode;
  /// floor_maps 最近一次保存使用的 schema 版本号
  final String? floorMapSchemaVersion;
  /// floor_maps 最近一次保存时间，前端作为 ETag/If-Match 乐观锁版本号
  final DateTime? floorMapUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Floor({
    required this.id,
    required this.buildingId,
    this.buildingName,
    required this.floorNumber,
    this.floorName,
    this.svgPath,
    this.pngPath,
    this.nla,
    this.renderMode = 'vector',
    this.floorMapSchemaVersion,
    this.floorMapUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Floor.fromColumnMap(Map<String, dynamic> map) {
    return Floor(
      id: map['id'] as String,
      buildingId: map['building_id'] as String,
      buildingName: map['building_name'] as String?,
      floorNumber: map['floor_number'] as int,
      floorName: map['floor_name'] as String?,
      svgPath: map['svg_path'] as String?,
      pngPath: map['png_path'] as String?,
      nla: _pd(map['nla']),
      renderMode: (map['render_mode'] as String?) ?? 'vector',
      floorMapSchemaVersion: map['floor_map_schema_version'] as String?,
      floorMapUpdatedAt: map['floor_map_updated_at'] as DateTime?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'building_id': buildingId,
        'building_name': buildingName,
        'floor_number': floorNumber,
        'floor_name': floorName,
        'svg_path': svgPath,
        'png_path': pngPath,
        'nla': nla,
        'render_mode': renderMode,
        'floor_map_schema_version': floorMapSchemaVersion,
        'floor_map_updated_at': floorMapUpdatedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// FloorHeatmap 楼层热区数据 — 用于 GET /api/floors/:id/heatmap 响应
class FloorHeatmap {
  final String floorId;
  final String? svgPath;
  final List<HeatmapUnit> units;

  const FloorHeatmap({
    required this.floorId,
    this.svgPath,
    required this.units,
  });

  Map<String, dynamic> toJson() => {
        'floor_id': floorId,
        'svg_path': svgPath,
        'units': units.map((u) => u.toJson()).toList(),
      };
}

/// HeatmapUnit 单个单元在热区中的状态快照
class HeatmapUnit {
  final String unitId;
  final String unitNumber;
  final String currentStatus;
  final String propertyType;
  final String? tenantName;
  final String? contractEndDate;

  const HeatmapUnit({
    required this.unitId,
    required this.unitNumber,
    required this.currentStatus,
    required this.propertyType,
    this.tenantName,
    this.contractEndDate,
  });

  factory HeatmapUnit.fromColumnMap(Map<String, dynamic> map) {
    final endDate = map['contract_end_date'];
    String? endDateStr;
    if (endDate is DateTime) {
      endDateStr = '${endDate.year.toString().padLeft(4, '0')}'
          '-${endDate.month.toString().padLeft(2, '0')}'
          '-${endDate.day.toString().padLeft(2, '0')}';
    } else if (endDate is String) {
      endDateStr = endDate;
    }
    return HeatmapUnit(
      unitId: map['unit_id'] as String,
      unitNumber: map['unit_number'] as String,
      currentStatus: map['current_status'] as String,
      propertyType: map['property_type'] as String,
      tenantName: map['tenant_name'] as String?,
      contractEndDate: endDateStr,
    );
  }

  Map<String, dynamic> toJson() => {
        'unit_id': unitId,
        'unit_number': unitNumber,
        'current_status': currentStatus,
        'property_type': propertyType,
        'tenant_name': tenantName,
        'contract_end_date': contractEndDate,
      };
}
