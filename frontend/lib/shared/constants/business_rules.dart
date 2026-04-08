// 业务规则常量（禁止在业务代码中硬编码魔法数字）
// ignore_for_file: constant_identifier_names

/// 租约到期预警天数
const int kLeaseExpiryWarningDays90 = 90;
const int kLeaseExpiryWarningDays60 = 60;
const int kLeaseExpiryWarningDays30 = 30;

/// 租金逾期节点（天）
const int kOverdueDay1 = 1;
const int kOverdueDay7 = 7;
const int kOverdueDay15 = 15;

/// KPI 满分率阈值
const double kKpiPerfectThreshold = 0.95;
const double kKpiPassThreshold = 0.60;

/// 押金退还预警提前天数
const int kDepositReturnWarningDays = 7;
