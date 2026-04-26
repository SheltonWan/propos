/**
 * 组织架构 DTO 类型（对齐 API_CONTRACT_v1.7 §1A.1–1A.4）
 */

/** 部门树节点 — DepartmentTree */
export interface DepartmentTree {
  id: string
  name: string
  parent_id: string | null
  level: number
  sort_order: number
  is_active: boolean
  children: DepartmentTree[]
  created_at: string
  updated_at: string
}

/** 创建部门请求体 */
export interface DepartmentCreateRequest {
  name: string
  parent_id?: string | null
  sort_order?: number
}

/** 更新部门请求体 */
export interface DepartmentUpdateRequest {
  name?: string
  parent_id?: string | null
  sort_order?: number
}

/** 导入批次结果 */
export interface DepartmentImportResult {
  batch_name: string
  total_records: number
  success_count: number
  failure_count: number
  rollback_status: 'committed' | 'rolled_back' | 'partial'
  error_details: { row: number; field: string; error: string }[]
}
