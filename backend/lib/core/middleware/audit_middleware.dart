import 'dart:convert';
import 'dart:io' as io;
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import '../request_context.dart';

// ---------------------------------------------------------------------------
// 审计规格：审计操作类型描述
// ---------------------------------------------------------------------------

/// 单条高风险操作的审计规格描述（编译期常量）。
class _AuditSpec {
  /// 写入 audit_logs.action 的操作字符串（snake.case）
  final String action;

  /// 写入 audit_logs.resource_type 的资源类型
  final String resourceType;

  /// 用于查询 before/after 状态的数据库表名（仅限安全白名单内的固定值）
  final String table;

  const _AuditSpec(this.action, this.resourceType, this.table);
}

// ---------------------------------------------------------------------------
// 高风险路由审计映射
//
// 格式：路径前缀 → HTTP方法 → 审计规格
// 覆盖4类高风险操作（架构约束 #4）：
//   1. 合同变更   → contract.update
//   2. 账单核销   → invoice.write_off
//   3. 权限变更   → user.role_change
//   4. 二房东提交 → sublease.submit
//
// 注意：'/api/contracts/' 含尾部斜杠，确保仅匹配携带资源 ID 的路径
//       而不匹配 '/api/contracts'（列表查询）。
// ---------------------------------------------------------------------------
const _auditRouteMap = <String, Map<String, _AuditSpec>>{
  '/api/contracts/': {
    'PATCH': _AuditSpec('contract.update', 'contract', 'contracts'),
  },
  '/api/invoices/': {
    'PATCH': _AuditSpec('invoice.write_off', 'invoice', 'invoices'),
  },
  '/api/users/': {
    'PATCH': _AuditSpec('user.role_change', 'user', 'users'),
  },
  // subleases 无尾部斜杠：同时捕获 POST /api/subleases 和 PATCH /api/subleases/:id
  '/api/subleases': {
    'POST': _AuditSpec('sublease.submit', 'sublease', 'subleases'),
    'PATCH': _AuditSpec('sublease.submit', 'sublease', 'subleases'),
  },
};

// ---------------------------------------------------------------------------
// UUID 格式校验
// ---------------------------------------------------------------------------
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

// ---------------------------------------------------------------------------
// 审计中间件
// ---------------------------------------------------------------------------

/// 高风险操作审计中间件。
///
/// 拦截 [_auditRouteMap] 中定义的4类高风险操作，捕获变更前后的完整 JSON 快照，
/// 写入 audit_logs 表。
///
/// - before_json：操作前从数据库查询的资源完整状态（非 null）
/// - after_json：操作后从响应信封 data 字段解析的资源状态（非 null）
/// - 日志写入异步执行，不阻塞业务响应
Middleware auditMiddleware(Pool db) {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = '/${request.url.path}';
      final method = request.method;

      // 匹配是否为高风险操作
      final spec = _matchAuditSpec(path, method);
      if (spec == null) return innerHandler(request);

      // 未认证请求不记录审计（auth 中间件已前置拦截）
      final ctx = request.context[kRequestContextKey] as RequestContext?;
      if (ctx == null) return innerHandler(request);

      // 从路径提取资源 ID（PATCH 有 ID；POST 新建则无 ID）
      final resourceId = _extractResourceId(path);

      // 查询变更前状态（before）——POST 新建时返回空对象 {}
      final beforeJson = resourceId != null
          ? await _fetchResourceState(db, spec.table, resourceId)
          : <String, dynamic>{};

      // 读取请求体字节并重构 Request，防止 body stream 二次消费
      final bodyBytes = <int>[];
      await for (final chunk in request.read()) {
        bodyBytes.addAll(chunk);
      }
      final reconstructedRequest = request.change(body: bodyBytes);

      // 执行请求
      final response = await innerHandler(reconstructedRequest);

      // 仅在 2xx 时写审计日志
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 读取响应体字节（消费一次后需重建 Response）
        final respBodyBytes = <int>[];
        await for (final chunk in response.read()) {
          respBodyBytes.addAll(chunk);
        }
        final respBodyStr = utf8.decode(respBodyBytes);

        // 从响应信封 data 字段解析 after 状态
        final afterJson = _extractDataFromEnvelope(respBodyStr);

        // POST 新建时从响应中获取 resource_id；PATCH 则已从路径取得
        final effectiveId = resourceId ?? _extractIdFromData(afterJson);

        if (effectiveId != null) {
          final ipAddress =
              request.headers['x-forwarded-for']?.split(',').first.trim() ??
                  request.headers['x-real-ip'];

          // 异步写入审计日志，不阻塞响应
          _writeAuditLog(
            db: db,
            userId: ctx.userId,
            action: spec.action,
            resourceType: spec.resourceType,
            resourceId: effectiveId,
            beforeJson: beforeJson,
            afterJson: afterJson,
            ipAddress: ipAddress,
          ).ignore();
        }

        // 重建响应（body stream 已被消费）
        return response.change(body: respBodyBytes);
      }

      return response;
    };
  };
}

// ---------------------------------------------------------------------------
// 内部辅助函数
// ---------------------------------------------------------------------------

/// 按路径前缀 + 方法从 [_auditRouteMap] 匹配审计规格。
_AuditSpec? _matchAuditSpec(String path, String method) {
  for (final entry in _auditRouteMap.entries) {
    if (path.startsWith(entry.key)) {
      return entry.value[method];
    }
  }
  return null;
}

/// 从 URL 路径中提取首个符合 UUID 格式的路径段。
String? _extractResourceId(String path) {
  for (final segment in path.split('/')) {
    if (_uuidPattern.hasMatch(segment)) return segment;
  }
  return null;
}

/// 从响应信封字符串中解析 data 字段。
/// 解析失败时返回空 Map（保证 after_json 非 null）。
Map<String, dynamic> _extractDataFromEnvelope(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
    }
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

/// 从已解析的 data Map 中提取 id 字段（UUID 格式）。
String? _extractIdFromData(Map<String, dynamic> data) {
  final id = data['id'];
  if (id is String && _uuidPattern.hasMatch(id)) return id;
  return null;
}

/// 从数据库查询指定资源的当前完整状态（before 快照）。
///
/// 安全说明：
///   - [table] 只能是 [_auditRouteMap] 中硬编码的白名单表名，不接受外部输入
///   - users 表排除 password_hash 等敏感字段
///   - 查询失败时返回空 Map，不阻断审计流程
Future<Map<String, dynamic>> _fetchResourceState(
  Pool db,
  String table,
  String resourceId,
) async {
  // 安全表名到 SQL 的静态映射（防止 SQL 注入，严禁字符串拼接）
  final sql = switch (table) {
    'contracts' => '''
        SELECT row_to_json(t.*) AS state
        FROM contracts t WHERE t.id = @id::uuid
      ''',
    'invoices' => '''
        SELECT row_to_json(t.*) AS state
        FROM invoices t WHERE t.id = @id::uuid
      ''',
    'subleases' => '''
        SELECT row_to_json(t.*) AS state
        FROM subleases t WHERE t.id = @id::uuid
      ''',
    // 用户表排除密码哈希及 OTP 等敏感字段
    'users' => '''
        SELECT row_to_json(t.*) AS state FROM (
          SELECT id, email, name, role::TEXT AS role,
                 department_id, is_active, session_version,
                 bound_contract_id, created_at, updated_at
          FROM users WHERE id = @id::uuid
        ) t
      ''',
    _ => null,
  };

  if (sql == null) return {};

  try {
    final result = await db.execute(
      Sql.named(sql),
      parameters: {'id': resourceId},
    );
    if (result.isEmpty) return {};

    final stateJson = result.first.toColumnMap()['state'];
    if (stateJson is Map<String, dynamic>) return stateJson;
    if (stateJson is String) {
      return jsonDecode(stateJson) as Map<String, dynamic>;
    }
    return {};
  } catch (e) {
    io.stderr.writeln('[AUDIT_WARN] 查询变更前状态失败 table=$table id=$resourceId: $e');
    return {};
  }
}

/// 将审计日志写入 audit_logs 表。
///
/// [beforeJson] 和 [afterJson] 均为完整 JSON 对象（非 null）。
/// 写入失败只记录错误日志，不影响主业务响应。
Future<void> _writeAuditLog({
  required Pool db,
  required String userId,
  required String action,
  required String resourceType,
  required String resourceId,
  required Map<String, dynamic> beforeJson,
  required Map<String, dynamic> afterJson,
  String? ipAddress,
}) async {
  try {
    await db.execute(
      Sql.named('''
        INSERT INTO audit_logs
          (user_id, action, resource_type, resource_id,
           before_json, after_json, ip_address, retention_until)
        VALUES
          (@userId::uuid, @action, @resourceType, @resourceId::uuid,
           @beforeJson::jsonb, @afterJson::jsonb,
           @ipAddress::inet,
           NOW() + INTERVAL '3 years')
      '''),
      parameters: {
        'userId': userId,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'beforeJson': jsonEncode(beforeJson),
        'afterJson': jsonEncode(afterJson),
        'ipAddress': ipAddress,
      },
    );
  } catch (e) {
    io.stderr
        .writeln('[AUDIT_ERROR] 审计日志写入失败 action=$action id=$resourceId: $e');
  }
}
