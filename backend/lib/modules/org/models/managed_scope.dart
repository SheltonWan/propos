/// 管辖范围数据模型（user_managed_scopes 表）
library;

/// 管辖范围记录（部门默认或个人覆盖）。
class ManagedScope {
  final String id;
  final String? departmentId;
  final String? userId;
  final String? buildingId;
  final String? buildingName;
  final String? floorId;
  final String? floorName;
  final String? propertyType;

  const ManagedScope({
    required this.id,
    this.departmentId,
    this.userId,
    this.buildingId,
    this.buildingName,
    this.floorId,
    this.floorName,
    this.propertyType,
  });

  factory ManagedScope.fromColumnMap(Map<String, dynamic> m) {
    return ManagedScope(
      id: m['id'] as String,
      departmentId: m['department_id'] as String?,
      userId: m['user_id'] as String?,
      buildingId: m['building_id'] as String?,
      buildingName: m['building_name'] as String?,
      floorId: m['floor_id'] as String?,
      floorName: m['floor_name'] as String?,
      propertyType: m['property_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'department_id': departmentId,
        'user_id': userId,
        'building_id': buildingId,
        'building_name': buildingName,
        'floor_id': floorId,
        'floor_name': floorName,
        'property_type': propertyType,
      };
}
