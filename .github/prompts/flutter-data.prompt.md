---
mode: agent
description: 创建 Flutter 前端的 data 层（HTTP Repository 实现 + Mock 实现）。Use when building lib/features/<module>/data/.
---

# Flutter Data 层实现规范

@file:docs/ARCH.md
@file:.github/copilot-instructions.md
@file:docs/backend/API_INVENTORY_v1.7.md

## 当前任务

{{TASK}}

## 目录约定

目标路径：`lib/features/<module>/data/repositories/`，包含：
```
http_<name>_repository.dart  ← 真实 HTTP 实现（Dio）
mock_<name>_repository.dart  ← 内存 Mock 实现（用于开发/测试）
```

## 强制约束

### HTTP 实现
- 使用项目统一的 `ApiClient`（Dio 实例，含 JWT Bearer 拦截器），不自建 Dio 实例
- 请求路径使用 `lib/shared/constants/api_paths.dart` 中定义的常量，禁止硬编码字符串 `/api/...`
- 分页参数：`page`（从 1 开始）+ `pageSize`（默认 `kDefaultPageSize = 20`）
- 响应解析：从 `{"data": ..., "meta": ...}` 信封中取值，`meta` 提取到 `PaginatedResult<T>` 中
- **异常包装**：捕获 `DioException` 后统一包装为 `ApiException`，禁止向上透传原始 `DioException`
- 日期字段：从 ISO 8601 字符串解析，`DateTime.parse(...).toUtc()`

### Mock 实现
- 实现与 HTTP 版本相同的 Repository 接口
- 包含至少 3 种状态的样本数据（如：已租/空置/即将到期）
- `get_it` 注册时通过 `--dart-define=USE_MOCK=true` 切换

### 依赖方向
- data 层可以 import domain 层；**禁止** domain 层 import data 层
- data 层禁止 import `presentation/` 层任何内容

## 禁止事项

- 不在 data 层写业务计算逻辑
- 不直接返回 `Map<String, dynamic>`，必须反序列化为 domain 层模型
- 不新增 `api_paths.dart` 以外的 URL 常量
