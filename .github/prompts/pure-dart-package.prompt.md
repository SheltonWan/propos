---
mode: agent
description: 创建纯 Dart 计算包（租金递增引擎 / KPI 打分器）。Use when creating or extending packages under backend/packages/.
---

# 纯 Dart 计算包开发规范

@file:docs/ARCH.md
@file:docs/backend/data_model.md
@file:docs/backend/SEED_DATA_SPEC.md
@file:docs/backend/REVENUE_SHARE_SPEC.md

## 当前任务

{{TASK}}

## 强制约束（违反则拒绝生成）

1. **零外部依赖**：`pubspec.yaml` 的 `dependencies` 区块必须为空，只允许 `dev_dependencies` 中有 `test: ^1.0.0`。
2. **纯 Dart**：禁止 `import 'package:flutter/...` 或任何 Flutter SDK 依赖。
3. **目录对齐**：
   - `rent_escalation_engine` → `backend/packages/rent_escalation_engine/lib/src/`
   - `kpi_scorer` → `backend/packages/kpi_scorer/lib/src/`
4. **测试覆盖**：每个公共函数/类配套 `test/` 下的单元测试，`dart test` 全绿方可停止。
5. **命名规范**：类名 PascalCase，文件名 snake_case，枚举值 camelCase。
6. **Money 类型**：租金相关值使用 `int`（分为单位）或 `double`（元为单位，双精度），**不使用** `String`。
7. KpiScorer 输出值域 **[0.0, 100.0]**，边界值 clamp 处理，不抛异常。

## 禁止事项

- 不生成 ORM 代码
- 不引入 `dio`、`http`、`freezed`、`json_serializable` 等业务包
- 不在 `lib/` 下生成测试代码（测试只在 `test/` 目录）
