---
description: "Use when performing a security review, auditing authentication code, checking for SQL injection, reviewing RBAC middleware, or verifying IDOR protections. Covers OWASP Top 10 checks specific to PropOS."
---

# 安全审查清单（PropOS 专项）

> 按此清单逐条检查，不得跳过。全局规则见 `.github/copilot-instructions.md`。

## 1. SQL 注入防护

```bash
# 检查所有 SQL 是否使用参数化，无字符串拼接
grep -rn "execute\|query" backend/lib --include="*.dart" | grep -v '\$[0-9]'
# 期望：无结果（即所有 SQL 都含 $1/$2 占位符）
```

重点检查：搜索条件、动态 ORDER BY 字段名、LIKE 模糊查询。

## 2. JWT 安全

- 算法固定为 `HS256`，验证时设置 `only: ['HS256']`，**禁止 `alg: none`**
- Token 验证失败返回 401，不泄露内部错误信息（如 `jwt malformed`）
- `JWT_SECRET` 必须来自环境变量（≥32位），不得硬编码在代码中

## 3. IDOR（越权访问）

所有 `GET/PUT/DELETE /api/xxx/:id` 端点：

```dart
// 必须验证资源归属当前请求者
final contract = await _repository.getById(id);
if (contract.tenantId != currentUser.tenantId && !currentUser.hasRole('admin')) {
  throw AppException('FORBIDDEN', '无访问权限', 403);
}
```

二房东越权测试：

```bash
# 使用二房东A的JWT，请求二房东B的合同数据，期望返回 [] 或 403
curl -H "Authorization: Bearer <sub_landlord_A_token>" \
  "http://localhost:8080/api/subleases?masterContractId=<B_contract_id>"
```

## 4. 证件号/手机号保护

```bash
# 检查加密存储
grep -rn "idNumber\|id_number" backend/lib --include="*.dart"
# 验证：存入时调用 encrypt()，读出时只返回后4位（****格式）
```

响应中**禁止**出现完整证件号，包括日志。

## 5. CORS 配置

```dart
// 生产环境必须限制来源
// CORS_ORIGINS 不得为 '*'
// ✅ CORS_ORIGINS=https://app.propos.example.com,https://admin.propos.example.com
```

## 6. 环境变量完整性

启动时检查以下变量缺失即拒绝启动（参考 `app_config.dart`）：

`DATABASE_URL` / `JWT_SECRET` / `JWT_EXPIRES_IN_HOURS` / `FILE_STORAGE_PATH` / `ENCRYPTION_KEY` / `APP_PORT`

## 7. 审计日志完整性

以下四类操作必须在 `audit_logs` 中有记录（`before/after` 均非 null）：

```sql
SELECT action, COUNT(*) FROM audit_logs
WHERE action IN ('contract.update', 'invoice.write_off', 'user.role_update', 'sublease.submit')
GROUP BY action;
-- 每类都应当有记录
```

## 8. 文件上传安全

- 上传类型白名单：`image/jpeg`, `image/png`, `application/pdf`
- 文件大小上限读取自环境变量 `MAX_UPLOAD_SIZE_MB`（默认 10MB）
- 存储路径不含用户输入（使用 UUID），禁止路径穿越（`../`）

## 参考文档

- @file:docs/backend/RBAC_MATRIX.md — 各端点权限矩阵
- @file:docs/backend/ERROR_CODE_REGISTRY.md — 安全相关错误码
