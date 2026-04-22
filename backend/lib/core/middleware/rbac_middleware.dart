import 'package:shelf/shelf.dart';
import '../request_context.dart';
import '../errors/app_exception.dart';

// ---------------------------------------------------------------------------
// 常量角色集合（减少矩阵内重复字符串集合，编译期常量）
// ---------------------------------------------------------------------------

/// 全体内部员工角色（不含二房东）
const _kAll = {
  'super_admin',
  'operations_manager',
  'leasing_specialist',
  'finance_staff',
  'maintenance_staff',
  'property_inspector',
  'report_viewer',
};

/// 仅管理层（超管 + 运营）
const _kMgmt = {'super_admin', 'operations_manager'};

/// 有资产写入权限的角色
const _kAssetWrite = {
  'super_admin',
  'operations_manager',
  'leasing_specialist',
};

/// 有合同写入权限的角色
const _kContractWrite = {
  'super_admin',
  'operations_manager',
  'leasing_specialist',
};

/// 有财务写入权限的角色
const _kFinanceWrite = {
  'super_admin',
  'operations_manager',
  'finance_staff',
};

// ---------------------------------------------------------------------------
// 路由权限矩阵（唯一权限源头，禁止在业务代码中散落 if-else 角色判断）
//
// 格式：路径前缀 → HTTP方法 → 允许角色集合（UserRole.value 字符串）
//
// 匹配规则：
//   - 按 Map 插入顺序扫描，第一个匹配的前缀生效
//   - 方法键 '*' 匹配任意 HTTP 方法（兜底）
//   - 空集合 Set<String>{} 表示任何已认证角色均可访问
//   - 路径越具体越靠前（防止宽泛前缀遮蔽具体规则）
// ---------------------------------------------------------------------------
const Map<String, Map<String, Set<String>>> _routePermissionMatrix = {
  // ── 认证（/api/auth/me、logout、change-password 需已登录，无角色限制）──
  '/api/auth': {'*': <String>{}},

  // ── 用户管理 ──────────────────────────────────────────────────────────────
  '/api/users': {
    'GET': _kMgmt,
    'POST': {'super_admin'},
    'PATCH': {'super_admin'},
    'DELETE': {'super_admin'},
  },

  // ── 组织架构 ──────────────────────────────────────────────────────────────
  '/api/departments': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kMgmt,
    'PATCH': _kMgmt,
    'DELETE': _kMgmt,
  },
  '/api/managed-scopes': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'PUT': _kMgmt,
  },

  // ── M1 资产（具体路径前缀先于宽泛前缀）────────────────────────────────────
  '/api/floor-plans': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'PATCH': _kAssetWrite,
  },
  '/api/assets': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
  },
  '/api/buildings': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kAssetWrite,
    'PATCH': _kAssetWrite,
  },
  '/api/floors': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kAssetWrite,
    'PATCH': _kAssetWrite,
  },
  '/api/units': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kAssetWrite,
    'PATCH': _kAssetWrite,
    'DELETE': _kMgmt,
  },
  '/api/renovations': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kAssetWrite,
    'PATCH': _kAssetWrite,
  },

  // ── M2 合同 ───────────────────────────────────────────────────────────────
  '/api/tenants': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': _kContractWrite,
  },
  '/api/escalation-templates': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': _kContractWrite,
    'DELETE': _kMgmt,
  },
  '/api/contracts': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': _kContractWrite,
  },
  '/api/alerts': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
    },
  },

  // ── M2-A 押金 ──────────────────────────────────────────────────────────────
  '/api/deposits': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
    },
    'PATCH': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
    },
  },

  // ── M3 财务 ───────────────────────────────────────────────────────────────
  '/api/invoices': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kFinanceWrite,
    'PATCH': _kFinanceWrite,
  },
  '/api/payments': {
    'GET': {
      'super_admin',
      'operations_manager',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kFinanceWrite,
    'PATCH': _kFinanceWrite,
  },
  '/api/expenses': {
    'GET': {
      'super_admin',
      'operations_manager',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kFinanceWrite,
    'PATCH': _kFinanceWrite,
    'DELETE': _kMgmt,
  },
  '/api/noi': {
    'GET': {
      'super_admin',
      'operations_manager',
      'finance_staff',
      'report_viewer'
    },
    'POST': _kMgmt,
  },
  '/api/meter-readings': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'maintenance_staff',
      'property_inspector',
    },
    'POST': {
      'super_admin',
      'operations_manager',
      'finance_staff',
      'maintenance_staff',
      'property_inspector',
    },
    'PATCH': _kFinanceWrite,
  },
  '/api/turnover-reports': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': _kFinanceWrite,
  },
  '/api/kpi': {
    'GET': _kAll,
    'POST': _kMgmt,
    'PATCH': _kMgmt,
    'PUT': _kMgmt,
    'DELETE': _kMgmt,
  },

  // ── M4 工单 ───────────────────────────────────────────────────────────────
  '/api/workorders': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'maintenance_staff',
      'property_inspector',
      'report_viewer',
    },
    'POST': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'maintenance_staff',
    },
    'PATCH': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'maintenance_staff',
    },
  },

  // ── M5 二房东（具体路径前缀先于宽泛前缀）──────────────────────────────────
  '/api/subleases/portal': {
    '*': {'sub_landlord'}, // 二房东自助填报专属入口
  },
  '/api/subleases': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
    'POST': _kContractWrite,
    'PATCH': _kContractWrite,
  },

  // ── 文件代理 ──────────────────────────────────────────────────────────────
  '/api/files': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'maintenance_staff',
      'property_inspector',
      'report_viewer',
      'sub_landlord',
    },
    'POST': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'maintenance_staff',
    },
  },

  // ── 报表导出 ──────────────────────────────────────────────────────────────
  '/api/reports': {
    'GET': {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'report_viewer',
    },
  },
};

// ---------------------------------------------------------------------------
// 公开路由白名单（不需要 JWT 认证，与 auth_middleware 保持一致）
// ---------------------------------------------------------------------------
const _publicPaths = {
  '/health',
  '/api/auth/login',
  '/api/auth/refresh',
  '/api/auth/forgot-password',
  '/api/auth/reset-password',
  '/api/test/reset-account-lock',
};

// ---------------------------------------------------------------------------
// 1. Pipeline 级全局 RBAC 中间件
// ---------------------------------------------------------------------------

/// 全局 RBAC 中间件。
///
/// 以 [_routePermissionMatrix] 为唯一权限源，通过路径前缀 + HTTP 方法匹配
/// 当前用户角色是否在允许集合中。所有角色判断由矩阵驱动，禁止散落 if-else。
///
/// 无权限时返回 403 + `FORBIDDEN` code。
Middleware rbacMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final path = '/${request.url.path}';
      final method = request.method;

      // 公开路由无需 RBAC
      if (_publicPaths.contains(path)) {
        return inner(request);
      }

      final ctx = request.context[kRequestContextKey] as RequestContext?;
      if (ctx == null) {
        // 防御性拦截：auth 中间件应已拒绝未认证请求
        throw const UnauthorizedException();
      }

      // 二房东账户完整性校验（属于账户配置约束，非矩阵 RBAC 逻辑）
      if (ctx.role == UserRole.subLandlord && ctx.boundContractId == null) {
        throw const ForbiddenException('SUBLEASE_SCOPE_MISSING', '二房东账户未绑定主合同');
      }

      // 从矩阵解析允许角色集合
      final allowedRoles = _resolveAllowedRoles(path, method);

      // 路径不在矩阵中：对已认证用户放行（per-route 层自行控制）
      if (allowedRoles == null) return inner(request);

      // 空集合：任何已认证角色均可访问（如 /api/auth/me）
      if (allowedRoles.isEmpty) return inner(request);

      // 角色不在允许集合中：返回 403 FORBIDDEN
      if (!allowedRoles.contains(ctx.role.value)) {
        throw const ForbiddenException();
      }

      return inner(request);
    };
  };
}

// ---------------------------------------------------------------------------
// 2. Per-route 角色守卫装饰器（Controller 方法级精细控制）
// ---------------------------------------------------------------------------

/// 方法级 RBAC 角色守卫装饰器。
///
/// [allowedRoles] 为允许访问该 Handler 的角色 value 字符串集合。
/// [subLandlordIsolated] 为 true 时额外校验二房东绑定合同。
///
/// 用法：
/// ```dart
/// router.get('/api/contracts',
///   withRbac({'super_admin', 'leasing_specialist'}, handler));
/// router.get('/api/subleases',
///   withRbac({'leasing_specialist'}, handler, subLandlordIsolated: true));
/// ```
Handler withRbac(
  Set<String> allowedRoles,
  Handler handler, {
  bool subLandlordIsolated = false,
}) {
  return (Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext?;
    if (ctx == null) throw const UnauthorizedException();

    if (!allowedRoles.contains(ctx.role.value)) {
      throw const ForbiddenException();
    }

    if (subLandlordIsolated && ctx.role == UserRole.subLandlord) {
      if (ctx.boundContractId == null) {
        throw const ForbiddenException('SUBLEASE_SCOPE_MISSING', '二房东账户缺少绑定合同');
      }
    }

    return handler(request);
  };
}

// ---------------------------------------------------------------------------
// 内部辅助
// ---------------------------------------------------------------------------

/// 按路径前缀 + 方法从 [_routePermissionMatrix] 中解析允许的角色集合。
///
/// 返回 null 表示路径不在矩阵中（调用方决定是否放行）。
/// 返回空集合表示任何已认证角色均可访问。
Set<String>? _resolveAllowedRoles(String path, String method) {
  for (final entry in _routePermissionMatrix.entries) {
    if (!path.startsWith(entry.key)) continue;
    final methodMap = entry.value;
    // 精确方法匹配，不存在时回退通配符 '*'
    return methodMap[method] ?? methodMap['*'];
  }
  return null;
}

