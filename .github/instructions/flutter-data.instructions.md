---
description: "Use when writing or editing the Flutter data layer — HTTP Repository implementations or Mock Repository implementations. Enforces ApiClient usage, api_paths constants, ApiException wrapping, and response envelope parsing."
applyTo: "frontend/lib/**/data/**"
---

# Flutter Data 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 data 层特有强制规则。

## 使用项目统一 ApiClient（禁止自建 Dio 实例）

```dart
// ✅ 正确 — 注入已配置 JWT Bearer 拦截器的 ApiClient
class HttpContractRepository implements ContractRepository {
  final ApiClient _client;  // 来自 lib/shared/network/api_client.dart
  HttpContractRepository(this._client);
}

// ❌ 禁止 — 自建 Dio 实例绕过统一拦截器
final dio = Dio();
```

## API 路径使用常量（禁止硬编码字符串）

```dart
// ✅ 正确
import 'package:propos/shared/constants/api_paths.dart';

final response = await _client.get(ApiPaths.contracts);
final response = await _client.get('${ApiPaths.contracts}/$id');

// ❌ 禁止 — 路径字符串散落在各 Repository 中
final response = await _client.get('/api/contracts');
```

所有 API 路径常量必须在 `lib/shared/constants/api_paths.dart` 中统一定义。

## 响应信封解析

```dart
// 后端统一返回 {"data": ..., "meta": {...}}
final envelope = response.data as Map<String, dynamic>;
final items = (envelope['data'] as List).map((e) => Contract.fromJson(e)).toList();
final meta = PaginationMeta.fromJson(envelope['meta'] as Map<String, dynamic>);
return PaginatedResult(items: items, meta: meta);

// 单对象
final contract = Contract.fromJson(envelope['data'] as Map<String, dynamic>);
```

## 异常包装（禁止透传原始 DioException）

```dart
@override
Future<PaginatedResult<Contract>> listContracts({int page = 1, int pageSize = 20}) async {
  try {
    final response = await _client.get(ApiPaths.contracts, queryParameters: {'page': page, 'pageSize': pageSize});
    // ... 解析
  } on DioException catch (e) {
    // ✅ 统一包装为 ApiException
    throw ApiException.fromDioException(e);
    // ❌ 禁止 rethrow 或 throw e（透传原始 DioException）
  }
}
```

## 日期字段解析

```dart
// ISO 8601 → UTC DateTime
startDate: DateTime.parse(json['start_date'] as String).toUtc(),
```

## Mock 实现规范

`mock_*_repository.dart` 必须：
- 实现与 HTTP 版本相同的 `ContractRepository` 接口
- 包含至少 3 种典型状态的样本数据（如：`active` / `expiring_soon` / `expired`）
- 样本数据参考 @file:docs/backend/SEED_DATA_SPEC.md

```dart
// get_it 注册时切换
// --dart-define=USE_MOCK=true 时注册 Mock 实现
```

## 依赖方向

- data 层可以 import `domain/` 层
- **禁止** domain 层 import data 层
- **禁止** data 层 import `presentation/` 任何内容

## 参考文档

- @file:docs/backend/API_INVENTORY_v1.7.md — 所有接口路径与参数
- @file:docs/backend/API_CONTRACT_v1.7.md — 响应字段定义
