import type { ApiListResponse, ListParams } from '@/types/api'
import { BUILDINGS, FLOORS, UNITS } from '@/constants/api_paths'
import { apiDelete, apiGet, apiPost, apiPut } from '../client'

// ─── 楼宇 ─────────────────────────────────────────────────────────────────
export function getBuildings(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(BUILDINGS, params as Record<string, unknown>)
}

export function getBuilding(id: string) {
  return apiGet<unknown>(`${BUILDINGS}/${id}`)
}

export function createBuilding(data: Record<string, unknown>) {
  return apiPost<unknown>(BUILDINGS, data)
}

export function updateBuilding(id: string, data: Record<string, unknown>) {
  return apiPut<unknown>(`${BUILDINGS}/${id}`, data)
}

export function deleteBuilding(id: string) {
  return apiDelete(`${BUILDINGS}/${id}`)
}

// ─── 楼层 ─────────────────────────────────────────────────────────────────
export function getFloors(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(FLOORS, params as Record<string, unknown>)
}

export function getFloor(id: string) {
  return apiGet<unknown>(`${FLOORS}/${id}`)
}

// ─── 房源 ─────────────────────────────────────────────────────────────────
export function getUnits(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(UNITS, params as Record<string, unknown>)
}

export function getUnit(id: string) {
  return apiGet<unknown>(`${UNITS}/${id}`)
}

export function updateUnit(id: string, data: Record<string, unknown>) {
  return apiPut<unknown>(`${UNITS}/${id}`, data)
}
