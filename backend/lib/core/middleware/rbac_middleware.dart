import 'package:shelf/shelf.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

// ---------------------------------------------------------------------------
// 1. Pipeline 级全局 RBAC 中间件（用于 bin/server.dart addMiddleware）
// ---------------------------------------------------------------------------

/// 全局 RBAC 中间件——基于 URL 前缀和 HTTP 方法进行权限核查。
///
/// 公开路由（`/health`、`/api/auth/*`）直接放行。
/// 其余路由要求已登录，并按路由权限表检查最低权限。
/// Day 7 会进一步完善权限矩阵覆盖所有业务路由。
Middleware rbacMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final path = '/${request.url.path}';
      final method = request.method;

      // 公开路由跳过 RBAC
      if (_isPublicPath(path)) {
        return inner(request);
      }

      // 获取用户上下文（authMiddleware 已验证 JWT 并注入）
      final ctx = request.context[kRequestContextKey] as RequestContext?;
      if (ctx == null) {
        // 防御性拦截：auth 中间件应已拒绝未认证请求
        throw const UnauthorizedException();
      }

      // 二房东角色限制：只能访问自身外部填报路由
      if (ctx.role == UserRole.subLandlord && !_isSubLandlordPath(path)) {
        throw const ForbiddenException();
      }
      if (ctx.role == UserRole.subLandlord && ctx.boundContractId == null) {
        throw const ForbiddenException('SUBLEASE_SCOPE_MISSING', '二房东账户未绑定主合同');
      }

      // 按路由权限表核查最低所需权限
      final required = _lookupRequiredPermissions(path, method);
      if (required != null && !_hasPermissions(ctx.role, required)) {
        throw const ForbiddenException();
      }

      return inner(request);
    };
  };
}

// ---------------------------------------------------------------------------
// 2. Per-route 装饰器（用于 Controller 方法级精细权限控制）
// ---------------------------------------------------------------------------

/// Per-route RBAC 和隐二房东数据隔离装饰器。
///
/// 用法（Controller 注册路由时）：
/// ```dart
/// router.get('/api/contracts',
///   withRbac(['contracts.read'], contractController.list));
/// router.get('/api/subleases',
///   withRbac(['sublease.read'], subLeaseController.list,
///     subLandlordIsolated: true));
/// ```
Handler withRbac(
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

// ---------------------------------------------------------------------------
// 内部辅助方法
// ---------------------------------------------------------------------------

/// 判断路由是否属于公开不需鉴权的路径。
/// 仅登录和刷新 Token 两个端点无需 Bearer，其余 /api/auth/* 均需鉴权。
/// Shelf 的 request.url.path 不含前导斜杠，此处 path 已在外部加了 '/'。
bool _isPublicPath(String path) =>
    path == '/health' ||
    path == '/api/auth/login' ||
    path == '/api/auth/refresh';

/// 二房东可访问的路径前缀
bool _isSubLandlordPath(String path) =>
    path.startsWith('/api/subleases/portal');

/// 按路由前缀 + HTTP 方法查询路由所需最低权限列表。
/// 返回 null 表示所有已登录用户均可访问（由 per-route 层进一步控制）。
List<String>? _lookupRequiredPermissions(String path, String method) {
  for (final rule in _routeTable) {
    if (path.startsWith(rule.prefix)) {
      return rule.methodPermissions[method] ?? rule.methodPermissions['*'];
    }
  }
  return null; // 未进入表：不强制（per-route 层自行处理）
}

/// 路由权限規则表（按匹配顺序排列，越具体的前缀先列出）
/// 这里定义的是最低入场门槛权限，具体 handler 可再用 withRbac 层叠加。
final _routeTable = <_RouteRule>[
  // ── 认证（/api/auth/me、logout、change-password 需已登录，无需特定权限） ──
  _RouteRule('/api/auth', {'*': []}),

  // ── 用户管理（仅 admin/super_admin） ──
  _RouteRule('/api/users', {
    'GET': ['users.read'],
    'POST': ['users.write'],
    'PATCH': ['users.write'],
    'DELETE': ['users.write'],
  }),

  // ── 一-A 组织架构 ──
  _RouteRule('/api/departments', {
    'GET': ['org.read'],
    'POST': ['org.manage'],
    'PATCH': ['org.manage'],
    'DELETE': ['org.manage'],
  }),
  _RouteRule('/api/managed-scopes', {
    'GET': ['org.read'],
    'PUT': ['org.manage'],
  }),

  // ── M1 资产 ──
  // 顺序重要：更具体的前缀先列出（/api/floor-plans 先于 /api/floors）
  _RouteRule('/api/floor-plans', {
    'GET': ['assets.read'],
    'PATCH': ['assets.write'],
  }),
  _RouteRule('/api/assets', {
    'GET': ['assets.read'],
  }),
  _RouteRule('/api/buildings', {
    'GET': ['assets.read'],
    'POST': ['assets.write'],
    'PATCH': ['assets.write'],
  }),
  _RouteRule('/api/floors', {
    'GET': ['assets.read'],
    'POST': ['assets.write'],
    'PATCH': ['assets.write'],
  }),
  _RouteRule('/api/units', {
    'GET': ['assets.read'],
    'POST': ['assets.write'],
    'PATCH': ['assets.write'],
    'DELETE': ['assets.write'],
  }),
  _RouteRule('/api/renovations', {
    'GET': ['assets.read'],
    'POST': ['assets.write'],
    'PATCH': ['assets.write'],
  }),

  // ── M2 合同 ──
  _RouteRule('/api/tenants', {
    'GET': ['contracts.read'],
    'POST': ['contracts.write'],
    'PATCH': ['contracts.write'],
  }),
  _RouteRule('/api/escalation-templates', {
    'GET': ['contracts.read'],
    'POST': ['contracts.write'],
    'PATCH': ['contracts.write'],
    'DELETE': ['contracts.write'],
  }),
  _RouteRule('/api/contracts', {
    'GET': ['contracts.read'],
    'POST': ['contracts.write'],
    'PATCH': ['contracts.write'],
  }),
  _RouteRule('/api/alerts', {
    'GET': ['alerts.read'],
    'POST': ['alerts.write'],
    'PATCH': ['alerts.read'], // 标记已读只需 alerts.read
  }),

  // ── M2-A 押金 ──
  _RouteRule('/api/deposits', {
    'GET': ['deposit.read'],
    'POST': ['deposit.write'],
    'PATCH': ['deposit.write'],
  }),

  // ── M3 财务 ──
  _RouteRule('/api/invoices', {
    'GET': ['finance.read'],
    'POST': ['finance.write'],
    'PATCH': ['finance.write'],
  }),
  _RouteRule('/api/payments', {
    'GET': ['finance.read'],
    'POST': ['finance.write'],
    'PATCH': ['finance.write'],
  }),
  _RouteRule('/api/expenses', {
    'GET': ['finance.read'],
    'POST': ['finance.write'],
    'PATCH': ['finance.write'],
    'DELETE': ['finance.write'],
  }),
  _RouteRule('/api/noi', {
    'GET': ['finance.read'],
    'POST': ['finance.write'],
  }),
  // kpi.view 是查看权限（RBAC_MATRIX.md 定义的权限字符串）
  _RouteRule('/api/kpi', {
    'GET': ['kpi.view'],
    'POST': ['kpi.manage'],
    'PATCH': ['kpi.manage'],
    'PUT': ['kpi.manage'],
    'DELETE': ['kpi.manage'],
  }),

  // ── M4 工单 ──
  _RouteRule('/api/workorders', {
    'GET': ['workorders.read'],
    'POST': ['workorders.write'],
    'PATCH': ['workorders.write'],
  }),

  // ── M5 二房东 ──
  _RouteRule('/api/subleases', {
    'GET': ['sublease.read'],
    'POST': ['sublease.write'],
    'PATCH': ['sublease.write'],
  }),

  // ── 文件代理 / 报表 ──
  _RouteRule('/api/files', {'GET': ['assets.read']}),
  _RouteRule('/api/reports', {'GET': ['finance.read']}),
];

/// 路由权限规则数据类
class _RouteRule {
  final String prefix;

  /// HTTP 方法 → 所需权限列表；键 `'*'` 匹配任意方法
  final Map<String, List<String>> methodPermissions;

  const _RouteRule(this.prefix, this.methodPermissions);
}

// ---------------------------------------------------------------------------
// 权限矩阵（角色 → 权限字符串集合）
// 与 docs/backend/RBAC_MATRIX.md 保持同步
// ---------------------------------------------------------------------------
bool _hasPermissions(UserRole role, List<String> required) {
  final rolePermissions = _permissionMatrix[role] ?? {};
  return required.every((p) => rolePermissions.contains(p));
}

const _permissionMatrix = <UserRole, Set<String>>{
  UserRole.admin: {
    'org.read', 'org.manage',
    'assets.read', 'assets.write',
    'contracts.read', 'contracts.write',
    'deposit.read', 'deposit.write',
    'finance.read', 'finance.write',
    'kpi.view', 'kpi.manage', 'kpi.appeal',
    'meterReading.write', 'turnoverReview.approve',
    'workorders.read', 'workorders.write',
    'sublease.read', 'sublease.write',
    'alerts.read', 'alerts.write',
    'ops.read', 'ops.write',
    'import.execute',
    // Legacy aliases kept for backward-compat with existing middleware tests
    'users.read', 'users.write', 'reports.read',
  },
  UserRole.operationsManager: {
    'org.read',
    'org.manage',
    'assets.read', 'assets.write',
    'contracts.read', 'contracts.write',
    'deposit.read',
    'finance.read',
    'kpi.view',
    'kpi.manage',
    'kpi.appeal',
    'meterReading.write',
    'workorders.read', 'workorders.write',
    'sublease.read', 'sublease.write',
    'alerts.read',
    'alerts.write',
    'ops.read',
    'import.execute',
    'reports.read',
  },
  UserRole.leaseSpecialist: {
    'org.read',
    'assets.read',
    'contracts.read', 'contracts.write',
    'deposit.read',
    'finance.read',
    'kpi.view',
    'kpi.appeal',
    'meterReading.write',
    'workorders.read',
    'sublease.read',
    'sublease.write',
    'alerts.read',
    'import.execute',
    'reports.read',
  },
  UserRole.financeStaff: {
    'org.read',
    'assets.read',
    'contracts.read',
    'deposit.read',
    'deposit.write',
    'finance.read', 'finance.write',
    'kpi.view',
    'kpi.appeal',
    'meterReading.write',
    'turnoverReview.approve',
    'sublease.read',
    'alerts.read',
    'import.execute',
    'reports.read',
  },
  UserRole.maintenanceStaff: {
    'org.read',
    'assets.read',
    'contracts.read',
    'kpi.view',
    'kpi.appeal',
    'meterReading.write',
    'workorders.read', 'workorders.write',
  },
  UserRole.subLandlord: {
    'sublease.portal',
  },
  UserRole.readOnly: {
    'org.read',
    'assets.read',
    'contracts.read',
    'finance.read',
    'workorders.read',
    'kpi.view',
    'reports.read',
  },
};

