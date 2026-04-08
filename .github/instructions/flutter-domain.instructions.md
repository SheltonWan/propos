---
description: "Use when writing or editing the Flutter domain layer — freezed models, Repository abstract interfaces, or UseCase classes. Enforces pure Dart, no Flutter SDK, and correct dependency direction."
applyTo: "frontend/lib/**/domain/**"
---

# Flutter Domain 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 domain 层特有强制规则。

## 纯 Dart，绝对不含 Flutter SDK

```dart
// ❌ 禁止 — domain 层任何文件都不得出现
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// ✅ 只允许
import 'dart:core';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
```

验证方式：`dart run` 在 Dart VM 下运行 domain 层测试，不应依赖 `flutter test`。

## freezed 数据类（模型）

```dart
@freezed
class Contract with _$Contract {
  const factory Contract({
    required String id,
    required ContractStatus status,
    required DateTime startDate,     // UTC，不含时区转换
    String? idNumberMasked,          // 脱敏后的证件号（****1234 格式）
  }) = _Contract;

  factory Contract.fromJson(Map<String, dynamic> json) => _$ContractFromJson(json);
}

// 枚举：@JsonValue 必须与后端 snake_case 字符串一致
enum ContractStatus {
  @JsonValue('active') active,
  @JsonValue('expired') expired,
  @JsonValue('terminated') terminated,
  @JsonValue('expiring_soon') expiringSoon,
}
```

## Repository 抽象接口

```dart
// ✅ 只有方法签名，没有任何实现
abstract class ContractRepository {
  Future<PaginatedResult<Contract>> listContracts({
    int page = 1,
    int pageSize = 20,
    ContractStatus? status,
  });

  Future<Contract> getContract(String id);
  Future<Contract> createContract(CreateContractInput input);
}

// ❌ 禁止在 domain 层出现任何实现代码（Dio、HTTP、本地缓存等）
```

## UseCase 注入规则

```dart
class GetContractDetailUseCase {
  final ContractRepository _repository;  // 注入接口，不是实现类

  GetContractDetailUseCase(this._repository);

  Future<Contract> execute(String id) => _repository.getContract(id);
}
```

## 日期时间

- 模型字段类型为 `DateTime`（UTC）
- **禁止 `DateTime.now()`** — 通过注入 `Clock` 接口获取当前时间（便于测试）
- API 返回的 ISO 8601 字符串在 `data/` 层解析，domain 层只消费 `DateTime`

## 不允许的依赖

- `data/` 层任何内容
- `presentation/` 层任何内容
- HTTP 库（`dio`、`http`）
- `Either<Failure, T>`（本项目不使用，直接抛 `ApiException`）

## 参考文档

- @file:docs/backend/data_model.md — 实体字段定义（与后端模型保持一致）
- @file:docs/backend/API_CONTRACT_v1.7.md — JSON 字段名与枚举值
