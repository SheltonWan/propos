---
description: "Use when writing or editing Repository layer SQL queries in the backend. Enforces parameterized SQL, row-level tenant isolation, encrypted field handling, and pagination."
applyTo: "backend/lib/**/repositories/**"
---

# Repository 层约束

> 全局架构规则见 `.github/copilot-instructions.md`，本文件补充 Repository 层特有强制规则。

## SQL 安全（每条违反即为 bug）

- **禁止字符串拼接构建 SQL**：条件、ORDER BY 字段名均不得拼接，一律用 `$1,$2...` 占位符
- **动态排序**：字段名通过白名单 `Map<String, String>` 映射后插入，不直接使用用户输入

```dart
// ✅ 正确
final rows = await conn.execute(
  'SELECT * FROM contracts WHERE tenant_id = $1 AND status = $2 LIMIT $3 OFFSET $4',
  parameters: [tenantId, status, pageSize, offset],
);

// ❌ 错误 — SQL 注入风险
final rows = await conn.execute(
  'SELECT * FROM contracts WHERE tenant_id = \'$tenantId\'',
);
```

## 行级数据隔离（二房东模块）

涉及 `sub_leases` 或通过 `master_contract_id` 访问数据的查询，**必须**在 WHERE 中附加归属过滤：

```dart
// 二房东只能看到自己合同下的子租赁
'WHERE sl.master_contract_id = ANY($1::uuid[])'
// $1 来自 JWT 解析的 subLandlordScope，不得由客户端传入
```

## 加密字段处理

`id_number`（证件号）/ `phone`（手机号）字段：

```dart
// 写入时：调用 EncryptionService.encrypt()，字段注释必须标注
final encryptedId = await _encryptionService.encrypt(tenant.idNumber); // encrypted: AES-256

// 读取时：API 响应只返回后 4 位
idNumber: row['id_number'] != null ? '****${_decrypt(row['id_number']).substring(_decrypt(row['id_number']).length - 4)}' : null,
```

## 分页（列表查询必须）

```dart
// 所有返回列表的方法签名
Future<PaginatedResult<T>> listXxx({
  int page = 1,
  int pageSize = 20,
  // ...过滤条件
});

// SQL 中
'LIMIT $pageSize OFFSET ${(page - 1) * pageSize}'
```

## 字段命名映射

| 数据库列名 | Dart 字段名 |
|-----------|-----------|
| `created_at` | `createdAt` |
| `tenant_id` | `tenantId` |
| `master_contract_id` | `masterContractId` |

`fromRow()` 方法必须用 `row['snake_case']` 读取，映射为 camelCase 的 Dart 模型。

## 超限拆分信号

`*_repository.dart` 超过 **300 行**或查询方法超过 **10 个** → 提取 `*_query_builder.dart` 封装复杂 SQL 片段，Repository 只组装调用。

## 参考文档

- @file:docs/backend/data_model.md — 表结构与 FK 关系
- @file:docs/backend/RBAC_MATRIX.md — 行级隔离权限矩阵
