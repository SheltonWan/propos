// ─── 认证 ─────────────────────────────────────────────────────────────────
export const AUTH_LOGIN = '/api/auth/login'
export const AUTH_REFRESH = '/api/auth/refresh'
export const AUTH_LOGOUT = '/api/auth/logout'
export const AUTH_ME = '/api/auth/me'
export const AUTH_CHANGE_PASSWORD = '/api/auth/change-password'
export const AUTH_FORGOT_PASSWORD = '/api/auth/forgot-password'
export const AUTH_RESET_PASSWORD = '/api/auth/reset-password'

// ─── 用户管理 ─────────────────────────────────────────────────────────────
export const USERS = '/api/users'

// ─── 组织架构 ─────────────────────────────────────────────────────────────
export const DEPARTMENTS = '/api/departments'

// ─── 资产 ─────────────────────────────────────────────────────────────────
export const BUILDINGS = '/api/buildings'
export const FLOORS = '/api/floors'
export const UNITS = '/api/units'
export const ASSETS_OVERVIEW = '/api/assets/overview'

// ─── 租务 ─────────────────────────────────────────────────────────────────
export const TENANTS = '/api/tenants'
export const CONTRACTS = '/api/contracts'

// ─── 财务 ─────────────────────────────────────────────────────────────────
export const INVOICES = '/api/invoices'
export const PAYMENTS = '/api/payments'
export const DEPOSITS = '/api/deposits'
export const EXPENSES = '/api/expenses'

// ─── 工单 ─────────────────────────────────────────────────────────────────
export const WORK_ORDERS = '/api/work-orders'
export const SUPPLIERS = '/api/suppliers'

// ─── 二房东 ───────────────────────────────────────────────────────────────
export const SUBLEASES = '/api/subleases'

// ─── 预警与通知 ───────────────────────────────────────────────────────────
export const ALERTS = '/api/alerts'
export const NOTIFICATIONS = '/api/notifications'

// ─── KPI ──────────────────────────────────────────────────────────────────
export const KPI_SCHEMES = '/api/kpi/schemes'
export const KPI_SCORES = '/api/kpi/scores'
export const KPI_APPEALS = '/api/kpi/appeals'

// ─── NOI & WALE ──────────────────────────────────────────────────────────
export const NOI = '/api/noi'
export const WALE = '/api/wale'

// ─── 水电抄表 ─────────────────────────────────────────────────────────────
export const METER_READINGS = '/api/meter-readings'

// ─── 商铺营业额 ──────────────────────────────────────────────────────────
export const TURNOVER_REPORTS = '/api/turnover-reports'

// ─── 文件代理 ─────────────────────────────────────────────────────────────
/** 后端文件代理根路径 */
export const FILES = '/api/files'

/**
 * 构造文件代理完整 URL（用于 SVG / PDF 等需要带 token 直接拉取的资源）
 *
 * @param storagePath 后端返回的相对路径（如 `floors/{building_id}/{floor_id}.svg`）
 * @returns 完整 URL（如 `http://host:port/api/files/floors/.../xxx.svg`）
 */
export function buildFileProxyUrl(storagePath: string): string {
  const baseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? ''
  // 去掉 storagePath 前导斜杠，避免双斜杠
  const path = storagePath.startsWith('/') ? storagePath.slice(1) : storagePath
  return `${baseUrl}${FILES}/${path}`
}
