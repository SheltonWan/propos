/**
 * M1 资产模块 API 函数
 * 端点清单：参考 docs/backend/API_INVENTORY_v1.7.md L66-88
 */

import { apiGet, apiGetList, apiPost, apiPatch } from '@/api/client'
import type { ApiListResponse } from '@/types/api'
import type {
  AssetOverviewStats,
  Building,
  Floor,
  FloorHeatmap,
  FloorPlan,
  RenovationListParams,
  RenovationRecord,
  Unit,
  UnitListParams,
} from '@/types/asset'
import {
  API_ASSETS_SUMMARY,
  API_BUILDINGS,
  API_FLOORS,
  API_FLOOR_PLANS,
  API_RENOVATIONS,
  API_UNITS,
} from '@/constants/api_paths'

// /api/assets/summary 是历史命名，新接口为 /api/assets/overview
const API_ASSETS_OVERVIEW = '/api/assets/overview'

// ─── 楼栋 ──────────────────────────────────────────────

/** GET /api/buildings — 楼栋列表（不分页） */
export async function fetchBuildings(): Promise<Building[]> {
  return apiGet<Building[]>(API_BUILDINGS)
}

/** GET /api/buildings/:id — 楼栋详情 */
export async function fetchBuilding(id: string): Promise<Building> {
  return apiGet<Building>(`${API_BUILDINGS}/${id}`)
}

/** POST /api/buildings — 创建楼栋 */
export async function createBuilding(payload: {
  name: string
  property_type: string
  total_floors: number
  gfa: number
  nla: number
  address?: string | null
  built_year?: number | null
}): Promise<Building> {
  return apiPost<Building>(API_BUILDINGS, payload)
}

/** PATCH /api/buildings/:id — 更新楼栋 */
export async function updateBuilding(
  id: string,
  payload: Partial<{
    name: string
    property_type: string
    total_floors: number
    gfa: number
    nla: number
    address: string | null
    built_year: number | null
  }>,
): Promise<Building> {
  return apiPatch<Building>(`${API_BUILDINGS}/${id}`, payload)
}

// ─── 楼层 ──────────────────────────────────────────────

/** GET /api/floors?building_id= — 楼层列表 */
export async function fetchFloors(buildingId?: string): Promise<Floor[]> {
  return apiGet<Floor[]>(API_FLOORS, buildingId ? { building_id: buildingId } : undefined)
}

/** GET /api/floors/:id — 楼层详情 */
export async function fetchFloor(id: string): Promise<Floor> {
  return apiGet<Floor>(`${API_FLOORS}/${id}`)
}

/** GET /api/floors/:id/heatmap — 楼层热区状态图 */
export async function fetchFloorHeatmap(floorId: string): Promise<FloorHeatmap> {
  return apiGet<FloorHeatmap>(`${API_FLOORS}/${floorId}/heatmap`)
}

/** GET /api/floors/:id/plans — 图纸版本列表 */
export async function fetchFloorPlans(floorId: string): Promise<FloorPlan[]> {
  return apiGet<FloorPlan[]>(`${API_FLOORS}/${floorId}/plans`)
}

/** PATCH /api/floor-plans/:id/set-current — 设为当前生效版本 */
export async function setCurrentFloorPlan(planId: string): Promise<FloorPlan> {
  return apiPatch<FloorPlan>(`${API_FLOOR_PLANS}/${planId}/set-current`)
}

// ─── 单元 ──────────────────────────────────────────────

/** GET /api/units — 单元分页列表 */
export async function fetchUnits(
  params: UnitListParams = {},
): Promise<ApiListResponse<Unit>> {
  return apiGetList<Unit>(API_UNITS, params as Record<string, unknown>)
}

/** GET /api/units/:id — 单元详情 */
export async function fetchUnit(id: string): Promise<Unit> {
  return apiGet<Unit>(`${API_UNITS}/${id}`)
}

/** PATCH /api/units/:id — 更新单元 */
export async function updateUnit(id: string, payload: Partial<Unit>): Promise<Unit> {
  return apiPatch<Unit>(`${API_UNITS}/${id}`, payload)
}

// ─── 改造记录 ──────────────────────────────────────────

/** GET /api/renovations — 改造记录列表 */
export async function fetchRenovations(
  params: RenovationListParams = {},
): Promise<ApiListResponse<RenovationRecord>> {
  return apiGetList<RenovationRecord>(API_RENOVATIONS, params as Record<string, unknown>)
}

// ─── 资产概览 ──────────────────────────────────────────

/** GET /api/assets/overview — 三业态概览统计 */
export async function fetchAssetOverview(): Promise<AssetOverviewStats> {
  return apiGet<AssetOverviewStats>(API_ASSETS_OVERVIEW)
}

/** 兼容旧名 /api/assets/summary（如未来需要恢复使用） */
export const ASSETS_SUMMARY_PATH = API_ASSETS_SUMMARY
