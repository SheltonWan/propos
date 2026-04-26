import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/department.dart';
import '../repositories/department_repository.dart';

/// DepartmentService — 组织架构业务逻辑。
///
/// 约束：
///   1. 部门层级最大 3 级
///   2. 父部门必须 is_active = true 才能挂新子部门
///   3. 停用前必须先清空在职员工与活跃子部门
class DepartmentService {
  final Pool _db;

  DepartmentService(this._db);

  static const int _maxDepth = 3;

  /// 查询部门树（包含全部活跃 + 停用节点，前端可自行过滤）。
  Future<List<Department>> getTree() async {
    final all = await DepartmentRepository(_db).findAll(includeInactive: true);
    return _buildTree(all);
  }

  /// 创建部门（顶级或挂在已有父部门下）。
  Future<Department> create({
    required String name,
    String? parentId,
    int sortOrder = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', '部门名称不能为空');
    }

    int level = 1;
    if (parentId != null) {
      final parent = await DepartmentRepository(_db).findById(parentId);
      if (parent == null) {
        throw const NotFoundException(
            'PARENT_DEPARTMENT_NOT_FOUND', '父部门不存在');
      }
      if (!parent.isActive) {
        throw const ValidationException(
            'PARENT_DEPARTMENT_INACTIVE', '父部门已停用');
      }
      level = parent.level + 1;
      if (level > _maxDepth) {
        throw const ValidationException(
            'MAX_DEPTH_EXCEEDED', '部门层级超过 $_maxDepth 级');
      }
    }

    return DepartmentRepository(_db).create(
      name: name.trim(),
      parentId: parentId,
      level: level,
      sortOrder: sortOrder,
    );
  }

  /// 更新部门。
  Future<Department> update(
    String id, {
    String? name,
    String? parentId,
    bool parentIdSet = false,
    int? sortOrder,
  }) async {
    final repo = DepartmentRepository(_db);
    final current = await repo.findById(id);
    if (current == null) {
      throw const NotFoundException('DEPARTMENT_NOT_FOUND', '部门不存在');
    }

    int? newLevel;
    if (parentIdSet) {
      if (parentId == null) {
        newLevel = 1;
      } else {
        if (parentId == id) {
          throw const ValidationException(
              'INVALID_PARENT', '不能将部门设置为自身的子部门');
        }
        // 防环：新父部门不能是当前部门的后代
        final wouldCycle = await repo.isDescendantOf(id, parentId);
        if (wouldCycle) {
          throw const ValidationException('INVALID_PARENT', '新父部门导致循环引用');
        }
        final parent = await repo.findById(parentId);
        if (parent == null) {
          throw const NotFoundException(
              'PARENT_DEPARTMENT_NOT_FOUND', '父部门不存在');
        }
        if (!parent.isActive) {
          throw const ValidationException(
              'PARENT_DEPARTMENT_INACTIVE', '父部门已停用');
        }
        newLevel = parent.level + 1;
        if (newLevel > _maxDepth) {
          throw const ValidationException(
              'MAX_DEPTH_EXCEEDED', '部门层级超过 $_maxDepth 级');
        }
      }
    }

    final updated = await repo.update(
      id,
      name: name?.trim().isEmpty ?? true ? null : name!.trim(),
      parentId: parentId,
      parentIdSet: parentIdSet,
      level: newLevel,
      sortOrder: sortOrder,
    );
    if (updated == null) {
      throw const NotFoundException('DEPARTMENT_NOT_FOUND', '部门不存在');
    }
    return updated;
  }

  /// 停用部门（逻辑删除）。
  Future<void> deactivate(String id) async {
    final repo = DepartmentRepository(_db);
    final current = await repo.findById(id);
    if (current == null) {
      throw const NotFoundException('DEPARTMENT_NOT_FOUND', '部门不存在');
    }
    if (!current.isActive) {
      // 幂等：已停用直接返回
      return;
    }
    if (await repo.hasActiveChildren(id)) {
      throw const ConflictException(
          'DEPARTMENT_HAS_ACTIVE_CHILDREN', '部门下有活跃子部门，无法停用');
    }
    if (await repo.hasActiveUsers(id)) {
      throw const ConflictException(
          'DEPARTMENT_HAS_ACTIVE_USERS', '部门下有在职员工，无法停用');
    }
    await repo.deactivate(id);
  }

  // ─── 树构造 ──────────────────────────────────────────────────────────────

  List<Department> _buildTree(List<Department> all) {
    final byParent = <String?, List<Department>>{};
    for (final d in all) {
      byParent.putIfAbsent(d.parentId, () => []).add(d);
    }
    Department withChildren(Department d) {
      final kids = byParent[d.id] ?? const [];
      return d.copyWith(
        children: kids.map(withChildren).toList(),
      );
    }

    final roots = byParent[null] ?? const [];
    return roots.map(withChildren).toList();
  }
}
