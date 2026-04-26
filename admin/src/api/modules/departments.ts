/**
 * 组织架构 API 模块（对齐 API_INVENTORY v1.7 §一-A）
 * 端点：
 *   - GET    /api/departments               树列表
 *   - POST   /api/departments               创建
 *   - PATCH  /api/departments/:id           更新（名称/排序/父级）
 *   - DELETE /api/departments/:id           停用（逻辑删除）
 *   - POST   /api/departments/import        批量导入（v1.7 新增）
 */

import { apiGet, apiPost, apiPatch, apiDelete, apiPostForm } from '@/api/client'
import { API_DEPARTMENTS, API_DEPARTMENTS_IMPORT } from '@/constants/api_paths'
import type {
  DepartmentTree,
  DepartmentCreateRequest,
  DepartmentUpdateRequest,
  DepartmentImportResult,
} from '@/types/department'

/** GET /api/departments */
export async function fetchDepartmentTree(): Promise<DepartmentTree[]> {
  return apiGet<DepartmentTree[]>(API_DEPARTMENTS)
}

/** POST /api/departments */
export async function createDepartment(
  payload: DepartmentCreateRequest,
): Promise<DepartmentTree> {
  return apiPost<DepartmentTree>(API_DEPARTMENTS, payload)
}

/** PATCH /api/departments/:id */
export async function updateDepartment(
  id: string,
  payload: DepartmentUpdateRequest,
): Promise<DepartmentTree> {
  return apiPatch<DepartmentTree>(`${API_DEPARTMENTS}/${id}`, payload)
}

/** DELETE /api/departments/:id（逻辑删除：is_active=false） */
export async function deactivateDepartment(id: string): Promise<void> {
  await apiDelete(`${API_DEPARTMENTS}/${id}`)
}

/** POST /api/departments/import */
export async function importDepartments(
  file: File,
  dryRun: boolean,
): Promise<DepartmentImportResult> {
  const form = new FormData()
  form.append('file', file)
  form.append('dry_run', String(dryRun))
  return apiPostForm<DepartmentImportResult>(API_DEPARTMENTS_IMPORT, form)
}
