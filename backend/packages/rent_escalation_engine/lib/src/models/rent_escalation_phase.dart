import 'escalation_type.dart';
import 'rent_escalation_rule.dart';

/// 合同租金递增阶段（sealed union）
///
/// 一份合同可拆分为若干阶段，每个阶段以 [startMonth]、[endMonth] 界定
/// 时间范围，并关联一个具体的递增规则。混合分段示例：
/// ```
/// 第 1~24 月：FixedRatePhase (5%)
/// 第 25~36 月：CpiLinkedPhase
/// ```
sealed class RentEscalationPhase {
  /// 阶段起始月（相对合同开始，从 1 开始）
  final int startMonth;

  /// 阶段结束月（含）；null 表示延续到合同结束
  final int? endMonth;

  /// 本阶段对应的递增类型
  EscalationType get type;

  const RentEscalationPhase({required this.startMonth, this.endMonth});

  /// 判断目标月序号是否落在本阶段范围内
  bool contains(int monthIndex) {
    if (monthIndex < startMonth) return false;
    return endMonth == null || monthIndex <= endMonth!;
  }
}

/// 固定比例递增阶段
final class FixedRatePhase extends RentEscalationPhase {
  final FixedRateRule rule;

  @override
  EscalationType get type => EscalationType.fixedRate;

  const FixedRatePhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}

/// 固定金额递增阶段
final class FixedAmountPhase extends RentEscalationPhase {
  final FixedAmountRule rule;

  @override
  EscalationType get type => EscalationType.fixedAmount;

  const FixedAmountPhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}

/// 阶梯式递增阶段
final class SteppedPhase extends RentEscalationPhase {
  final SteppedRule rule;

  @override
  EscalationType get type => EscalationType.stepped;

  const SteppedPhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}

/// CPI 联动递增阶段
final class CpiLinkedPhase extends RentEscalationPhase {
  final CpiLinkedRule rule;

  @override
  EscalationType get type => EscalationType.cpiLinked;

  const CpiLinkedPhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}

/// 每 N 年固定比例递增阶段
final class EveryNYearsPhase extends RentEscalationPhase {
  final EveryNYearsRule rule;

  @override
  EscalationType get type => EscalationType.everyNYears;

  const EveryNYearsPhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}

/// 装修免租后递增阶段
final class PostRenovationPhase extends RentEscalationPhase {
  final PostRenovationRule rule;

  @override
  EscalationType get type => EscalationType.postRenovation;

  const PostRenovationPhase({
    required super.startMonth,
    super.endMonth,
    required this.rule,
  });
}
