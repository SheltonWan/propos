import 'package:propos_kpi_scorer/propos_kpi_scorer.dart';
import 'package:test/test.dart';

void main() {
  const scorer = KpiScorer();

  // ---------------------------------------------------------------------------
  // 旧接口 KpiIndicator（正向指标，无 failThreshold）
  // ---------------------------------------------------------------------------
  KpiIndicator ind({
    required String code,
    required double pass,
    required double perfect,
    required double actual,
    double weight = 0.1,
  }) =>
      KpiIndicator(
        code: code,
        name: code,
        passThreshold: pass,
        perfectThreshold: perfect,
        weight: weight,
        actualValue: actual,
      );

  group('KpiIndicator 单指标打分（旧接口）', () {
    test('实际值 >= 满分阈值 → 100 分', () {
      final result = scorer.score([ind(code: 'K01', pass: 0.85, perfect: 0.95, actual: 1.0)]);
      expect(result.indicatorScores.first.rawScore, equals(100.0));
    });

    test('实际值 == 满分阈值 → 100 分', () {
      final result = scorer.score([ind(code: 'K01', pass: 0.85, perfect: 0.95, actual: 0.95)]);
      expect(result.indicatorScores.first.rawScore, equals(100.0));
    });

    test('实际值 == 及格阈值 → 60 分', () {
      final result = scorer.score([ind(code: 'K01', pass: 0.85, perfect: 0.95, actual: 0.85)]);
      expect(result.indicatorScores.first.rawScore, closeTo(60.0, 0.001));
    });

    test('实际值 < 及格阈值 → 低于 60 分', () {
      final result = scorer.score([ind(code: 'K01', pass: 0.85, perfect: 0.95, actual: 0.50)]);
      expect(result.indicatorScores.first.rawScore, lessThan(60.0));
    });

    test('实际值 = 0 → 0 分', () {
      final result = scorer.score([ind(code: 'K01', pass: 0.85, perfect: 0.95, actual: 0.0)]);
      expect(result.indicatorScores.first.rawScore, equals(0.0));
    });
  });

  group('KpiIndicator 总分计算（旧接口）', () {
    test('两个指标权重各 0.5，总分正确', () {
      final indicators = [
        ind(code: 'K01', pass: 0.8, perfect: 0.95, actual: 0.95, weight: 0.5),
        ind(code: 'K02', pass: 0.8, perfect: 0.95, actual: 0.8, weight: 0.5),
      ];
      final result = scorer.score(indicators);
      // K01 = 100 × 0.5 = 50, K02 = 60 × 0.5 = 30 → total = 80
      expect(result.totalScore, closeTo(80.0, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // 新接口 KpiMetric（支持 direction + failThreshold）
  // ---------------------------------------------------------------------------

  KpiMetric metric({
    required String code,
    required double full,
    required double pass,
    required double fail,
    required double actual,
    required double weight,
    KpiDirection direction = KpiDirection.positive,
  }) =>
      KpiMetric(
        code: code,
        name: code,
        fullScoreThreshold: full,
        passThreshold: pass,
        failThreshold: fail,
        weight: weight,
        actualValue: actual,
        direction: direction,
      );

  group('KpiMetric 正向指标（越高越好）', () {
    test('actual >= fullScore → 100 分', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 1.00, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, equals(100.0));
    });

    test('actual == fullScore → 100 分', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.95, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, equals(100.0));
    });

    test('actual == pass → 60 分', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.80, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(60.0, 0.001));
    });

    // SEED §10: K01 出租率 actual=91%, full=95%, pass=80%, fail=60% → 89.33
    test('K01 出租率 91% → 89.33（SEED验算）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.91, weight: 0.25),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(89.33, 0.01));
    });

    test('actual == fail → 0 分', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.60, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, equals(0.0));
    });

    test('actual < fail → 0 分（clamp）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.30, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, equals(0.0));
    });

    // 部分得分区间：fail < actual < pass → 0~60 线性插值
    // actual=0.70, fail=0.60, pass=0.80 → (0.70-0.60)/(0.80-0.60)*60 = 30.0
    test('fail < actual < pass → 0~60 线性插值（部分得分区间）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.70, weight: 1.0),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(30.0, 0.01));
    });
  });

  group('KpiMetric 反向指标（越低越好）', () {
    // SEED §10: K08 逾期率 actual=8%, full=5%, pass=15%, fail=20% → 88.00
    test('K08 逾期率 8% → 88.00（SEED验算）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.08, weight: 0.15,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(88.0, 0.01));
    });

    // SEED §10: K06 空置周转天数 actual=25天, full=30, pass=60, fail=90 → 100
    test('K06 空置周转天数 25天 ≤ 满分30天 → 100 分（SEED验算）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K06', full: 30, pass: 60, fail: 90,
            actual: 25, weight: 0.15,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, equals(100.0));
    });

    test('actual == pass → 60 分', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.15, weight: 1.0,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(60.0, 0.001));
    });

    test('actual >= fail → 0 分（红线）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.25, weight: 1.0,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, equals(0.0));
    });

    test('actual == fullScore → 100 分（满分边界精确）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.05, weight: 1.0,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, equals(100.0));
    });

    // 部分得分区间：pass < actual < fail → 0~60 线性插值
    // actual=0.17, full=0.05, pass=0.15, fail=0.20 → (0.20-0.17)/(0.20-0.15)*60 = 36.0
    test('pass < actual < fail → 0~60 线性插值（反向部分得分区间）', () {
      final s = scorer.scoreMetrics([
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.17, weight: 1.0,
            direction: KpiDirection.negative),
      ]);
      expect(s.metricScores.first.rawScore, closeTo(36.0, 0.01));
    });
  });

  group('KpiScore 综合总分（SEED §10 完整验算）', () {
    // SEED §10 期望总分 94.03
    test('6指标混合打分总分 ≈ 94.03', () {
      final metrics = [
        // K01 出租率 25% → 89.33
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.91, weight: 0.25),
        // K02 收款及时率 20% → 100
        metric(code: 'K02', full: 0.95, pass: 0.80, fail: 0.70,
            actual: 0.98, weight: 0.20),
        // K04 续约率 15% → 90
        metric(code: 'K04', full: 0.80, pass: 0.60, fail: 0.40,
            actual: 0.75, weight: 0.15),
        // K06 空置周转天数（反向）15% → 100
        metric(code: 'K06', full: 30, pass: 60, fail: 90,
            actual: 25, weight: 0.15, direction: KpiDirection.negative),
        // K08 逾期率（反向）15% → 88
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.08, weight: 0.15, direction: KpiDirection.negative),
        // K09 递增执行率 10% → 100
        metric(code: 'K09', full: 0.95, pass: 0.80, fail: 0.70,
            actual: 1.00, weight: 0.10),
      ];
      final result = scorer.scoreMetrics(metrics);
      expect(result.totalScore, closeTo(94.03, 0.01));
    });

    test('得分值域 clamp：指标均 0 → 总分 0', () {
      final metrics = [
        metric(code: 'K01', full: 0.95, pass: 0.80, fail: 0.60,
            actual: 0.0, weight: 0.5),
        metric(code: 'K08', full: 0.05, pass: 0.15, fail: 0.20,
            actual: 0.99, weight: 0.5, direction: KpiDirection.negative),
      ];
      final result = scorer.scoreMetrics(metrics);
      expect(result.totalScore, equals(0.0));
    });
  });
}

