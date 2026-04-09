# propos_rent_escalation_engine

PropOS 内部纯 Dart 计算包 · 租金递增引擎

支持 **6 种递增规则**与**多阶段混合分段**，零外部依赖，可在 Dart VM（后端）和 Flutter（客户端离线预览）中复用。

---

## 特性

| 特性 | 说明 |
|------|------|
| 零外部依赖 | `dependencies: {}` — 仅 Dart core；可在 Dart VM 和 Flutter 双端复用 |
| 6 种递增规则 | 固定比例 / 固定金额 / 阶梯 / CPI 联动 / 每 N 年 / 装修免租 |
| 多阶段混合分段 | `RentEscalationPhase` 容器支持任意阶段组合 + 相位偏移计算 |
| 单月快算 | `calculateRentForMonth` — 对任意目标月一次返回月租金额 |
| 全周期列表 | `generateRentSchedule` / `generateScheduleFromPhases` — 返回逐月 `MonthlyRent` 列表 |
| Sealed class | Dart 3.0 sealed class + exhaustive switch，编译期保证所有规则覆盖 |
| 22 个测试 | 每种规则 ≥ 3 用例，含跨类型混合分段与边界回退 |

---

## 安装

该包通过 `path` 依赖引用，不发布到 pub.dev：

```yaml
# backend/pubspec.yaml 或 frontend/pubspec.yaml
dependencies:
  propos_rent_escalation_engine:
    path: packages/rent_escalation_engine   # 后端路径
    # 或 Flutter 端路径：../backend/packages/rent_escalation_engine
```

---

## 核心 API

### `RentCalculator`

所有计算方法均为纯函数，无副作用，线程安全。

```dart
import 'package:propos_rent_escalation_engine/propos_rent_escalation_engine.dart';

const calc = RentCalculator();
```

#### `calculateRentForMonth` — 单规则单月计算

```dart
double calculateRentForMonth({
  required RentEscalationRule rule,
  required double baseMonthlyRent,  // 基准月租（元）
  required DateTime contractStart,  // 合同起租日（UTC）
  required DateTime targetMonth,    // 目标月（UTC，取年月，忽略日）
})
```

#### `generateRentSchedule` — 单规则全周期列表

```dart
List<MonthlyRent> generateRentSchedule({
  required RentEscalationRule rule,
  required double baseMonthlyRent,
  required DateTime contractStart,
  required DateTime contractEnd,    // 合同到期日（UTC）
})
```

#### `compute` — 多阶段混合单月计算

```dart
double compute({
  required List<RentEscalationPhase> phases,  // 按 startMonth 升序排列
  required double baseMonthlyRent,
  required DateTime contractStart,
  required DateTime targetMonth,
})
```

> 若目标月不在任何阶段内，回退为 `baseMonthlyRent`。

#### `generateScheduleFromPhases` — 多阶段全周期列表

```dart
List<MonthlyRent> generateScheduleFromPhases({
  required List<RentEscalationPhase> phases,
  required double baseMonthlyRent,
  required DateTime contractStart,
  required DateTime contractEnd,
})
```

---

## 6 种递增规则

### 1. `FixedRateRule` — 固定比例递增

每 `intervalYears` 年按 `percent` 比例递增，复利计算。

```dart
// 每年递增 5%，3 年合同：月 1-12 → 1000，月 13-24 → 1050，月 25-36 → 1102.5
const rule = FixedRateRule(percent: 0.05);   // intervalYears 默认为 1

// 每 2 年递增 10%
const rule2 = FixedRateRule(percent: 0.10, intervalYears: 2);
```

**计算公式**：`baseRent × (1 + percent) ^ floor((monthIndex - 1) / (intervalYears × 12))`

---

### 2. `FixedAmountRule` — 固定金额递增

每 `intervalYears` 年月租加 `incrementPerMonth` 元（调用方负责将单价 × 面积换算后传入）。

```dart
// 每年月租增加 200 元
const rule = FixedAmountRule(incrementPerMonth: 200.0);

// 每 2 年月租增加 500 元
const rule2 = FixedAmountRule(incrementPerMonth: 500.0, intervalYears: 2);
```

**计算公式**：`baseRent + incrementPerMonth × floor((monthIndex - 1) / (intervalYears × 12))`

---

### 3. `SteppedRule` — 阶梯式递增

按 `StepSegment` 列表分段，每段定义从第几个月起的固定月租。

```dart
const rule = SteppedRule(steps: [
  StepSegment(startMonth: 0,  monthlyRent: 5000.0),  // 第 1–12 月
  StepSegment(startMonth: 12, monthlyRent: 6000.0),  // 第 13–24 月
  StepSegment(startMonth: 24, monthlyRent: 7000.0),  // 第 25 月起
]);
```

> `startMonth` 为相对合同起始的月偏移（0 表示第 1 个月）。最后一段无上限，延续至合同结束。

---

### 4. `CpiLinkedRule` — CPI 联动递增

每年按 `cpiByYear` 表中对应年度系数调整，**复合乘积**计算。

```dart
// 第 1 年系数 1.03，第 2 年系数 1.025，第 3 年系数 1.04
const rule = CpiLinkedRule(cpiByYear: {
  1: 1.03,
  2: 1.025,
  3: 1.04,
});
```

**计算公式**：`baseRent × Π(cpiByYear[y])` — 对合同第 1 到当前年的前 y-1 年系数连乘  
（当年系数在年末生效，不计入当年月租）

> 若 `cpiByYear` 中无当前年的记录，当年复合积不变（即维持上一年系数）。

---

### 5. `EveryNYearsRule` — 每 N 年固定比例递增

与 `FixedRateRule` 语义一致，但强调"每满 N 年"触发一次，适用于合同约定节点不按自然年的场景。

```dart
// 每满 3 年递增 15%
const rule = EveryNYearsRule(intervalYears: 3, percent: 0.15);
```

---

### 6. `PostRenovationRule` — 装修免租期后递增

先享受 `freeRentMonths` 个月免租（月租 = 0），之后以 `baseMonthlyRent` 为基准按 `followUpRule` 递增；`followUpRule` 为 `null` 时免租期后保持 `baseMonthlyRent` 不变。

```dart
// 3 个月免租，之后按每年 5% 递增，基准月租 8000 元
const rule = PostRenovationRule(
  freeRentMonths: 3,
  baseMonthlyRent: 8000.0,
  followUpRule: FixedRateRule(percent: 0.05),
);
```

---

## 多阶段混合分段

当一份合同的不同阶段采用不同递增策略时，使用 `RentEscalationPhase` 容器：

```dart
final phases = [
  // 第 1–24 月：固定比例递增 5%
  FixedRatePhase(
    startMonth: 1,
    endMonth: 24,
    rule: FixedRateRule(percent: 0.05),
  ),
  // 第 25 月起：CPI 联动
  CpiLinkedPhase(
    startMonth: 25,
    rule: CpiLinkedRule(cpiByYear: {1: 1.03, 2: 1.025}),
  ),
];

const calc = RentCalculator();

// 单月计算
final rent = calc.compute(
  phases: phases,
  baseMonthlyRent: 10000.0,
  contractStart: DateTime.utc(2024, 1, 1),
  targetMonth: DateTime.utc(2026, 3, 1),  // 第 27 月 → CPI 阶段
);

// 全周期列表
final schedule = calc.generateScheduleFromPhases(
  phases: phases,
  baseMonthlyRent: 10000.0,
  contractStart: DateTime.utc(2024, 1, 1),
  contractEnd: DateTime.utc(2026, 12, 31),
);
```

**Phase 容器规则**：
- `startMonth` / `endMonth` 均为相对合同第 1 个月的月序号（从 1 开始）
- `endMonth` 省略（`null`）表示延续至合同结束
- 各阶段应连续衔接不重叠，按 `startMonth` 升序排列
- 每个阶段内的月序号从该阶段 `startMonth` 重置（相位偏移），规则计算以阶段内月序为准

---

## `MonthlyRent` 数据类

```dart
class MonthlyRent {
  final int monthIndex;    // 合同月序号（从 1 开始）
  final DateTime month;   // 月份（UTC，日固定为 1）
  final double amount;    // 当月应收月租（元）
}
```

---

## 完整示例

```dart
import 'package:propos_rent_escalation_engine/propos_rent_escalation_engine.dart';

void main() {
  const calc = RentCalculator();
  final start = DateTime.utc(2024, 4, 1);
  final end   = DateTime.utc(2027, 3, 31);

  // 单规则：每年递增 5%，基准月租 10000 元
  final schedule = calc.generateRentSchedule(
    rule: const FixedRateRule(percent: 0.05),
    baseMonthlyRent: 10000.0,
    contractStart: start,
    contractEnd: end,
  );

  for (final m in schedule) {
    print('${m.month.year}-${m.month.month.toString().padLeft(2, '0')} '
          '第${m.monthIndex}月  ¥${m.amount.toStringAsFixed(2)}');
  }
}
```

输出节选：
```
2024-04 第1月  ¥10000.00
...
2025-04 第13月 ¥10500.00
...
2026-04 第25月 ¥11025.00
```

---

## 运行测试

```bash
cd backend/packages/rent_escalation_engine
dart test
# 22 tests passed
```

---

## 架构约束

- 本包为 **PropOS 架构约束 §5** 规定的零依赖核心计算包，**禁止**引入任何 pub.dev 外部依赖
- 租金金额使用 `double`（元为单位），调用方负责显示时的精度格式化
- 所有 `DateTime` 参数应传入 UTC 时间（`DateTime.utc(...)`），避免时区漂移影响月序计算
- 本包不含日志、HTTP、数据库访问等副作用，适合在单元测试中直接调用
