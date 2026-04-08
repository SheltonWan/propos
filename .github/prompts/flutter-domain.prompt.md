---
mode: agent
description: 创建 Flutter 前端的 domain 层（freezed 模型 + Repository 抽象接口 + UseCase）。Use when building lib/features/<module>/domain/.
---

# Flutter Domain 层实现规范

@file:docs/ARCH.md
@file:.github/copilot-instructions.md
@file:docs/backend/data_model.md
@file:docs/backend/API_CONTRACT_v1.7.md

## 当前任务

{{TASK}}

## 目录约定

目标路径：`lib/features/<module>/domain/`，包含：
```
models/       ← @freezed 不可变数据类（纯 Dart，无 Flutter SDK）
repositories/ ← Repository 抽象接口（abstract class，只含方法签名）
usecases/     ← UseCase 类（注入 Repository 接口，封装单一业务操作）
```

## 强制约束

### 纯 Dart，无 Flutter SDK
- **禁止** `import 'package:flutter/material.dart'` 或任何 `flutter/` 路径
- domain 层必须能在 **纯 Dart VM** 环境下运行和测试
- 日期时间使用 `DateTime`（UTC），不依赖 `DateTime.now()`，通过注入 `Clock` 接口

### 数据类（模型）
- 所有模型使用 `@freezed` 生成不可变类
- 枚举值必须与后端 API 的 `snake_case` 字符串对应（使用 `@JsonValue('...')` 标注）
- 证件号字段（`idNumber`）在 domain 模型中为 `String?`（可能脱敏为仅 4 位）

### Repository 抽象接口
- 只有 `abstract class`，**不含任何实现代码**
- 方法签名返回 `Future<T>` 或 `Stream<T>`，不返回 `Either<>`（项目规模不需要）
- 分页方法参数：`{int page = 1, int pageSize = 20}`

### UseCase
- 构造函数注入 Repository **接口**，不直接引用 `Http*Repository` 实现
- 一个文件只包含一个 UseCase 类

## 禁止事项

- 不在 domain 层 import `data/` 层的任何内容
- 不使用 `Either<Failure, T>`（改为直接抛 `ApiException`）
- 不在 domain 层处理 HTTP / JSON 逻辑
