import type { ApiListResponse, ListParams } from '@/types/api'
import { SUPPLIERS, WORK_ORDERS } from '@/constants/api_paths'
import { apiDelete, apiGet, apiPatch, apiPost, apiPut } from '../client'

// ─── 工单 ─────────────────────────────────────────────────────────────────
export function getWorkOrders(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(WORK_ORDERS, params as Record<string, unknown>)
}

export function getWorkOrder(id: string) {
  return apiGet<unknown>(`${WORK_ORDERS}/${id}`)
}

export function createWorkOrder(data: Record<string, unknown>) {
  return apiPost<unknown>(WORK_ORDERS, data)
}

export function updateWorkOrder(id: string, data: Record<string, unknown>) {
  return apiPut<unknown>(`${WORK_ORDERS}/${id}`, data)
}

export function patchWorkOrder(id: string, data: Record<string, unknown>) {
  return apiPatch<unknown>(`${WORK_ORDERS}/${id}`, data)
}

export function deleteWorkOrder(id: string) {
  return apiDelete(`${WORK_ORDERS}/${id}`)
}

// ─── 供应商 ───────────────────────────────────────────────────────────────
export function getSuppliers(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(SUPPLIERS, params as Record<string, unknown>)
}

export function getSupplier(id: string) {
  return apiGet<unknown>(`${SUPPLIERS}/${id}`)
}
