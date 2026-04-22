/// RenovationRecord 改造记录数据模型 — 对应 renovation_records 表（migration 004 + 021）
/// unit_number 为 JOIN 冗余字段
class RenovationRecord {
  final String id;
  final String unitId;
  /// JOIN units.unit_number
  final String? unitNumber;
  /// 改造类型，如"隔断改造"、"水电改造"、"装修升级"
  final String renovationType;
  /// 改造开始日期（DATE 列，以 DateTime 表示，不含时分秒）
  final DateTime startedAt;
  /// 改造完成日期（可选）
  final DateTime? completedAt;
  /// 施工造价（元）
  final double? cost;
  /// 施工方
  final String? contractor;
  final String? description;
  /// 改造前照片路径列表（renovations/{record_id}/{index}.jpg）
  final List<String> beforePhotoPaths;
  /// 改造后照片路径列表
  final List<String> afterPhotoPaths;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RenovationRecord({
    required this.id,
    required this.unitId,
    this.unitNumber,
    required this.renovationType,
    required this.startedAt,
    this.completedAt,
    this.cost,
    this.contractor,
    this.description,
    required this.beforePhotoPaths,
    required this.afterPhotoPaths,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RenovationRecord.fromColumnMap(Map<String, dynamic> map) {
    // PostgreSQL DATE 列在 Dart postgres 包中以 DateTime 返回（时间部分为 00:00:00 UTC）
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    return RenovationRecord(
      id: map['id'] as String,
      unitId: map['unit_id'] as String,
      unitNumber: map['unit_number'] as String?,
      renovationType: map['renovation_type'] as String,
      startedAt: parseDate(map['started_at']),
      completedAt:
          map['completed_at'] != null ? parseDate(map['completed_at']) : null,
      cost: (map['cost'] as num?)?.toDouble(),
      contractor: map['contractor'] as String?,
      description: map['description'] as String?,
      beforePhotoPaths: (map['before_photo_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      afterPhotoPaths: (map['after_photo_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unit_id': unitId,
        'unit_number': unitNumber,
        'renovation_type': renovationType,
        'started_at': '${startedAt.year.toString().padLeft(4, '0')}'
            '-${startedAt.month.toString().padLeft(2, '0')}'
            '-${startedAt.day.toString().padLeft(2, '0')}',
        'completed_at': completedAt != null
            ? '${completedAt!.year.toString().padLeft(4, '0')}'
                '-${completedAt!.month.toString().padLeft(2, '0')}'
                '-${completedAt!.day.toString().padLeft(2, '0')}'
            : null,
        'cost': cost,
        'contractor': contractor,
        'description': description,
        'before_photo_paths': beforePhotoPaths,
        'after_photo_paths': afterPhotoPaths,
        'created_by': createdBy,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
