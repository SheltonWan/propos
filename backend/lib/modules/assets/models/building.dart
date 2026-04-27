/// PostgreSQL NUMERIC 列可能以 String 形式返回，统一兼容转换
double? _pd(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.parse(v.toString());
}

/// Building 楼栋数据模型 — 对应 buildings 表（migration 004 + 021 + 025）
class Building {
  final String id;
  final String name;
  /// 标签业态：'office' | 'retail' | 'apartment' | 'mixed'（综合体）
  final String propertyType;
  /// 地上楼层总数（1F ~ NF）
  final int totalFloors;
  /// 地下楼层总数（B1 ~ BN），对应 floor_number < 0 的楼层行数
  final int basementFloors;
  /// 总建筑面积（m²）
  final double gfa;
  /// 净可租面积（m²）
  final double nla;
  final String? address;
  final int? builtYear;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Building({
    required this.id,
    required this.name,
    required this.propertyType,
    required this.totalFloors,
    this.basementFloors = 0,
    required this.gfa,
    required this.nla,
    this.address,
    this.builtYear,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Building.fromColumnMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'] as String,
      name: map['name'] as String,
      propertyType: map['property_type'] as String,
      totalFloors: map['total_floors'] as int,
      basementFloors: (map['basement_floors'] as int?) ?? 0,
      gfa: _pd(map['gfa'])!,
      nla: _pd(map['nla'])!,
      address: map['address'] as String?,
      builtYear: map['built_year'] as int?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'property_type': propertyType,
        'total_floors': totalFloors,
        'basement_floors': basementFloors,
        'gfa': gfa,
        'nla': nla,
        'address': address,
        'built_year': builtYear,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
