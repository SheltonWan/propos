/**
 * 资产模块类型定义
 * 字段命名严格遵循 docs/backend/API_CONTRACT_v1.7.md
 */

// ─── 枚举 ───────────────────────────────────────────────────────────────────

/** 业态：写字楼 / 商铺 / 公寓 / 综合体（仅楼栋） */
export type PropertyType = 'office' | 'retail' | 'apartment' | 'mixed'

/** 房源当前状态 */
export type UnitStatus =
  | 'leased' // 已租
  | 'vacant' // 空置
  | 'expiring_soon' // 即将到期
  | 'non_leasable' // 非可租
  | 'renovating' // 装修中
  | 'pre_lease' // 预租

/** 朝向 */
export type Orientation = 'east' | 'south' | 'west' | 'north'

/** 装修状态 */
export type DecorationStatus = 'blank' | 'simple' | 'refined' | 'raw'

// ─── 楼栋 ───────────────────────────────────────────────────────────────────

export interface Building {
  id: string
  name: string
  property_type: PropertyType
  total_floors: number
  basement_floors: number
  gfa: number // 建筑面积 m²
  nla: number // 净可租面积 m²
  address: string
  built_year: number | null
  created_at: string
  updated_at: string
}

// ─── 楼层 ───────────────────────────────────────────────────────────────────

export interface Floor {
  id: string
  building_id: string
  building_name: string
  floor_number: number
  floor_name: string
  svg_path: string | null
  png_path: string | null
  nla: number
  created_at: string
  updated_at: string
}

/** 楼层热区单元（仅含状态可视化所需字段） */
export interface FloorHeatmapUnit {
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
  units: FloorHeatmapUnit[]
}

export interface FloorPlan {
  id: string
  floor_id: string
  version: number
  svg_path: string | null
  png_path: string | null
  is_current: boolean
  uploaded_by: string | null
  uploaded_at: string
}

// ─── 房源 ───────────────────────────────────────────────────────────────────

export interface Unit {
  id: string
  building_id: string
  building_name: string
  floor_id: string
  floor_name: string
  unit_number: string
  property_type: PropertyType
  gross_area: number
  net_area: number
  orientation: Orientation | null
  ceiling_height: number | null
  decoration_status: DecorationStatus | null
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

// ─── 列表查询参数 ───────────────────────────────────────────────────────────

export interface UnitListParams {
  building_id?: string
  floor_id?: string
  property_type?: PropertyType
  current_status?: UnitStatus
  is_leasable?: boolean
  page?: number
  pageSize?: number
}

// ─── 楼栋出租率聚合（前端计算） ────────────────────────────────────────────

export interface BuildingOccupancy {
  total: number
  leased: number
  vacant: number
  rate: number
}

// ─── 资产概览 API 响应（API_CONTRACT_v1.7.md §2.23） ──────────────────────

/** 后端 by_property_type 数组元素 */
export interface ApiPropertyTypeStats {
  property_type: PropertyType
  total_units: number
  leased_units: number
  vacant_units: number
  expiring_soon_units: number
  /** 出租率 0~1 小数（leased + expiring_soon 口径，与后端一致） */
  occupancy_rate: number
  total_nla: number
  leased_nla: number
}

/** GET /api/assets/overview 响应体 */
export interface AssetOverview {
  total_units: number
  total_leasable_units: number
  /** 总体出租率 0~1 小数 */
  total_occupancy_rate: number
  wale_income_weighted: number
  wale_area_weighted: number
  by_property_type: ApiPropertyTypeStats[]
}
