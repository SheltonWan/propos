/**
 * 业务规则常量
 * 对应 backend business_rules.dart，禁止在业务代码中硬编码魔法数字
 */

// ── 租约到期预警天数 ────────────────────────────────────
export const LEASE_EXPIRY_WARNING_DAYS_90 = 90
export const LEASE_EXPIRY_WARNING_DAYS_60 = 60
export const LEASE_EXPIRY_WARNING_DAYS_30 = 30

// ── 租金逾期节点（天） ────────────────────────────────────
export const OVERDUE_DAY_1 = 1
export const OVERDUE_DAY_7 = 7
export const OVERDUE_DAY_15 = 15

// ── KPI 阈值 ─────────────────────────────────────────────
export const KPI_PERFECT_THRESHOLD = 0.95
export const KPI_PASS_THRESHOLD = 0.60

// ── 押金退还预警（天） ────────────────────────────────────
export const DEPOSIT_RETURN_WARNING_DAYS = 7

// ── 二房东外部填报 SLA（小时） ──────────────────────────
export const SUBLEASE_REVIEW_SLA_HOURS = 48
