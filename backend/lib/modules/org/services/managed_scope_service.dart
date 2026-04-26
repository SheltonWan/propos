import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/managed_scope.dart';
import '../repositories/managed_scope_repository.dart';

/// ManagedScopeService — 管辖范围设置（部门默认 + 个人覆盖）。
///
/// 写入时整体覆写：删除该 owner 的全部现有范围后批量插入。
class ManagedScopeService {
  final Pool _db;

  ManagedScopeService(this._db);

  /// 查询管辖范围。允许同时不传，返回空列表（避免误用）。
  Future<List<ManagedScope>> list({
    String? departmentId,
    String? userId,
  }) async {
    return ManagedScopeRepository(_db).find(
      departmentId: departmentId,
      userId: userId,
    );
  }

  /// 覆写设置管辖范围。
  /// [scopes] 中每条至少需指定一个维度（building / floor / property_type）。
  Future<List<ManagedScope>> set({
    String? departmentId,
    String? userId,
    required List<Map<String, dynamic>> scopes,
  }) async {
    if ((departmentId == null) == (userId == null)) {
      throw const ValidationException(
          'VALIDATION_ERROR', 'department_id 与 user_id 必须二选一');
    }

    return await _db.runTx<List<ManagedScope>>((tx) async {
      final repo = ManagedScopeRepository(tx);
      await repo.deleteByOwner(
        departmentId: departmentId,
        userId: userId,
        tx: tx,
      );
      for (final s in scopes) {
        final building = s['building_id'] as String?;
        final floor = s['floor_id'] as String?;
        final propertyType = s['property_type'] as String?;
        if (building == null && floor == null && propertyType == null) {
          throw const ValidationException(
              'VALIDATION_ERROR', '每条管辖范围至少需指定一个维度');
        }
        await repo.insert(
          departmentId: departmentId,
          userId: userId,
          buildingId: building,
          floorId: floor,
          propertyType: propertyType,
          tx: tx,
        );
      }
      return repo.find(departmentId: departmentId, userId: userId);
    });
  }
}
