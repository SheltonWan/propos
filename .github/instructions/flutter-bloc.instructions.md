---
description: "Use when writing or editing Flutter BLoC or Cubit files. Enforces domain-only imports, freezed sealed states, error handling pattern, and complexity limits."
applyTo: ["frontend/lib/**/bloc/**", "frontend/lib/**/cubit/**"]
---

# Flutter BLoC / Cubit 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 BLoC/Cubit 层特有强制规则。

## 依赖方向（最容易被违反）

```dart
// ✅ 只允许 import domain 层
import 'package:propos/features/contract/domain/repositories/contract_repository.dart';
import 'package:propos/features/contract/domain/usecases/get_contract_detail_usecase.dart';

// ❌ 禁止 import data 层实现
import 'package:propos/features/contract/data/repositories/http_contract_repository.dart';

// ❌ 禁止 import flutter/material.dart（BLoC 是纯业务逻辑）
import 'package:flutter/material.dart';
```

## State 使用 freezed sealed union（四变体必须完整）

```dart
@freezed
sealed class ContractState with _$ContractState {
  const factory ContractState.initial() = _Initial;
  const factory ContractState.loading() = _Loading;
  const factory ContractState.loaded(PaginatedResult<Contract> result) = _Loaded;
  const factory ContractState.error(String message) = _Error;
}

// ❌ 禁止散落标志位
// bool isLoading = false;
// bool hasError = false;
// String? errorMsg;
```

## 通过构造函数注入 Repository 接口

```dart
class ContractListBloc extends Bloc<ContractEvent, ContractState> {
  final ContractRepository _repository;  // 接口，不是实现类

  ContractListBloc({required ContractRepository repository})
      : _repository = repository,
        super(const ContractState.initial());
}
```

## 错误处理模式

```dart
on<LoadContracts>((event, emit) async {
  emit(const ContractState.loading());
  try {
    final result = await _repository.listContracts(page: event.page);
    emit(ContractState.loaded(result));
  } on ApiException catch (e) {
    emit(ContractState.error(e.message));  // 不使用 Either<>
  }
});
```

## 禁止 DateTime.now()

```dart
// ❌
final today = DateTime.now();

// ✅ 注入 Clock 接口（便于测试中 mock 时间）
final Clock _clock;
final today = _clock.now();
```

## 单元测试（必须配套）

```dart
// 每个 BLoC 必须有对应 test 文件
// test/features/contract/bloc/contract_list_bloc_test.dart

blocTest<ContractListBloc, ContractState>(
  'emits [loading, loaded] when LoadContracts succeeds',
  build: () => ContractListBloc(repository: MockContractRepository()),
  act: (bloc) => bloc.add(const LoadContracts()),
  expect: () => [isA<_Loading>(), isA<_Loaded>()],
);
```

使用 `bloc_test` + `mocktail`。`MockContractRepository extends Mock implements ContractRepository`。

## 超限拆分信号

`*_bloc.dart` 超过 **200 行** 或 `on<>` 超过 **5 个** → 按职责拆分独立 Cubit：
- 列表用 `XxxListBloc`
- 表单用 `XxxFormCubit`
- 详情用 `XxxDetailCubit`
