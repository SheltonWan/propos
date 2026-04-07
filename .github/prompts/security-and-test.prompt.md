---
mode: agent
description: 执行安全审查、集成测试或性能测试任务。Use when running security review, integration tests, or performance profiling.
---

# 安全与测试审查规范

@file:docs/ARCH.md
@file:.github/copilot-instructions.md
@file:docs/backend/data_model.md

## 当前任务

{{TASK}}

## 安全审查清单（逐条验证）

### SQL 注入防护
- `grep -r "execute\|query" backend/lib --include="*.dart"` 确认所有 SQL 使用参数化（`$1,$2...`），无字符串拼接
- 重点检查：搜索条件、动态 ORDER BY、LIMIT 参数是否安全

### JWT 安全
- `token_service.dart`：算法固定为 `HS256`，验证时设置 `only: ['HS256']`，禁止 `alg: none`
- Token 验证失败返回 401，不泄露内部错误信息

### IDOR（跨用户访问）
- 所有 `GET /api/xxx/:id` 端点：验证资源归属当前用户/权限范围，不符合返回 403
- 二房东 JWT 请求：`subLandlordScope` 必须在 SQL 层强制过滤，不依赖应用层

### 证件号保护
- `grep -r "idNumber\|id_number" backend/lib --include="*.dart"` 确认：
  1. 存储前调用加密函数
  2. 查询结果 API 响应中仅末 4 位（`****1234` 格式）
  3. 字段有 `// encrypted: AES-256` 注释

### CORS
- 生产环境 `CORS_ORIGINS` 不为 `*`，限制为实际域名

### 行级隔离测试
```bash
# 使用二房东A的JWT，请求二房东B的合同数据，必须返回空数组或403
curl -H "Authorization: Bearer <sub_landlord_A_token>" \
  "http://localhost:8080/api/subleases?masterContractId=<B_contract_id>"
```

## 性能测试要点

- 账单批量生成：`time curl -X POST /api/invoices/generate`，目标 < 30 秒（639 条）
- 并发压测：`hey -n 500 -c 50 http://localhost:8080/api/dashboard`，P99 < 3 秒
- 慢查询：`pg_stat_statements` 找出 Top 5 + `EXPLAIN ANALYZE` 优化
- Flutter DevTools：Dashboard 首屏帧率 ≥ 60fps 无掉帧

## 审计日志完整性

确认以下四类操作都有 `audit_logs` 记录（含 before/after JSON 非 null）：
1. 合同变更（状态流转/续签/终止）
2. 账单核销（payment_allocations）
3. 权限变更（user role update）  
4. 二房东数据提交（sublease create/update）
