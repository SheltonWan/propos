/// 租金递增类型枚举（6 种）
/// 与 data_model.md `rent_escalation_type` 枚举值精确对齐
enum EscalationType {
  /// 固定比例递增（如每年/每N年涨固定百分比）
  fixedRate,

  /// 固定金额递增（每平米每月递增固定元）
  fixedAmount,

  /// 阶梯式递增（按分段表定义绝对租金）
  stepped,

  /// CPI 联动递增（按年度 CPI 指数调整）
  cpiLinked,

  /// 每 N 年固定比例递增
  everyNYears,

  /// 装修免租期结束后开始递增
  postRenovation,
}
