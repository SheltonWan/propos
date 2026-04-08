/// 单指标打分结果
class KpiIndicatorScore {
  final String code;
  final double actualValue;
  final double rawScore;   // 0 ~ 100
  final double weightedScore;

  const KpiIndicatorScore({
    required this.code,
    required this.actualValue,
    required this.rawScore,
    required this.weightedScore,
  });
}

/// 综合 KPI 打分结果
class KpiResult {
  final List<KpiIndicatorScore> indicatorScores;
  /// KPI 总分 = Σ(rawScore_i × weight_i)
  final double totalScore;

  const KpiResult({
    required this.indicatorScores,
    required this.totalScore,
  });
}
