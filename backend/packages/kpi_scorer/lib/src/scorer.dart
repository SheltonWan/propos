import 'models/kpi_direction.dart';
import 'models/kpi_indicator.dart';
import 'models/kpi_metric.dart';
import 'models/kpi_result.dart';
import 'models/kpi_score.dart';

/// KPI 线性插值打分器
///
/// 提供两套 API：
/// - [score]：老接口，接受 [KpiIndicator] 列表（正向指标，无 failThreshold）
/// - [scoreMetrics]：新接口，接受 [KpiMetric] 列表（支持 direction + failThreshold）
///
/// **打分公式（正向指标，越高越好）：**
/// - actual ≥ fullScore → 100
/// - actual ≥ pass      → 60 + (actual − pass) / (full − pass) × 40
/// - actual > fail      → (actual − fail) / (pass − fail) × 60
/// - actual ≤ fail      → 0
///
/// **反向指标（越低越好）插值翻转：**
/// - actual ≤ fullScore → 100
/// - actual ≤ pass      → 60 + (pass − actual) / (pass − full) × 40
/// - actual < fail      → (fail − actual) / (fail − pass) × 60
/// - actual ≥ fail      → 0
///
/// 所有得分均 clamp 至 [0.0, 100.0]，不抛异常。
class KpiScorer {
  const KpiScorer();

  // ---------------------------------------------------------------------------
  // 新接口：KpiMetric（支持 direction + failThreshold）
  // ---------------------------------------------------------------------------

  /// 多指标综合打分（支持正/反向，based on SEED_DATA_SPEC §10 验算样本）
  KpiScore scoreMetrics(List<KpiMetric> metrics) {
    final scores = metrics.map(_scoreOneMetric).toList();
    final total =
        scores.fold(0.0, (sum, s) => sum + s.weightedScore).clamp(0.0, 100.0);
    return KpiScore(metricScores: scores, totalScore: total);
  }

  KpiMetricScore _scoreOneMetric(KpiMetric m) {
    final raw = switch (m.direction) {
      KpiDirection.positive => _interpolatePositive(
          m.actualValue, m.failThreshold, m.passThreshold, m.fullScoreThreshold),
      KpiDirection.negative => _interpolateNegative(
          m.actualValue, m.failThreshold, m.passThreshold, m.fullScoreThreshold),
    };
    return KpiMetricScore(
      code: m.code,
      actualValue: m.actualValue,
      rawScore: raw,
      weightedScore: raw * m.weight,
      direction: m.direction,
    );
  }

  /// 正向指标线性插值（越高越好，fail < pass < fullScore）
  static double _interpolatePositive(
      double actual, double fail, double pass, double full) {
    if (actual >= full) return 100.0;
    if (actual >= pass) {
      return (60.0 + (actual - pass) / (full - pass) * 40.0).clamp(0.0, 100.0);
    }
    if (actual <= fail) return 0.0;
    return ((actual - fail) / (pass - fail) * 60.0).clamp(0.0, 60.0);
  }

  /// 反向指标线性插值（越低越好，fullScore < pass < fail）
  static double _interpolateNegative(
      double actual, double fail, double pass, double full) {
    if (actual <= full) return 100.0;
    if (actual <= pass) {
      return (60.0 + (pass - actual) / (pass - full) * 40.0).clamp(0.0, 100.0);
    }
    if (actual >= fail) return 0.0;
    return ((fail - actual) / (fail - pass) * 60.0).clamp(0.0, 60.0);
  }

  // ---------------------------------------------------------------------------
  // 旧接口：KpiIndicator（保留兼容）
  // ---------------------------------------------------------------------------

  KpiResult score(List<KpiIndicator> indicators) {
    final scores = indicators.map(_scoreOne).toList();
    final total = scores.fold(
      0.0,
      (sum, s) => sum + s.weightedScore,
    );
    return KpiResult(indicatorScores: scores, totalScore: total);
  }

  KpiIndicatorScore _scoreOne(KpiIndicator ind) {
    final raw = _interpolateLegacy(
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

  static double _interpolateLegacy({
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

