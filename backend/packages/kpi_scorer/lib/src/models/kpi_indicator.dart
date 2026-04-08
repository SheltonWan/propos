/// KPI 指标定义
class KpiIndicator {
  /// 指标代码，如 'K01'
  final String code;
  /// 指标名称
  final String name;
  /// 及格阈值（actual >= passThreshold → 60 分基线）
  final double passThreshold;
  /// 满分阈值（actual >= perfectThreshold → 100 分）
  final double perfectThreshold;
  /// 权重（0.0 ~ 1.0），所有指标权重之和必须等于 1.0
  final double weight;
  /// 实际值
  final double actualValue;

  const KpiIndicator({
    required this.code,
    required this.name,
    required this.passThreshold,
    required this.perfectThreshold,
    required this.weight,
    required this.actualValue,
  });
}
