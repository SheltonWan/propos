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

/** 导入批次结果（对齐 API_CONTRACT_v1.7 §1A.7 DepartmentImportResult） */
export interface DepartmentImportResult {
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
