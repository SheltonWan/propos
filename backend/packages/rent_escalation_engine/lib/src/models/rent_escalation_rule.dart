/// 租金递增规则 — 密封类层次（6 种类型 + 混合分段）
/// 零外部依赖，可在后端 Dart VM 和 Flutter 客户端离线预览复用
sealed class RentEscalationRule {
  const RentEscalationRule();
}

/// 固定比例递增（每年/每N年按比例上涨）
final class FixedRateRule extends RentEscalationRule {
  /// 递增百分比，如 0.05 表示 5%
  final double percent;
  /// 递增周期（年），默认 1
  final int intervalYears;
  const FixedRateRule({required this.percent, this.intervalYears = 1});
}

/// 固定金额递增（每月递增固定元，调用方负责将每平米金额乘以面积后传入）
final class FixedAmountRule extends RentEscalationRule {
  /// 每个递增周期（默认1年）新增的月租金额（元/月）
  final double incrementPerMonth;
  final int intervalYears;
  const FixedAmountRule({required this.incrementPerMonth, this.intervalYears = 1});
}

/// 阶梯式递增（按月/按年分段定义租金）
final class SteppedRule extends RentEscalationRule {
  final List<StepSegment> steps;
  const SteppedRule({required this.steps});
}

class StepSegment {
  /// 起始月（相对合同开始，0 = 第 1 个月）
  final int startMonth;
  /// 该阶段固定租金（元/月）
  final double monthlyRent;
  const StepSegment({required this.startMonth, required this.monthlyRent});
}

/// CPI 联动递增（每年按 CPI 表中对应年度指数调整）
final class CpiLinkedRule extends RentEscalationRule {
  /// key = 年份（合同第几年，从 1 开始），value = CPI 调整系数（如 1.03）
  final Map<int, double> cpiByYear;
  const CpiLinkedRule({required this.cpiByYear});
}

/// 每 N 年固定百分比递增
final class EveryNYearsRule extends RentEscalationRule {
  final int intervalYears;
  final double percent;
  const EveryNYearsRule({required this.intervalYears, required this.percent});
}

/// 装修免租期后租金递增（装修免租 + 后续递增策略）
final class PostRenovationRule extends RentEscalationRule {
  /// 免租月数
  final int freeRentMonths;
  /// 免租期后基准月租（元/月）
  final double baseMonthlyRent;
  /// 免租期后的递增规则（可嵌套）
  final RentEscalationRule? followUpRule;
  const PostRenovationRule({
    required this.freeRentMonths,
    required this.baseMonthlyRent,
    this.followUpRule,
  });
}
