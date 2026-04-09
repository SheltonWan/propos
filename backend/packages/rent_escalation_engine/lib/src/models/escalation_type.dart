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
  postRenovation;

  /// 转换为数据库存储的枚举字符串（exhaustive switch — 新增枚举值时编译器强制补充）
  ///
  /// DB 值（snake_case）↔ Dart enum（camelCase）映射：
  /// | Dart            | DB                       |
  /// |-----------------|--------------------------|
  /// | fixedRate       | fixed_rate               |
  /// | fixedAmount     | fixed_amount             |
  /// | stepped         | step                     |
  /// | cpiLinked       | cpi                      |
  /// | everyNYears     | periodic                 |
  /// | postRenovation  | base_after_free_period   |
  String toDbValue() {
    return switch (this) {
      EscalationType.fixedRate      => 'fixed_rate',
      EscalationType.fixedAmount    => 'fixed_amount',
      EscalationType.stepped        => 'step',
      EscalationType.cpiLinked      => 'cpi',
      EscalationType.everyNYears    => 'periodic',
      EscalationType.postRenovation => 'base_after_free_period',
    };
  }

  /// 从数据库 `escalation_type` 枚举字符串构造
  ///
  /// **实现说明**：通过遍历 [EscalationType.values] 并调用 [toDbValue] 反向查找，
  /// 确保与 [toDbValue] 永远保持一致——新增枚举值只需维护 [toDbValue] 一处。
  ///
  /// 未知值抛出 [ArgumentError]。
  static EscalationType fromDbValue(String dbValue) {
    return EscalationType.values.firstWhere(
      (e) => e.toDbValue() == dbValue,
      orElse: () => throw ArgumentError('未知的 escalation_type 数据库值: $dbValue'),
    );
  }
}
