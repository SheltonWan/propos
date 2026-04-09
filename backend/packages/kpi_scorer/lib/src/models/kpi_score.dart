import 'kpi_direction.dart';

/// 单指标打分结果（对应 kpi_score_snapshot_items 一行）
class KpiMetricScore {
  final String code;
  final double actualValue;

  /// 原始得分，值域 [0.0, 100.0]（已 clamp）
  final double rawScore;

  /// 加权得分 = rawScore × weight
  final double weightedScore;

  final KpiDirection direction;

  const KpiMetricScore({
    required this.code,
    required this.actualValue,
    required this.rawScore,
    required this.weightedScore,
    required this.direction,
  });
}

/// 综合 KPI 打分结果（对应 kpi_score_snapshots 一行）
///
/// KPI 总分 = Σ(rawScore_i × weight_i)，值域 [0.0, 100.0]
class KpiScore {
  final List<KpiMetricScore> metricScores;

  /// KPI 总分（已 clamp 至 [0.0, 100.0]）
  final double totalScore;

  const KpiScore({
    required this.metricScores,
    required this.totalScore,
  });
}
