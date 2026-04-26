/// 组织架构（部门）数据模型
library;

/// 部门节点（含可选 children 形成树）。
class Department {
  final String id;
  final String name;
  final String? parentId;
  final int level;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Department> children;

  const Department({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
  });

  factory Department.fromColumnMap(Map<String, dynamic> m) {
    return Department(
      id: m['id'] as String,
      name: m['name'] as String,
      parentId: m['parent_id'] as String?,
      level: (m['level'] as num).toInt(),
      sortOrder: (m['sort_order'] as num).toInt(),
      isActive: m['is_active'] as bool,
      createdAt: m['created_at'] as DateTime,
      updatedAt: m['updated_at'] as DateTime,
    );
  }

  Department copyWith({List<Department>? children}) {
    return Department(
      id: id,
      name: name,
      parentId: parentId,
      level: level,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'level': level,
        'sort_order': sortOrder,
        'is_active': isActive,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'children': children.map((c) => c.toJson()).toList(),
      };
}
