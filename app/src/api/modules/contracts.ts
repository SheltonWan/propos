import type { ApiListResponse, ListParams } from '@/types/api'
import { CONTRACTS, TENANTS } from '@/constants/api_paths'
import { apiDelete, apiGet, apiPost, apiPut } from '../client'

// ─── 合同 ─────────────────────────────────────────────────────────────────
export function getContracts(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(CONTRACTS, params as Record<string, unknown>)
}

export function getContract(id: string) {
  return apiGet<unknown>(`${CONTRACTS}/${id}`)
}

export function createContract(data: Record<string, unknown>) {
  return apiPost<unknown>(CONTRACTS, data)
}

export function updateContract(id: string, data: Record<string, unknown>) {
  return apiPut<unknown>(`${CONTRACTS}/${id}`, data)
}

export function deleteContract(id: string) {
  return apiDelete(`${CONTRACTS}/${id}`)
}

// ─── 租户 ─────────────────────────────────────────────────────────────────
export function getTenants(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(TENANTS, params as Record<string, unknown>)
}

export function getTenant(id: string) {
  return apiGet<unknown>(`${TENANTS}/${id}`)
}
