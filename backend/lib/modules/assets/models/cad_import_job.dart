/// CadImportJob 数据模型 — 对应 cad_import_jobs 表（migration 026）
///
/// 状态机：uploaded → splitting → done | failed
class CadImportJob {
  final String id;
  final String buildingId;
  /// 任务状态：uploaded / splitting / done / failed
  final String status;
  /// 原始 DXF 相对路径（cad/{buildingId}/{jobId}.dxf）
  final String dxfPath;
  /// 切分输出 SVG 前缀
  final String prefix;
  /// 自动匹配到 floors 的 SVG 数量
  final int matchedCount;
  /// 未匹配 SVG 列表
  final List<UnmatchedSvg> unmatchedSvgs;
  /// 失败原因（status='failed' 时填充）
  final String? errorMessage;
  final String? createdBy;
  /// JOIN users.name
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CadImportJob({
    required this.id,
    required this.buildingId,
    required this.status,
    required this.dxfPath,
    required this.prefix,
    required this.matchedCount,
    required this.unmatchedSvgs,
    this.errorMessage,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CadImportJob.fromColumnMap(Map<String, dynamic> map) {
    final raw = map['unmatched_svgs'];
    final List<dynamic> rawList = raw is List ? raw : <dynamic>[];
    return CadImportJob(
      id: map['id'] as String,
      buildingId: map['building_id'] as String,
      status: map['status'] as String,
      dxfPath: map['dxf_path'] as String,
      prefix: map['prefix'] as String,
      matchedCount: map['matched_count'] as int,
      unmatchedSvgs: rawList
          .map((e) => UnmatchedSvg.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: map['error_message'] as String?,
      createdBy: map['created_by'] as String?,
      createdByName: map['created_by_name'] as String?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'building_id': buildingId,
        'status': status,
        'dxf_path': dxfPath,
        'prefix': prefix,
        'matched_count': matchedCount,
        'unmatched_svgs':
            unmatchedSvgs.map((e) => e.toJson()).toList(growable: false),
        'error_message': errorMessage,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// 未匹配的 SVG 条目
/// label 来自 SVG 文件名（去除前缀），如 "F11" / "F6-F8-F10" / "屋顶"
/// tmpPath 是切分输出后暂存路径（仍在 cad/.../jobs/{jobId}/ 目录下）
class UnmatchedSvg {
  final String label;
  final String tmpPath;

  const UnmatchedSvg({required this.label, required this.tmpPath});

  factory UnmatchedSvg.fromJson(Map<String, dynamic> json) => UnmatchedSvg(
        label: json['label'] as String,
        tmpPath: json['tmp_path'] as String,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'tmp_path': tmpPath,
      };
}
