---
mode: agent
description: 创建后端 Dart/Shelf 模块的四层结构（Model + Repository + Service + Controller）。Use when implementing any backend module under backend/lib/modules/.
---

# 后端模块四层实现规范

@file:docs/ARCH.md
@file:docs/backend/data_model.md
@file:.github/copilot-instructions.md

## 当前任务

{{TASK}}

## 目录约定

目标路径：`backend/lib/modules/<module>/`，必须包含：
```
models/        ← @freezed 数据类，字段名 camelCase
repositories/  ← 原生 SQL，Repository 接口 + 实现
services/      ← 业务逻辑，调用 Repository
controllers/   ← HTTP 路由处理，调用 Service
```

## 强制约束（每条都必须检查）

### SQL 层
- **禁止 ORM**：所有数据库访问使用 `postgres` 包 + 原生 SQL
- **参数化查询**：SQL 中禁止字符串拼接，一律使用 `$1,$2...` 占位符
- **分页**：列表查询必须支持 `LIMIT $pageSize OFFSET $offset`
- **字段名**：数据库列名 `snake_case`，Dart 字段名 `camelCase`（JSON 序列化自动转换）
- **证件号/手机号**：存储前 AES-256 加密，读取后 API 响应仅返回后 4 位，字段注释 `// encrypted: AES-256`

### Service 层
- **禁止直接 return Response**：Service 抛出 `AppException(code, message, statusCode)`，由 `error_handler.dart` 统一处理
- 错误 code 使用 `SCREAMING_SNAKE_CASE`（如 `CONTRACT_NOT_FOUND`）

### Controller 层
- 禁止在 Controller 包含任何业务逻辑，只做参数解析 → 调用 Service → 返回 JSON
- 响应格式严格遵循信封：`{"data": ..., "meta": {...}}` 或 `{"error": {"code": "...", "message": "..."}}`

### 安全
- 所有端点必须通过 RBAC 中间件（`rbac_middleware`）验证角色
- 二房东相关查询在 Repository SQL 中强制附加 `WHERE master_contract_id = ANY($subLandlordScope)` 行级过滤

## 禁止超前实现

Phase 2 以外的功能仅保留接口桩，不实现具体逻辑。
