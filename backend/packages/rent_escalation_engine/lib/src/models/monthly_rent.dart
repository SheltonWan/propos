/// 单月租金记录
class MonthlyRent {
  /// 合同内第几个月（从 1 开始）
  final int monthIndex;
  /// 该月对应的历法月份（UTC 第一天）
  final DateTime month;
  /// 该月应收月租（元，精确到分）
  final double amount;

  const MonthlyRent({
    required this.monthIndex,
    required this.month,
    required this.amount,
  });
}
