/**
 * API 端点路径常量
 * 对应 backend 约定的所有路由（API_INVENTORY_v1.7.md）
 * 客户端统一从此处引用，禁止在业务代码中硬编码路径字符串
 */

// ── 认证 ────────────────────────────────────────────────
export const API_AUTH_LOGIN = '/api/auth/login'
export const API_AUTH_REFRESH = '/api/auth/refresh'
export const API_AUTH_LOGOUT = '/api/auth/logout'
export const API_AUTH_ME = '/api/auth/me'
export const API_AUTH_CHANGE_PASSWORD = '/api/auth/change-password'

// ── 组织架构 ─────────────────────────────────────────────
export const API_DEPARTMENTS = '/api/departments'

// ── M1 资产 ──────────────────────────────────────────────
export const API_BUILDINGS = '/api/buildings'
export const API_FLOORS = '/api/floors'
export const API_UNITS = '/api/units'
export const API_FLOOR_PLANS = '/api/floor-plans'
export const API_ASSETS_SUMMARY = '/api/assets/summary'
export const API_RENOVATIONS = '/api/renovations'

// ── M2 合同 ──────────────────────────────────────────────
export const API_TENANTS = '/api/tenants'
export const API_CONTRACTS = '/api/contracts'
export const API_ESCALATION_TEMPLATES = '/api/escalation-templates'
export const API_ALERTS = '/api/alerts'
export const API_DEPOSITS = '/api/deposits'

// ── M3 财务 ──────────────────────────────────────────────
export const API_INVOICES = '/api/invoices'
export const API_PAYMENTS = '/api/payments'
export const API_EXPENSES = '/api/expenses'
export const API_NOI_SUMMARY = '/api/noi/summary'
export const API_NOI_TREND = '/api/noi/trend'

// ── M3 KPI ───────────────────────────────────────────────
export const API_KPI_METRICS = '/api/kpi/metrics'
export const API_KPI_SCHEMES = '/api/kpi/schemes'
export const API_KPI_SCORES = '/api/kpi/scores'
export const API_KPI_RANKINGS = '/api/kpi/rankings'
export const API_KPI_APPEALS = '/api/kpi/appeals'

// ── M4 工单 ──────────────────────────────────────────────
export const API_WORKORDERS = '/api/workorders'
export const API_SUPPLIERS = '/api/suppliers'
export const API_METER_READINGS = '/api/meter-readings'

// ── M5 二房东 ─────────────────────────────────────────────
export const API_SUBLEASES = '/api/subleases'
export const API_SUBLEASE_PORTAL = '/api/subleases/portal'
export const API_TURNOVER_REPORTS = '/api/turnover-reports'

// ── 文件代理 / 报表 ──────────────────────────────────────
export const API_FILES = '/api/files'
export const API_REPORTS = '/api/reports'
export const API_IMPORT_BATCHES = '/api/import-batches'
