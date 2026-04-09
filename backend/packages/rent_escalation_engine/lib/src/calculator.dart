import 'models/rent_escalation_phase.dart';
import 'models/rent_escalation_rule.dart';
import 'models/monthly_rent.dart';

/// 租金递增计算器
/// 零外部依赖，所有方法为纯函数
class RentCalculator {
  const RentCalculator();

  /// 多阶段混合租金计算（混合分段场景）
  ///
  /// [phases] 按 startMonth 升序排列，各阶段互不重叠且紧密衔接。
  /// 每个阶段的 monthIndex 从该阶段的 startMonth 开始重新计算（相位偏移）。
  /// 若目标月不在任何阶段内，回退为 [baseMonthlyRent]。
  ///
  /// 示例（混合分段）：
  /// ```dart
  /// const phases = [
  ///   FixedRatePhase(startMonth: 1, endMonth: 24, rule: FixedRateRule(percent: 0.05)),
  ///   CpiLinkedPhase(startMonth: 25, rule: CpiLinkedRule(cpiByYear: {1: 1.03})),
  /// ];
  /// final rent = calc.compute(phases: phases, baseMonthlyRent: 10000,
  ///     contractStart: ..., targetMonth: ...);
  /// ```
  double compute({
    required List<RentEscalationPhase> phases,
    required double baseMonthlyRent,
    required DateTime contractStart,
    required DateTime targetMonth,
  }) {
    final monthIndex = _monthsBetween(contractStart, targetMonth) + 1;
    for (final phase in phases) {
      if (phase.contains(monthIndex)) {
        final phaseMonthIndex = monthIndex - phase.startMonth + 1;
        final rule = _ruleFromPhase(phase);
        return _calculate(rule, baseMonthlyRent, phaseMonthIndex);
      }
    }
    return baseMonthlyRent;
  }

  /// 多阶段全生命周期租金列表
  List<MonthlyRent> generateScheduleFromPhases({
    required List<RentEscalationPhase> phases,
    required double baseMonthlyRent,
    required DateTime contractStart,
    required DateTime contractEnd,
  }) {
    final result = <MonthlyRent>[];
    var current = DateTime.utc(contractStart.year, contractStart.month);
    int monthIndex = 1;
    while (!current.isAfter(DateTime.utc(contractEnd.year, contractEnd.month))) {
      final amount = _computeByMonthIndex(phases, baseMonthlyRent, monthIndex);
      result.add(MonthlyRent(monthIndex: monthIndex, month: current, amount: amount));
      current = DateTime.utc(
        current.month == 12 ? current.year + 1 : current.year,
        current.month == 12 ? 1 : current.month + 1,
      );
      monthIndex++;
    }
    return result;
  }

  double _computeByMonthIndex(
      List<RentEscalationPhase> phases, double base, int monthIndex) {
    for (final phase in phases) {
      if (phase.contains(monthIndex)) {
        final phaseMonthIndex = monthIndex - phase.startMonth + 1;
        return _calculate(_ruleFromPhase(phase), base, phaseMonthIndex);
      }
    }
    return base;
  }

  RentEscalationRule _ruleFromPhase(RentEscalationPhase phase) {
    return switch (phase) {
      FixedRatePhase p => p.rule,
      FixedAmountPhase p => p.rule,
      SteppedPhase p => p.rule,
      CpiLinkedPhase p => p.rule,
      EveryNYearsPhase p => p.rule,
      PostRenovationPhase p => p.rule,
    };
  }

  /// 给定递增规则、基准月租、合同起始日期和目标月份，返回当月应收月租（元）
  double calculateRentForMonth({
    required RentEscalationRule rule,
    required double baseMonthlyRent,
    required DateTime contractStart,
    required DateTime targetMonth,
  }) {
    final monthIndex = _monthsBetween(contractStart, targetMonth) + 1;
    return _calculate(rule, baseMonthlyRent, monthIndex);
  }

  /// 生成合同全生命周期每月租金列表
  List<MonthlyRent> generateRentSchedule({
    required RentEscalationRule rule,
    required double baseMonthlyRent,
    required DateTime contractStart,
    required DateTime contractEnd,
  }) {
    final result = <MonthlyRent>[];
    var current = DateTime.utc(contractStart.year, contractStart.month);
    int monthIndex = 1;

    while (!current.isAfter(DateTime.utc(contractEnd.year, contractEnd.month))) {
      final amount = _calculate(rule, baseMonthlyRent, monthIndex);
      result.add(MonthlyRent(
        monthIndex: monthIndex,
        month: current,
        amount: amount,
      ));
      current = DateTime.utc(
        current.month == 12 ? current.year + 1 : current.year,
        current.month == 12 ? 1 : current.month + 1,
      );
      monthIndex++;
    }
    return result;
  }

  double _calculate(
      RentEscalationRule rule, double base, int monthIndex) {
    return switch (rule) {
      FixedRateRule r => _fixedRate(r, base, monthIndex),
      FixedAmountRule r => _fixedAmount(r, base, monthIndex),
      SteppedRule r => _stepped(r, monthIndex),
      CpiLinkedRule r => _cpiLinked(r, base, monthIndex),
      EveryNYearsRule r => _everyNYears(r, base, monthIndex),
      PostRenovationRule r => _postRenovation(r, monthIndex),
    };
  }

  double _fixedRate(FixedRateRule r, double base, int monthIndex) {
    final intervals = (monthIndex - 1) ~/ (r.intervalYears * 12);
    return base * _pow(1 + r.percent, intervals);
  }

  double _fixedAmount(FixedAmountRule r, double base, int monthIndex) {
    final intervals = (monthIndex - 1) ~/ (r.intervalYears * 12);
    return base + r.incrementPerMonth * intervals;
  }

  double _stepped(SteppedRule r, int monthIndex) {
    double rent = 0;
    for (final step in r.steps.reversed) {
      if (monthIndex > step.startMonth) {
        rent = step.monthlyRent;
        break;
      }
    }
    // 如果 monthIndex <= 所有 step 的 startMonth，取第一个
    if (rent == 0 && r.steps.isNotEmpty) {
      rent = r.steps.first.monthlyRent;
    }
    return rent;
  }

  double _cpiLinked(CpiLinkedRule r, double base, int monthIndex) {
    final year = ((monthIndex - 1) ~/ 12) + 1;
    double amount = base;
    for (int y = 1; y <= year; y++) {
      final factor = r.cpiByYear[y] ?? 1.0;
      if (y < year) amount *= factor;
    }
    return amount;
  }

  double _everyNYears(EveryNYearsRule r, double base, int monthIndex) {
    final intervals = (monthIndex - 1) ~/ (r.intervalYears * 12);
    return base * _pow(1 + r.percent, intervals);
  }

  double _postRenovation(PostRenovationRule r, int monthIndex) {
    if (monthIndex <= r.freeRentMonths) return 0;
    final adjustedIndex = monthIndex - r.freeRentMonths;
    if (r.followUpRule == null) return r.baseMonthlyRent;
    return _calculate(r.followUpRule!, r.baseMonthlyRent, adjustedIndex);
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
