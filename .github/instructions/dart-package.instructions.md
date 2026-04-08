---
description: "Use when creating or extending pure Dart calculation packages: rent_escalation_engine or kpi_scorer. Enforces zero external dependencies, money type rules, and mandatory unit test coverage."
applyTo: "backend/packages/**"
---

# 纯 Dart 计算包约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 `backend/packages/` 下计算包的特有规则。

## 零外部依赖（铁律）

`pubspec.yaml` 的 `dependencies` 区块**必须为空**：

```yaml
# ✅ 正确
dependencies:
  # 空

dev_dependencies:
  test: ^1.0.0
  lints: ^4.0.0

# ❌ 禁止引入任何业务包
dependencies:
  dio: ^5.0.0
  freezed: ^2.0.0
  json_serializable: ^6.0.0
```

允许：Dart SDK 内置 `dart:core`、`dart:math`、`dart:collection`。

## 金额类型

```dart
// ✅ 使用 int（分为单位）或 double（元为单位）
final monthlyRent = 45500.00;  // double，元
final depositCents = 13650000; // int，分（精确避免浮点误差时用）

// ❌ 禁止用 String 存储金额
final rent = '45500.00';
```

KPI 分值使用 `double`，值域 `[0.0, 100.0]`，边界用 `clamp(0.0, 100.0)`：

```dart
double score = interpolate(actual, baseline, target);
return score.clamp(0.0, 100.0);  // 不抛异常，直接截断
```

## 包结构约定

```
backend/packages/rent_escalation_engine/
├── lib/
│   ├── rent_escalation_engine.dart   ← 公共 API 导出
│   └── src/
│       ├── models/
│       │   ├── escalation_rule.dart
│       │   └── escalation_type.dart
│       ├── engines/
│       │   ├── fixed_amount_engine.dart
│       │   ├── fixed_rate_engine.dart
│       │   └── mixed_segment_engine.dart
│       └── calculator.dart
└── test/
    ├── fixed_rate_test.dart
    └── mixed_segment_test.dart
```

一个公共函数/类对应一个文件，`lib/` 下各文件粒度清晰，不超过 100 行。

## 单元测试覆盖（必须）

每个公共函数/类必须配套 `test/` 下的测试，`dart test` 全绿才可停止：

```dart
// kpi_scorer 线性插值测试示例
test('正向指标：实际值在基准与满分之间线性插值', () {
  final score = KpiScorer.linearScore(
    actual: 0.91,
    baseline: 0.80,
    target: 0.95,
    isPositive: true,
  );
  expect(score, closeTo(89.33, 0.01));  // 来自 SEED_DATA_SPEC 验算
});
```

验算期望值来自 @file:docs/backend/SEED_DATA_SPEC.md 第十节 KPI 验算样本。

## 租金递增六类型

`rent_escalation_engine` 必须实现以下六种类型（参考 PRD）：

| 类型标识 | 说明 |
|---------|------|
| `fixed_amount` | 固定租金（无递增） |
| `fixed_rate` | 固定比例递增（每期 +X%） |
| `fixed_increment` | 固定金额递增（每期 +X 元） |
| `cpi_linked` | CPI 挂钩递增 |
| `step_rate` | 阶梯式（每阶段不同单价） |
| `mixed_segment` | 混合分段（不同时间段不同类型） |

以及 `mixed_segment` 作为组合容器，参考 @file:docs/backend/SEED_DATA_SPEC.md 第四节合同样本。
