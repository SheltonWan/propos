/// KPI 指标方向（与 data_model kpi_metric_definitions.direction 字段对齐）
///
/// - [positive]：数值越高越好（K01出租率 / K02收款及时率 / K04续约率 / K07NOI达成率 /
///   K09递增执行率 / K10租户满意度）
/// - [negative]：数值越低越好（K03租户集中度 / K05工单响应时效 / K06空置周转天数 / K08逾期率），
///   打分时线性插值逻辑翻转
enum KpiDirection {
  /// 正向：actual 越大，得分越高
  positive,

  /// 反向：actual 越小，得分越高（如逾期率、空置天数）
  negative,
}
