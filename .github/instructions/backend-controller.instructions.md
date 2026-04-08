---
description: "Use when writing or editing Controller layer HTTP route handlers in the backend. Enforces response envelope format, RBAC middleware, no business logic, and error code registry."
applyTo: "backend/lib/**/controllers/**"
---

# Controller 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 Controller 层特有强制规则。

## Controller 职责边界（铁律）

Controller **只做三件事**，其余一概不写：

```
1. 解析请求参数（query / path / body）
2. 调用 Service 方法
3. 返回标准信封 JSON
```

禁止在 Controller 中出现：业务判断、SQL、日期计算、`if/else` 业务分支。

## 标准响应信封（不得自行发明格式）

```dart
// ✅ 成功响应
Response.ok(jsonEncode({'data': model.toJson()}));
Response.ok(jsonEncode({'data': list.map((e) => e.toJson()).toList(), 'meta': {'page': page, 'pageSize': pageSize, 'total': total}}));

// ✅ 创建成功
Response(201, body: jsonEncode({'data': created.toJson()}));

// ❌ 错误响应 — 不要在 Controller 直接构建，应让 AppException 经 error_handler.dart 处理
```

## RBAC 中间件注解

每个路由 handler **必须**声明所需权限，通过 `rbacMiddleware` 管道传递：

```dart
// 示例：注册路由时指定权限
router.get('/api/contracts', rbacMiddleware(['contracts.read'], contractController.list));
router.post('/api/contracts', rbacMiddleware(['contracts.write'], contractController.create));

// 二房东端点额外标注隔离标志
router.get('/api/subleases', rbacMiddleware(['sublease.read'], subLeaseController.list, subLandlordIsolated: true));
```

RBAC 权限字符串参考 @file:docs/backend/RBAC_MATRIX.md

## 路由 Handler 签名

```dart
Future<Response> list(Request request) async {
  final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
  final pageSize = int.tryParse(request.url.queryParameters['pageSize'] ?? '20') ?? 20;
  // 调用 Service，不做任何业务处理
  final result = await _service.listContracts(page: page, pageSize: pageSize);
  return Response.ok(jsonEncode({'data': result.items.map((e) => e.toJson()).toList(), 'meta': result.meta.toJson()}));
}
```

## 错误处理

Controller **绝对不允许** `try/catch` 后自行构建错误响应。Service 抛出的 `AppException` 由全局 `error_handler.dart` 统一处理。

```dart
// ❌ 不要这样做
try {
  ...
} catch (e) {
  return Response(404, body: jsonEncode({'error': e.toString()}));
}

// ✅ 直接 await，异常会被全局错误处理器捕获
final result = await _service.getContract(id);
```

## 超限拆分信号

`*_controller.dart` 超过 **150 行**或路由 handler 超过 **6 个** → 按资源拆分 Controller 文件，统一在 `router/` 挂载。

## 参考文档

- @file:docs/backend/API_CONTRACT_v1.7.md — 字段定义与响应格式
- @file:docs/backend/ERROR_CODE_REGISTRY.md — 所有错误 code 枚举
- @file:docs/backend/RBAC_MATRIX.md — 各端点的权限要求
