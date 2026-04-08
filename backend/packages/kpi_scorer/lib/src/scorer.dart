import 'models/kpi_indicator.dart';
import 'models/kpi_result.dart';

/// KPI 线性插值打分器
/// 公式（每个指标独立计算）：
///   actual >= perfectThreshold → score = 100
///   actual >= passThreshold    → score = 60 + (actual - pass) / (perfect - pass) × 40
///   actual < passThreshold     → score = max(0, actual / pass × 60)
///   KPI总分 = Σ(score_i × weight_i)
class KpiScorer {
  const KpiScorer();

  KpiResult score(List<KpiIndicator> indicators) {
    final scores = indicators.map(_scoreOne).toList();
    final total = scores.fold(
      0.0,
      (sum, s) => sum + s.weightedScore,
    );
    return KpiResult(indicatorScores: scores, totalScore: total);
  }

  KpiIndicatorScore _scoreOne(KpiIndicator ind) {
    final raw = _interpolate(
      actual: ind.actualValue,
      passThreshold: ind.passThreshold,
      perfectThreshold: ind.perfectThreshold,
    );
    return KpiIndicatorScore(
      code: ind.code,
      actualValue: ind.actualValue,
      rawScore: raw,
      weightedScore: raw * ind.weight,
    );
  }

  static double _interpolate({
    required double actual,
    required double passThreshold,
    required double perfectThreshold,
  }) {
    if (actual >= perfectThreshold) return 100.0;
    if (actual >= passThreshold) {
      return 60.0 +
          (actual - passThreshold) /
              (perfectThreshold - passThreshold) *
              40.0;
    }
    if (passThreshold == 0) return 0;
    return (actual / passThreshold * 60.0).clamp(0.0, 60.0);
  }
}
