/// FloorMap 楼层结构数据模型 — 对应 floor_maps 表（migration 027）
///
/// 与 [Floor] 1:1 关联，存储 DXF 抽取的候选结构（candidates）以及
/// 人工审核确认后的结构（structures/outline/windows/north）。
///
/// 关联规范：
/// - docs/backend/FLOOR_MAP_API_SPEC.md
/// - docs/backend/schemas/floor_map.v2.schema.json
class FloorMap {
  final String floorId;
  /// 当前固定 '2.0'，与 floor_map.v2.schema.json 对齐
  final String schemaVersion;
  /// 视口尺寸 { width, height }
  final Map<String, dynamic>? viewport;
  /// 外轮廓 { type: 'rect'|'polygon', rect?, points? }
  final Map<String, dynamic>? outline;
  /// 已审核结构数组（StructureOrColumn 联合类型）
  final List<Map<String, dynamic>> structures;
  /// 窗洞数组 [{ side, offset, width }]
  final List<Map<String, dynamic>> windows;
  /// 指北针 { x, y, rotation_deg? }
  final Map<String, dynamic>? north;
  /// DXF 自动抽取的候选结构（仅 source='auto'），前端只读
  final Map<String, dynamic>? candidates;
  /// 候选项最近一次抽取时间
  final DateTime? candidatesExtractedAt;
  /// 最近一次人工保存时间，作为乐观锁版本号
  final DateTime updatedAt;
  /// 最近一次保存的操作人 user_id
  final String? updatedBy;

  const FloorMap({
    required this.floorId,
    this.schemaVersion = '2.0',
    this.viewport,
    this.outline,
    this.structures = const [],
    this.windows = const [],
    this.north,
    this.candidates,
    this.candidatesExtractedAt,
    required this.updatedAt,
    this.updatedBy,
  });

  factory FloorMap.fromColumnMap(Map<String, dynamic> map) {
    return FloorMap(
      floorId: map['floor_id'] as String,
      schemaVersion: (map['schema_version'] as String?) ?? '2.0',
      viewport: _asMap(map['viewport']),
      outline: _asMap(map['outline']),
      structures: _asListOfMap(map['structures']),
      windows: _asListOfMap(map['windows']),
      north: _asMap(map['north']),
      candidates: _asMap(map['candidates']),
      candidatesExtractedAt: map['candidates_extracted_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime,
      updatedBy: map['updated_by'] as String?,
    );
  }

  /// 转换为 API 响应 body（floor_map.v2.schema 兼容）
  ///
  /// 注意：版本号 [updatedAt] 不写入 body，由 Controller 通过 HTTP `ETag`
  /// 响应头返回（schema 顶层 `additionalProperties: false`）。
  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'viewport': viewport,
        'outline': outline,
        'structures': structures,
        'windows': windows,
        'north': north,
      };
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

List<Map<String, dynamic>> _asListOfMap(dynamic v) {
  if (v == null) return const [];
  if (v is List) {
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
  return const [];
}
