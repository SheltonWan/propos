/**
 * 用户管理 API 模块（对齐 API_INVENTORY v1.7 §一 + §七）
 * 端点：
 *   - GET    /api/users                     列表
 *   - GET    /api/users/:id                 详情
 *   - POST   /api/users                     创建
 *   - PATCH  /api/users/:id                 更新基本信息
 *   - PATCH  /api/users/:id/status          启停用
 *   - PATCH  /api/users/:id/role            变更角色
 *   - PATCH  /api/users/:id/department      变更部门
 *   - POST   /api/users/import              批量导入员工（v1.7 新增）
 */

import { apiGetList, apiGet, apiPost, apiPatch, apiPostForm } from '@/api/client'
import type { ApiListResponse } from '@/types/api'
import { API_USERS, API_USERS_IMPORT } from '@/constants/api_paths'
import type {
  UserSummary,
  UserDetail,
  UserListParams,
  UserCreateRequest,
  UserUpdateRequest,
  UserRole,
  UserImportResult,
} from '@/types/user'

/** GET /api/users */
export async function fetchUsers(
  params?: UserListParams,
): Promise<ApiListResponse<UserSummary>> {
  return apiGetList<UserSummary>(API_USERS, params as Record<string, unknown> | undefined)
}

/** GET /api/users/:id */
export async function fetchUser(id: string): Promise<UserDetail> {
  return apiGet<UserDetail>(`${API_USERS}/${id}`)
}

/** POST /api/users */
export async function createUser(payload: UserCreateRequest): Promise<UserDetail> {
  return apiPost<UserDetail>(API_USERS, payload)
}

/** PATCH /api/users/:id */
export async function updateUser(
  id: string,
  payload: UserUpdateRequest,
): Promise<UserDetail> {
  return apiPatch<UserDetail>(`${API_USERS}/${id}`, payload)
}

/** PATCH /api/users/:id/status */
export async function updateUserStatus(id: string, isActive: boolean): Promise<UserDetail> {
  return apiPatch<UserDetail>(`${API_USERS}/${id}/status`, { is_active: isActive })
}

/** PATCH /api/users/:id/role */
export async function updateUserRole(
  id: string,
  role: UserRole,
  boundContractId?: string | null,
): Promise<UserDetail> {
  const payload: Record<string, unknown> = { role }
  if (boundContractId !== undefined) payload.bound_contract_id = boundContractId
  return apiPatch<UserDetail>(`${API_USERS}/${id}/role`, payload)
}

/** PATCH /api/users/:id/department */
export async function updateUserDepartment(
  id: string,
  departmentId: string,
): Promise<UserDetail> {
  return apiPatch<UserDetail>(`${API_USERS}/${id}/department`, {
    department_id: departmentId,
  })
}

/** POST /api/users/import — Excel 批量导入员工（dry_run 预校验或正式入库） */
export async function importUsers(
  file: File,
  dryRun: boolean,
): Promise<UserImportResult> {
  const form = new FormData()
  form.append('file', file)
  form.append('dry_run', String(dryRun))
  return apiPostForm<UserImportResult>(API_USERS_IMPORT, form)
}
