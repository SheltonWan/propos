/**
 * M1 资产模块类型定义
 * 与 backend/lib/modules/assets/models/*.dart 字段一一对应
 */

/** 主业态 */
export type PropertyType = 'office' | 'retail' | 'apartment'

/** 单元出租状态 */
export type UnitStatus =
  | 'leased'
  | 'vacant'
  | 'expiring_soon'
  | 'non_leasable'
  | 'renovating'
  | 'pre_lease'

/** 装修状态 */
export type DecorationStatus = 'blank' | 'simple' | 'refined' | 'raw'

/** 朝向 */
export type Orientation = 'east' | 'south' | 'west' | 'north'

// ─── 楼栋 ──────────────────────────────────────────────

export interface Building {
  id: string
  name: string
  property_type: PropertyType
  total_floors: number
  gfa: number
  nla: number
  address: string | null
  built_year: number | null
  created_at: string
  updated_at: string
}

// ─── 楼层 ──────────────────────────────────────────────

export interface Floor {
  id: string
  building_id: string
  building_name: string | null
  floor_number: number
  floor_name: string | null
  svg_path: string | null
  png_path: string | null
  nla: number | null
  created_at: string
  updated_at: string
}

// ─── 楼层热区 ──────────────────────────────────────────

export interface HeatmapUnit {
  unit_id: string
  unit_number: string
  current_status: UnitStatus
  property_type: PropertyType
  tenant_name: string | null
  contract_end_date: string | null
}

export interface FloorHeatmap {
  floor_id: string
  svg_path: string | null
  units: HeatmapUnit[]
}

// ─── 楼层图纸版本 ──────────────────────────────────────

export interface FloorPlan {
  id: string
  floor_id: string
  version_label: string
  svg_path: string
  png_path: string | null
  is_current: boolean
  uploaded_by: string | null
  uploaded_by_name: string | null
  created_at: string
}

// ─── 单元 ──────────────────────────────────────────────

export interface Unit {
  id: string
  building_id: string
  building_name: string | null
  floor_id: string
  floor_name: string | null
  unit_number: string
  property_type: PropertyType
  gross_area: number | null
  net_area: number | null
  orientation: Orientation | null
  ceiling_height: number | null
  decoration_status: DecorationStatus
  current_status: UnitStatus
  is_leasable: boolean
  ext_fields: Record<string, unknown>
  current_contract_id: string | null
  qr_code: string | null
  market_rent_reference: number | null
  predecessor_unit_ids: string[]
  archived_at: string | null
  created_at: string
  updated_at: string
}

// ─── 改造记录 ──────────────────────────────────────────

export interface RenovationRecord {
  id: string
  unit_id: string
  unit_number: string | null
  renovation_type: string
  started_at: string
  completed_at: string | null
  cost: number | null
  contractor: string | null
  description: string | null
  before_photo_paths: string[]
  after_photo_paths: string[]
  created_by: string | null
  created_at: string
  updated_at: string
}

// ─── 资产概览 ──────────────────────────────────────────
// 字段口径严格遵循 docs/backend/API_CONTRACT_v1.7.md §2.23

export interface PropertyTypeStats {
  property_type: PropertyType
  total_units: number
  leased_units: number
  vacant_units: number
  expiring_soon_units: number
  occupancy_rate: number
  total_nla: number
  leased_nla: number
}

export interface AssetOverviewStats {
  total_units: number
  total_leasable_units: number
  total_occupancy_rate: number
  wale_income_weighted: number
  wale_area_weighted: number
  by_property_type: PropertyTypeStats[]
}

// ─── 列表查询参数 ──────────────────────────────────────

export interface UnitListParams {
  building_id?: string
  floor_id?: string
  property_type?: PropertyType
  current_status?: UnitStatus
  is_leasable?: boolean
  include_archived?: boolean
  page?: number
  page_size?: number
}

export interface RenovationListParams {
  unit_id?: string
  page?: number
  page_size?: number
}

// ─── 改造记录新增请求 ──────────────────────────────────

export interface RenovationCreateRequest {
  unit_id: string
  renovation_type: string
  started_at: string
  completed_at?: string | null
  cost?: number | null
  contractor?: string | null
  description?: string | null
}

// ─── 单元更新请求 ──────────────────────────────────────

export interface UnitUpdateRequest {
  unit_number?: string
  property_type?: PropertyType
  gross_area?: number | null
  net_area?: number | null
  orientation?: Orientation | null
  ceiling_height?: number | null
  decoration_status?: DecorationStatus
  is_leasable?: boolean
  market_rent_reference?: number | null
  ext_fields?: Record<string, unknown>
}

// ─── 导入批次 ──────────────────────────────────────────

export type ImportDataType = 'units' | 'contracts' | 'invoices'
export type ImportRollbackStatus = 'committed' | 'rolled_back'

export interface ImportError {
  row: number
  field: string
  error: string
}

export interface ImportBatchDetail {
  id: string
  batch_name: string
  data_type: ImportDataType
  total_records: number
  success_count: number
  failure_count: number
  rollback_status: ImportRollbackStatus
  is_dry_run: boolean
  error_details: ImportError[] | null
  source_file_path: string | null
  created_by: string | null
  created_at: string
}

// ─── 合同摘要（用于房源详情页展示当前租赁信息）────────

export interface ContractSummary {
  id: string
  contract_number: string
  status: string
  tenant_id: string | null
  tenant_name: string | null
  monthly_rent: number | null
  start_date: string | null
  end_date: string | null
}
