/// Building 楼栋数据模型 — 对应 buildings 表（migration 004 + 021）
class Building {
  final String id;
  final String name;
  /// 主业态：'office' | 'retail' | 'apartment'
  final String propertyType;
  final int totalFloors;
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
      gfa: (map['gfa'] as num).toDouble(),
      nla: (map['nla'] as num).toDouble(),
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
        'gfa': gfa,
        'nla': nla,
        'address': address,
        'built_year': builtYear,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
