import type { ApiListResponse, ListParams } from '@/types/api'
import { DEPOSITS, EXPENSES, INVOICES, PAYMENTS } from '@/constants/api_paths'
import { apiDelete, apiGet, apiPost, apiPut } from '../client'

// ─── 账单 ─────────────────────────────────────────────────────────────────
export function getInvoices(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(INVOICES, params as Record<string, unknown>)
}

export function getInvoice(id: string) {
  return apiGet<unknown>(`${INVOICES}/${id}`)
}

export function createInvoice(data: Record<string, unknown>) {
  return apiPost<unknown>(INVOICES, data)
}

export function updateInvoice(id: string, data: Record<string, unknown>) {
  return apiPut<unknown>(`${INVOICES}/${id}`, data)
}

export function deleteInvoice(id: string) {
  return apiDelete(`${INVOICES}/${id}`)
}

// ─── 收款 ─────────────────────────────────────────────────────────────────
export function getPayments(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(PAYMENTS, params as Record<string, unknown>)
}

export function getPayment(id: string) {
  return apiGet<unknown>(`${PAYMENTS}/${id}`)
}

export function createPayment(data: Record<string, unknown>) {
  return apiPost<unknown>(PAYMENTS, data)
}

// ─── 押金 ─────────────────────────────────────────────────────────────────
export function getDeposits(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(DEPOSITS, params as Record<string, unknown>)
}

export function getDeposit(id: string) {
  return apiGet<unknown>(`${DEPOSITS}/${id}`)
}

// ─── 费用 ─────────────────────────────────────────────────────────────────
export function getExpenses(params?: ListParams) {
  return apiGet<ApiListResponse<unknown>>(EXPENSES, params as Record<string, unknown>)
}

export function getExpense(id: string) {
  return apiGet<unknown>(`${EXPENSES}/${id}`)
}

export function createExpense(data: Record<string, unknown>) {
  return apiPost<unknown>(EXPENSES, data)
}
