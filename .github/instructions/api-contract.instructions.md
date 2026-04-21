---
description: "Use when implementing any API endpoint (backend) or API call (Flutter data layer / Admin). Enforces field-level contracts from API_CONTRACT_v1.7.md and endpoint inventory from API_INVENTORY_v1.7.md."
applyTo: |
  flutter_app/lib/core/api/**
  flutter_app/lib/**/data/models/**
  flutter_app/lib/**/data/repositories/**
  backend/lib/**/controllers/**
  backend/lib/**/models/**
  backend/lib/**/repositories/**
  backend/lib/**/services/**
  admin/src/api/**
  admin/src/types/**
---

# API 契约约束（PropOS）

> **权威文档**（生成任何 API 相关代码前必须以此为准）：
> - 字段级 Request/Response 定义：[`docs/backend/API_CONTRACT_v1.7.md`](../../../docs/backend/API_CONTRACT_v1.7.md)
> - 端点清单与权限矩阵：[`docs/backend/API_INVENTORY_v1.7.md`](../../../docs/backend/API_INVENTORY_v1.7.md)
>
> 当代码与文档存在冲突时，**以文档为准**，不得自行发明字段名或结构。

---

## 1. 响应信封（不可变规范）

```json
// 成功（单对象）
{ "data": { ...payload } }

// 成功（列表 + 分页）
{ "data": [ ...items ], "meta": { "page": 1, "pageSize": 20, "total": 639 } }

// 失败
{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "人类可读描述" } }
```

- 禁止在信封外添加额外顶层字段（如 `success`, `status`, `result`）
- 错误 `code` 统一 `SCREAMING_SNAKE_CASE`，前端只判断 `code`，不解析 `message`

## 2. 分页约定

| 请求参数 | 默认值 | 上限 |
|---------|-------|------|
| `page` | 1 | — |
| `pageSize` | 20 | 100 |

响应 `meta` 必须包含：`page` / `pageSize` / `total`（总条数）

## 3. 通用错误码

在实现错误处理时，使用以下标准错误码，不得自创：

| 错误码 | HTTP 状态 | 适用场景 |
|--------|----------|---------|
| `UNAUTHORIZED` | 401 | 未登录或 Token 无效 |
| `FORBIDDEN` | 403 | 无操作权限 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION_ERROR` | 400 | 请求参数校验失败 |
| `CONFLICT` | 409 | 资源冲突（如重复创建） |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |

> 业务专属错误码（如 `CONTRACT_NOT_FOUND`、`ACCOUNT_LOCKED`）见 [`docs/backend/ERROR_CODE_REGISTRY.md`](../../../docs/backend/ERROR_CODE_REGISTRY.md)

## 4. 日期时间约定

- **API 传输**：ISO 8601 字符串 `2026-04-05T08:00:00Z`（UTC）
- **纯日期字段**：`2026-04-05`（无时区）
- **Flutter 展示**：`DateFormat('yyyy-MM-dd').format(dt.toLocal())`
- **Admin 展示**：`dayjs(value).format('YYYY-MM-DD')`
- **禁止**在前端做 WALE、逾期天数等业务日期计算，统一由后端返回

## 5. 脱敏规则

- 证件号默认返回 `****XXXX`（仅末4位），字段名 `id_number`
- 手机号默认返回 `***XXXX`（仅末4位），字段名 `phone`
- DTO 模型中必须注释：`// 加密存储，API 层默认脱敏`

## 6. API 路径常量

**禁止在业务代码中硬编码路径字符串**，统一从常量文件引用：

- Flutter：`flutter_app/lib/core/constants/api_paths.dart`
- Admin：`admin/src/constants/api_paths.ts`

新增接口时同步在常量文件中添加对应常量。

## 7. 认证头

所有需要鉴权的请求必须携带：

```
Authorization: Bearer <access_token>
```

Flutter `ApiClient` 已在拦截器中自动注入，Repository 实现层无需手动设置。

## 8. 实现新接口的检查清单

在生成任何接口的后端或前端代码前，先完成以下确认：

- [ ] 在 `API_CONTRACT_v1.7.md` 中找到该端点的字段级定义
- [ ] 在 `API_INVENTORY_v1.7.md` 中确认权限要求（`applyTo` 角色）
- [ ] DTO 字段名与契约文档完全一致（`snake_case`）
- [ ] 响应使用标准信封格式
- [ ] 错误码在 `ERROR_CODE_REGISTRY.md` 中已注册
- [ ] 路径常量已添加到对应常量文件
