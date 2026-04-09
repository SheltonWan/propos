# propos_kpi_scorer

PropOS 内部纯 Dart 计算包 · KPI 线性插值打分引擎

对物业运营 KPI 指标进行**三段线性插值打分**，支持**正向**（越高越好）和**反向**（越低越好）两类指标，零外部依赖，可在 Dart VM（后端）和 Flutter（客户端离线预览）中复用。

---

## 特性

| 特性 | 说明 |
|------|------|
| 零外部依赖 | `dependencies: {}` — 仅 Dart core；可在 Dart VM 和 Flutter 双端复用 |
| 正/反向指标 | `KpiDirection.positive / negative`，轴对称插值，统一接口 |
| 三段线性插值 | 满分段（100）/ 及格段（60-100）/ 零分段（0-60）/ 不及格（0） |
| 加权综合总分 | `KpiScore.totalScore = Σ(rawScore × weight)`，clamp 至 [0.0, 100.0] |
| 双接口兼容 | `scoreMetrics`（新接口，推荐）+ `score`（旧接口，向后兼容） |
| SEED 数据验算 | 与 `SEED_DATA_SPEC §10` 样本完全吻合（K01=89.33、K08=88.00、综合=94.03） |
| 21 个测试 | 覆盖正/反向各段边界、权重加总、clamp 限幅 |

---

## 安装

该包通过 `path` 依赖引用，不发布到 pub.dev：

```yaml
# backend/pubspec.yaml 或 frontend/pubspec.yaml
dependencies:
  propos_kpi_scorer:
    path: packages/kpi_scorer             # 后端路径
    # 或 Flutter 端路径：../backend/packages/kpi_scorer
```

---

## 打分公式

### 正向指标（越高越好，`KpiDirection.positive`）

阈值关系：`fail < pass < full`

| actual 范围 | 得分 |
|------------|------|
| `actual ≥ full` | **100** |
| `pass ≤ actual < full` | `60 + (actual − pass) / (full − pass) × 40` |
| `fail < actual < pass` | `(actual − fail) / (pass − fail) × 60` |
| `actual ≤ fail` | **0** |

### 反向指标（越低越好，`KpiDirection.negative`）

阈值关系：`full < pass < fail`

| actual 范围 | 得分 |
|------------|------|
| `actual ≤ full` | **100** |
| `full < actual ≤ pass` | `60 + (pass − actual) / (pass − full) × 40` |
| `pass < actual < fail` | `(fail − actual) / (fail − pass) × 60` |
| `actual ≥ fail` | **0** |

> 所有 `rawScore` 均 clamp 至 `[0.0, 100.0]`，不抛异常。

---

## 核心 API

### `KpiScorer`

```dart
import 'package:propos_kpi_scorer/propos_kpi_scorer.dart';

const scorer = KpiScorer();
```

#### `scoreMetrics` — 推荐接口

```dart
KpiScore scoreMetrics(List<KpiMetric> metrics)
```

接受 `KpiMetric` 列表，返回包含各指标明细和综合总分的 `KpiScore`。

#### `score` — 旧版兼容接口

```dart
KpiResult score(List<KpiIndicator> indicators)
```

仅支持正向指标，无 `failThreshold`，保留向后兼容。新代码请使用 `scoreMetrics`。

---

## 数据模型

### `KpiMetric` — 指标快照

```dart
class KpiMetric {
  final String code;               // 指标代码，如 'K01'
  final String name;               // 指标名称
  final double fullScoreThreshold; // 满分阈值
  final double passThreshold;      // 及格阈值
  final double failThreshold;      // 零分红线
  final double weight;             // 权重，值域 [0.0, 1.0]
  final double actualValue;        // 当期实际测量值
  final KpiDirection direction;    // 指标方向（默认 positive）
}
```

> 同一 KPI 方案（scheme）所有指标的 `weight` 之和应等于 1.0。

### `KpiScore` — 综合打分结果

```dart
class KpiScore {
  final List<KpiMetricScore> metricScores; // 各指标明细
  final double totalScore;                 // 加权综合总分（已 clamp）
}
```

### `KpiMetricScore` — 单指标得分明细

```dart
class KpiMetricScore {
  final String code;           // 指标代码
  final double actualValue;    // 实际值
  final double rawScore;       // 该指标原始得分（0–100）
  final double weightedScore;  // 加权得分（rawScore × weight）
  final KpiDirection direction;
}
```

---

## 使用示例

### 1. 正向指标示例 — 出租率 K01

```dart
import 'package:propos_kpi_scorer/propos_kpi_scorer.dart';

// 指标定义：出租率满分≥95%，及格≥80%，零分≤60%，权重 25%
// 本季实际出租率 91%
const metric = KpiMetric(
  code: 'K01',
  name: '出租率',
  fullScoreThreshold: 0.95,
  passThreshold: 0.80,
  failThreshold: 0.60,
  weight: 0.25,
  actualValue: 0.91,
  direction: KpiDirection.positive,
);

const scorer = KpiScorer();
final result = scorer.scoreMetrics([metric]);

print(result.metricScores.first.rawScore);    // → 89.33（SEED §10 验算值）
print(result.metricScores.first.weightedScore); // → 22.33
```

### 2. 反向指标示例 — 逾期率 K08

```dart
// 指标定义：逾期率满分≤5%，及格≤15%，零分≥20%，权重 15%
// 本季实际逾期率 8%
const metric = KpiMetric(
  code: 'K08',
  name: '逾期率',
  fullScoreThreshold: 0.05,
  passThreshold: 0.15,
  failThreshold: 0.20,
  weight: 0.15,
  actualValue: 0.08,
  direction: KpiDirection.negative,
);

final result = scorer.scoreMetrics([metric]);
print(result.metricScores.first.rawScore); // → 88.00（SEED §10 验算值）
```

### 3. 综合多指标打分

```dart
final metrics = [
  const KpiMetric(
    code: 'K01', name: '出租率',
    fullScoreThreshold: 0.95, passThreshold: 0.80, failThreshold: 0.60,
    weight: 0.25, actualValue: 0.91,
    direction: KpiDirection.positive,
  ),
  const KpiMetric(
    code: 'K06', name: '工单完结率',
    fullScoreThreshold: 0.90, passThreshold: 0.75, failThreshold: 0.60,
    weight: 0.20, actualValue: 0.92,
    direction: KpiDirection.positive,
  ),
  const KpiMetric(
    code: 'K08', name: '逾期率',
    fullScoreThreshold: 0.05, passThreshold: 0.15, failThreshold: 0.20,
    weight: 0.15, actualValue: 0.08,
    direction: KpiDirection.negative,
  ),
  // ... 更多指标
];

const scorer = KpiScorer();
final kpiScore = scorer.scoreMetrics(metrics);

print('综合总分: ${kpiScore.totalScore.toStringAsFixed(2)}');

for (final s in kpiScore.metricScores) {
  print('${s.code}: 实际=${s.actualValue} '
        '原始分=${s.rawScore.toStringAsFixed(2)} '
        '加权=${s.weightedScore.toStringAsFixed(2)}');
}
```

### 4. 旧版接口（向后兼容）

```dart
final indicators = [
  KpiIndicator(name: '出租率', target: 0.95, actual: 0.91, weight: 0.3),
  KpiIndicator(name: '费用收缴率', target: 0.98, actual: 0.97, weight: 0.25),
];

final result = scorer.score(indicators);
print(result.totalScore);
for (final s in result.indicatorScores) {
  print('${s.name}: ${s.score.toStringAsFixed(2)}');
}
```

---

## SEED 数据验算参考

以下为 `SEED_DATA_SPEC §10` 中 Q3 考核期的验算样本，可用于端到端集成验证：

| 指标 | code | actual | full | pass | fail | weight | rawScore |
|------|------|--------|------|------|------|--------|----------|
| 出租率 | K01 | 0.91 | 0.95 | 0.80 | 0.60 | 0.25 | **89.33** |
| 工单完结率 | K06 | 0.92 | 0.90 | 0.75 | 0.60 | 0.20 | **100.00** |
| 逾期率（反向） | K08 | 0.08 | 0.05 | 0.15 | 0.20 | 0.15 | **88.00** |

综合总分（按全部指标权重加总）：**94.03**

---

## 指标阈值配置规则

| 指标类型 | `fullScoreThreshold` | `passThreshold` | `failThreshold` |
|---------|---------------------|----------------|----------------|
| 正向（越高越好） | 最高值（`actual ≥ full` → 满分） | 及格下限 | 零分上限（`actual ≤ fail` → 0分） |
| 反向（越低越好） | 最低值（`actual ≤ full` → 满分） | 及格上限 | 零分下限（`actual ≥ fail` → 0分） |

> 配置错误（如正向指标 `fail > pass`）不会抛出异常，但插值结果可能无意义。调用方应在业务层校验阈值逻辑。

---

## 运行测试

```bash
cd backend/packages/kpi_scorer
dart test
# 21 tests passed
```

---

## 架构约束

- 本包为 **PropOS 架构约束 §5** 规定的零依赖核心计算包，**禁止**引入任何 pub.dev 外部依赖
- 分值使用 `double`，`totalScore` 已经 `clamp(0.0, 100.0)`，调用方无需二次限幅
- 本包不含日志、HTTP、数据库访问等副作用，适合在单元测试中直接调用
- 与数据库 `kpi_metric_definitions` 表字段对应关系：`code → code`、`fullScoreThreshold → default_full_score_threshold`、`passThreshold → default_pass_threshold`、`failThreshold → default_fail_threshold`、`weight → weight`、`direction → direction`
