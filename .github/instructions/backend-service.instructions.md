---
description: "Use when writing or editing Service layer business logic in the backend. Enforces AppException pattern, audit logging for 4 scenarios, and no direct HTTP Response returns."
applyTo: "backend/lib/**/services/**"
---

# Service 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 Service 层特有强制规则。

## 错误处理（铁律）

Service **禁止** `return Response(...)` 或 `import 'package:shelf/shelf.dart'`。  
所有异常通过 `AppException` 抛出，由全局 `error_handler.dart` 统一转为 HTTP 响应：

```dart
// ✅ 正确
import 'package:propos_backend/shared/exceptions/app_exception.dart';

if (contract == null) {
  throw AppException('CONTRACT_NOT_FOUND', '合同不存在', 404);
}
if (!_canModify(contract, currentUser)) {
  throw AppException('FORBIDDEN', '无操作权限', 403);
}

// ❌ 错误 — Service 不应知道 HTTP
return Response(404, body: '...');
```

所有 `code` 值必须来自 `ERROR_CODE_REGISTRY.md`，不得自造新字符串。

## 审计日志（四类操作必须记录）

以下操作**完成后**必须写入 `audit_logs` 表（before/after JSON 不得为 null）：

| 触发场景 | `action` 字段值 | 必须记录的字段 |
|---------|--------------|-------------|
| 合同状态变更/续签/终止 | `contract.update` | before: 原状态, after: 新状态 |
| 账单核销（payment_allocations） | `invoice.write_off` | before: null, after: 核销详情 |
| 用户角色/权限变更 | `user.role_update` | before: 旧角色, after: 新角色 |
| 二房东子租赁创建/更新 | `sublease.submit` | before: 原记录(null 若为新建), after: 新记录 |

```dart
// 审计调用模板
await _auditRepository.log(
  actorId: currentUser.id,
  action: 'contract.update',
  targetType: 'contract',
  targetId: contract.id,
  before: originalContract.toJson(),
  after: updatedContract.toJson(),
);
```

## 业务计算规则

- WALE、NOI、KPI 打分计算**禁止内联在 Service 中**，必须调用对应 package：
  - `rent_escalation_engine` — 租金递增
  - `kpi_scorer` — KPI 线性插值打分
- 日期计算使用注入的 `Clock` 接口，**禁止 `DateTime.now()`**

## 超限拆分信号

`*_service.dart` 超过 **250 行**或方法超过 **8 个** → 按子领域拆分（如 `WaleService` 独立于 `ContractService`）。

## 参考文档

- @file:docs/backend/ERROR_CODE_REGISTRY.md — 完整错误码列表
- @file:docs/backend/CONTRACT_STATE_MACHINE.md — 合同状态机（合同变更的合法转移路径）
