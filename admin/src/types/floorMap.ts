/**
 * Floor Map v2 类型定义
 * 严格对齐 docs/backend/schemas/floor_map.v2.schema.json
 *
 * 注意：
 *  - StructureType 仅 6 种（column 是独立联合分支，使用 point 而非 rect）
 *  - schema 顶层 additionalProperties:false，不允许写入 floor_map_updated_at（通过 ETag 头部承载）
 *  - PUT 请求时所有 structure 的 source 必须为 'manual'
 */

export type StructureType =
  | 'core'
  | 'elevator'
  | 'stair'
  | 'restroom'
  | 'equipment'
  | 'corridor'

export type AnyStructureType = StructureType | 'column'

export type Source = 'auto' | 'manual'

export interface Rect {
  x: number
  y: number
  w: number
  h: number
}

export interface Structure {
  type: StructureType
  rect: Rect
  label?: string | null
  /** elevator 必填，正则 ^[A-Z]\d{1,3}$ */
  code?: string | null
  /** restroom 必填 */
  gender?: 'M' | 'F' | 'unknown' | null
  source: Source
  /** 仅 source=auto 时存在，[0, 1] */
  confidence?: number
}

export interface Column {
  type: 'column'
  /** 注意：column 用 point，不用 rect */
  point: [number, number]
  source: Source
  confidence?: number
}

export type StructureOrColumn = Structure | Column

export interface WindowSegment {
  side: 'N' | 'S' | 'E' | 'W'
  /** 沿所属边的偏移（像素） */
  offset: number
  /** 沿所属边的长度（像素），≥ 8 */
  width: number
}

/** schema 限制长度 3~32 */
export type PointArray = [number, number][]

export interface Outline {
  type: 'rect' | 'polygon'
  rect?: Rect
  points?: PointArray
}

export interface Unit {
  unit_id: string
  label: string
  polygon: PointArray
  centroid?: [number, number]
  area_sqm?: number
  property_type?: 'office' | 'retail' | 'apartment'
}

export interface FloorMapV2 {
  schema_version: '2.0'
  render_mode: 'vector' | 'semantic'
  viewport: { width: number; height: number }
  outline: Outline
  structures: StructureOrColumn[]
  windows?: WindowSegment[]
  north?: { x: number; y: number; rotation_deg?: number } | null
  units?: Unit[]
  floor_id?: string | null
  building_id?: string | null
  floor_label?: string | null
  svg_version?: string | null
  dxf_region?: { min_x: number; min_y: number; max_x: number; max_y: number } | null
}

/** type guard：判断 StructureOrColumn 是否为 column */
export const isColumn = (s: StructureOrColumn): s is Column => s.type === 'column'

/** PATCH /api/floors/:id/render-mode 响应体 */
export interface RenderModeChangeResult {
  floor_id: string
  render_mode: 'vector' | 'semantic'
  render_mode_changed_at: string
  changed_by: string
}
