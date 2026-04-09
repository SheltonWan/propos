import 'kpi_direction.dart';

/// KPI 指标快照（含义与 data_model kpi_metric_definitions 对齐）
///
/// 示例 — 正向指标 K01 出租率（Q3 实测 91%）：
/// ```dart
/// const metric = KpiMetric(
///   code: 'K01', name: '出租率',
///   fullScoreThreshold: 0.95, passThreshold: 0.80, failThreshold: 0.60,
///   weight: 0.25, actualValue: 0.91, direction: KpiDirection.positive,
/// );
/// ```
///
/// 示例 — 反向指标 K08 逾期率（Q3 实测 8%）：
/// ```dart
/// const metric = KpiMetric(
///   code: 'K08', name: '逾期率',
///   fullScoreThreshold: 0.05, passThreshold: 0.15, failThreshold: 0.20,
///   weight: 0.15, actualValue: 0.08, direction: KpiDirection.negative,
/// );
/// ```
class KpiMetric {
  /// 指标代码，如 'K01'
  final String code;

  /// 指标名称
  final String name;

  /// 满分阈值（对应 default_full_score_threshold）
  /// - positive：actual ≥ this → 100 分
  /// - negative：actual ≤ this → 100 分
  final double fullScoreThreshold;

  /// 及格阈值（对应 default_pass_threshold）
  /// - positive：actual ≥ this → 进入 60-100 区间
  /// - negative：actual ≤ this → 进入 60-100 区间
  final double passThreshold;

  /// 零分红线（对应 default_fail_threshold）
  /// - positive：actual ≤ this → 0 分
  /// - negative：actual ≥ this → 0 分
  final double failThreshold;

  /// 权重，值域 [0.0, 1.0]，同一 scheme 所有指标权重之和应等于 1.0
  final double weight;

  /// 当期实际测量值（与 kpi_score_snapshot_items.actual_value 对应）
  final double actualValue;

  /// 指标方向（默认正向）
  final KpiDirection direction;

  const KpiMetric({
    required this.code,
    required this.name,
    required this.fullScoreThreshold,
    required this.passThreshold,
    required this.failThreshold,
    required this.weight,
    required this.actualValue,
    this.direction = KpiDirection.positive,
  });
}
