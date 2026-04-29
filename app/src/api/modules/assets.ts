import type { ApiListResponse } from '@/types/api'
import type {
  AssetOverview,
  Building,
  Floor,
  FloorHeatmap,
  FloorPlan,
  Unit,
  UnitListParams,
} from '@/types/assets'
import { ASSETS_OVERVIEW, BUILDINGS, FLOORS, UNITS } from '@/constants/api_paths'
import { apiGet, apiGetList, apiPatch } from '../client'

// ─── 资产概览 ───────────────────────────────────────────────────────────────

/** GET /api/assets/overview — 三业态聚合统计（后端计算，含 WALE + 出租率） */
export function fetchOverview(): Promise<AssetOverview> {
  return apiGet<AssetOverview>(ASSETS_OVERVIEW)
}

// ─── 楼栋 ───────────────────────────────────────────────────────────────────

/** 楼栋列表（不分页，<10 栋） */
export function fetchBuildings(): Promise<Building[]> {
  return apiGet<Building[]>(BUILDINGS)
}

export function fetchBuilding(id: string): Promise<Building> {
  return apiGet<Building>(`${BUILDINGS}/${id}`)
}

// ─── 楼层 ───────────────────────────────────────────────────────────────────

export function fetchFloors(buildingId?: string): Promise<Floor[]> {
  const params = buildingId ? { building_id: buildingId } : undefined
  return apiGet<Floor[]>(FLOORS, params)
}

export function fetchFloor(id: string): Promise<Floor> {
  return apiGet<Floor>(`${FLOORS}/${id}`)
}

export function fetchFloorHeatmap(floorId: string): Promise<FloorHeatmap> {
  return apiGet<FloorHeatmap>(`${FLOORS}/${floorId}/heatmap`)
}

export function fetchFloorPlans(floorId: string): Promise<FloorPlan[]> {
  return apiGet<FloorPlan[]>(`${FLOORS}/${floorId}/plans`)
}

// ─── 房源 ───────────────────────────────────────────────────────────────────

export function fetchUnits(params: UnitListParams = {}): Promise<ApiListResponse<Unit>> {
  return apiGetList<Unit>(UNITS, params as Record<string, unknown>)
}

export function fetchUnit(id: string): Promise<Unit> {
  return apiGet<Unit>(`${UNITS}/${id}`)
}

export function patchUnit(id: string, payload: Partial<Unit>): Promise<Unit> {
  return apiPatch<Unit>(`${UNITS}/${id}`, payload)
}
