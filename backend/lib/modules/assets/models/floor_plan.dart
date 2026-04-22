/// FloorPlan 楼层图纸版本数据模型 — 对应 floor_plans 表（migration 004 + 021）
/// uploaded_by_name 为 JOIN 冗余字段
class FloorPlan {
  final String id;
  final String floorId;
  /// 版本标签，如"原始图纸"、"2026年改造后"
  final String versionLabel;
  /// SVG 文件路径（floors/{building_id}/{floor_id}_v{n}.svg）
  final String svgPath;
  /// PNG 备用路径（可选）
  final String? pngPath;
  /// 是否为当前生效版本
  final bool isCurrent;
  final String? uploadedBy;
  /// JOIN users.name
  final String? uploadedByName;
  final DateTime createdAt;

  const FloorPlan({
    required this.id,
    required this.floorId,
    required this.versionLabel,
    required this.svgPath,
    this.pngPath,
    required this.isCurrent,
    this.uploadedBy,
    this.uploadedByName,
    required this.createdAt,
  });

  factory FloorPlan.fromColumnMap(Map<String, dynamic> map) {
    return FloorPlan(
      id: map['id'] as String,
      floorId: map['floor_id'] as String,
      versionLabel: map['version_label'] as String,
      svgPath: map['svg_path'] as String,
      pngPath: map['png_path'] as String?,
      isCurrent: map['is_current'] as bool,
      uploadedBy: map['uploaded_by'] as String?,
      uploadedByName: map['uploaded_by_name'] as String?,
      createdAt: map['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'floor_id': floorId,
        'version_label': versionLabel,
        'svg_path': svgPath,
        'png_path': pngPath,
        'is_current': isCurrent,
        'uploaded_by': uploadedBy,
        'uploaded_by_name': uploadedByName,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
