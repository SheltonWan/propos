import 'package:shelf/shelf.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

/// RBAC 权限校验中间件工厂函数
/// 接受所需权限字符串列表，当前用户角色不满足时抛出 ForbiddenException
///
/// 使用方式：
/// ```dart
/// router.get('/api/contracts',
///   rbacMiddleware(['contracts.read'])(contractController.list));
/// ```
Handler rbacMiddleware(
  List<String> requiredPermissions,
  Handler handler, {
  bool subLandlordIsolated = false,
}) {
  return (Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext?;
    if (ctx == null) {
      throw const UnauthorizedException();
    }

    final allowed = _hasPermissions(ctx.role, requiredPermissions);
    if (!allowed) {
      throw const ForbiddenException();
    }

    // 二房东数据隔离检查
    if (subLandlordIsolated && ctx.role == UserRole.subLandlord) {
      if (ctx.boundContractId == null) {
        throw const ForbiddenException(
            'SUBLEASE_SCOPE_MISSING', '二房东账户缺少绑定合同');
      }
    }

    return handler(request);
  };
}

/// 权限矩阵（与 docs/backend/RBAC_MATRIX.md 保持同步）
bool _hasPermissions(UserRole role, List<String> required) {
  final rolePermissions = _permissionMatrix[role] ?? {};
  return required.every((p) => rolePermissions.contains(p));
}

const _permissionMatrix = <UserRole, Set<String>>{
  UserRole.admin: {
    'assets.read', 'assets.write',
    'contracts.read', 'contracts.write',
    'finance.read', 'finance.write',
    'workorders.read', 'workorders.write',
    'sublease.read', 'sublease.write',
    'users.read', 'users.write',
    'kpi.read', 'kpi.write',
    'reports.read',
  },
  UserRole.operationsManager: {
    'assets.read', 'assets.write',
    'contracts.read', 'contracts.write',
    'finance.read',
    'workorders.read', 'workorders.write',
    'sublease.read', 'sublease.write',
    'kpi.read', 'kpi.write',
    'reports.read',
  },
  UserRole.leaseSpecialist: {
    'assets.read',
    'contracts.read', 'contracts.write',
    'finance.read',
    'sublease.read',
    'reports.read',
  },
  UserRole.financeStaff: {
    'assets.read',
    'contracts.read',
    'finance.read', 'finance.write',
    'kpi.read',
    'reports.read',
  },
  UserRole.maintenanceStaff: {
    'assets.read',
    'workorders.read', 'workorders.write',
  },
  UserRole.subLandlord: {
    'sublease.read', 'sublease.write',
  },
  UserRole.readOnly: {
    'assets.read',
    'contracts.read',
    'finance.read',
    'workorders.read',
    'kpi.read',
    'reports.read',
  },
};
