/**
 * 用户管理 DTO 类型（对齐 API_CONTRACT_v1.7 §1.5–1.11）
 */

export type UserRole =
  | 'super_admin'
  | 'operations_manager'
  | 'leasing_specialist'
  | 'finance_staff'
  | 'maintenance_staff'
  | 'property_inspector'
  | 'report_viewer'
  | 'sub_landlord'

/** 用户角色中文标签 */
export const USER_ROLE_LABELS: Record<UserRole, string> = {
  super_admin: '超级管理员',
  operations_manager: '运营管理',
  leasing_specialist: '租务专员',
  finance_staff: '财务人员',
  maintenance_staff: '维修技工',
  property_inspector: '楼管巡检员',
  report_viewer: '只读观察者',
  sub_landlord: '二房东',
}

/** 用户列表项 — 对齐 §1.5 UserSummary */
export interface UserSummary {
  id: string
  name: string
  email: string
  role: UserRole
  department_id: string | null
  department_name: string | null
  is_active: boolean
  last_login_at: string | null
  created_at: string
}

/** 用户详情 — 对齐 §1.6 UserDetail */
export interface UserDetail extends UserSummary {
  bound_contract_id: string | null
  failed_login_attempts: number
  locked_until: string | null
  password_changed_at: string | null
  frozen_at: string | null
  frozen_reason: string | null
  updated_at: string
}

/** 列表查询参数 */
export interface UserListParams {
  search?: string
  role?: UserRole
  department_id?: string
  is_active?: boolean
  page?: number
  pageSize?: number
}

/** 创建用户请求体 — §1.7 */
export interface UserCreateRequest {
  name: string
  email: string
  password: string
  role: UserRole
  department_id?: string | null
  bound_contract_id?: string | null
}

/** 更新基本信息请求体 — §1.8 */
export interface UserUpdateRequest {
  name?: string
  email?: string
}

/** 用户导入批次结果（对齐 API_CONTRACT_v1.7 §1.15 UserImportResult） */
export interface UserImportResult {
  batch_id: string
  batch_name: string
  dry_run: boolean
  total_records: number
  success_count: number
  failure_count: number
  /** 试运行恒为 'none'；正式提交：成功为 'committed'，含失败行为 'rolled_back' */
  rollback_status: 'none' | 'committed' | 'rolled_back'
  error_details: { row: number; code: string; message: string }[]
}
