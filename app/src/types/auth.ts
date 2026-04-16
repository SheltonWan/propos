export type Role =
  | 'super_admin'
  | 'operations_manager'
  | 'leasing_specialist'
  | 'finance_staff'
  | 'maintenance_staff'
  | 'property_inspector'
  | 'report_viewer'
  | 'sub_landlord'

export type Permission =
  | 'org.read'
  | 'org.manage'
  | 'assets.read'
  | 'assets.write'
  | 'contracts.read'
  | 'contracts.write'
  | 'deposit.read'
  | 'deposit.write'
  | 'finance.read'
  | 'finance.write'
  | 'kpi.view'
  | 'kpi.manage'
  | 'kpi.appeal'
  | 'meterReading.write'
  | 'turnoverReview.approve'
  | 'workorders.read'
  | 'workorders.write'
  | 'sublease.read'
  | 'sublease.write'
  | 'alerts.read'
  | 'alerts.write'
  | 'ops.read'
  | 'ops.write'
  | 'import.execute'
  | 'users.manage'

export interface UserBrief {
  id: string
  name: string
  email: string
  role: Role
  department_id: string | null
  must_change_password: boolean
}

export interface CurrentUser {
  id: string
  name: string
  email: string
  role: Role
  department_id: string | null
  department_name: string | null
  permissions: Permission[]
  bound_contract_id: string | null
  is_active: boolean
  last_login_at: string | null
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  user: UserBrief
}

export interface TokenResponse {
  access_token: string
  refresh_token: string
  expires_in: number
}
