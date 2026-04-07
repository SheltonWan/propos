---
mode: agent
description: 创建 Flutter 前端的 BLoC/Cubit 层。Use when building lib/features/<module>/presentation/bloc/.
---

# Flutter BLoC 层实现规范

@file:docs/ARCH.md
@file:.github/copilot-instructions.md

## 当前任务

{{TASK}}

## 目录约定

目标路径：`lib/features/<module>/presentation/bloc/`，文件遵循：
```
<name>_bloc.dart / <name>_cubit.dart
<name>_event.dart   ← 仅 BLoC 需要
<name>_state.dart
```

## 强制约束

### 依赖方向（最关键）
- BLoC/Cubit **只 import domain 层接口**（`Repository` 抽象类 / `UseCase`）
- **禁止直接 import** `data/` 层（`HttpXxxRepository`、`MockXxxRepository`）
- **禁止 import** `flutter/material.dart`（BLoC 是纯业务逻辑，不含 UI 依赖）

### State 定义
- 使用 `@freezed` sealed union，必须包含四个变体：`initial` / `loading` / `loaded` / `error`
- `error` 变体携带 `String message`（来自 `ApiException.message`）
- 禁止使用 `bool isLoading` / `bool hasError` 这类散落标志位

### BLoC 实现
- 通过构造函数注入 Repository **接口**，不在 BLoC 内部实例化 Repository
- `try/catch` 捕获异常后 `emit(State.error(e.message))`，不使用 `Either<>`
- 不在 BLoC 中调用 `DateTime.now()`，通过注入 `Clock` 获取时间

### 文件复杂度控制（超限时拆分）
- `*_bloc.dart` > 200 行 或 `on<>` 超过 5 个 → 按职责拆出独立 Cubit
- 例：列表用 `XxxListBloc`，表单用 `XxxFormCubit`，详情用 `XxxDetailCubit`

### 单元测试（必须）
- 使用 `bloc_test` + `mocktail`
- 覆盖：初始状态 / loading → loaded / loading → error 三个基本场景
- Mock Repository 接口用 `mocktail` 的 `MockXxxRepository extends Mock implements XxxRepository`

## 禁止事项

- 不在 BLoC 中进行 HTTP 调用（通过 Repository 接口隔离）
- 不在 BLoC 中进行 UI 操作（如 `Navigator.push`）
- 不使用 `setState` 或 `StatefulWidget` 模式替代 BLoC
