/**
 * Axios HTTP 客户端封装
 * 职责：JWT 注入 + Token 刷新 + 信封解析 + ApiError 转换
 * 与 app/src/api/client.ts 约定完全一致
 */

import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios'
import { ApiError } from '@/types/api'
import type { ApiResponse, ApiListResponse, ApiErrorBody } from '@/types/api'
import { API_AUTH_REFRESH } from '@/constants/api_paths'
import router from '@/router'

const BASE_URL: string = import.meta.env.VITE_API_BASE_URL ?? ''

const http: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

// ── 请求拦截：注入 JWT ─────────────────────────────────
http.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// ── 响应拦截：信封解析 + 错误统一转换 ──────────────────
let isRefreshing = false
let refreshSubscribers: Array<(token: string) => void> = []

function subscribeRefresh(cb: (token: string) => void) {
  refreshSubscribers.push(cb)
}
function notifySubscribers(token: string) {
  refreshSubscribers.forEach((cb) => cb(token))
  refreshSubscribers = []
}

http.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean }
    const statusCode: number = error.response?.status ?? 0
    const body = error.response?.data as ApiErrorBody | undefined

    if (statusCode === 401 && !originalRequest._retry) {
      const refreshToken = localStorage.getItem('refresh_token')
      if (refreshToken && !isRefreshing) {
        isRefreshing = true
        originalRequest._retry = true
        try {
          const res = await http.post<ApiResponse<{ accessToken: string; refreshToken: string }>>(
            API_AUTH_REFRESH,
            { refreshToken },
          )
          const tokens = res.data.data
          localStorage.setItem('access_token', tokens.accessToken)
          localStorage.setItem('refresh_token', tokens.refreshToken)
          notifySubscribers(tokens.accessToken)
          isRefreshing = false
          // 重试原请求
          return http(originalRequest)
        } catch {
          isRefreshing = false
          refreshSubscribers = []
          _redirectToLogin()
          return Promise.reject(new ApiError('UNAUTHORIZED', '登录已过期，请重新登录', 401))
        }
      } else if (isRefreshing) {
        // 等待 token 刷新
        return new Promise((resolve) => {
          subscribeRefresh(() => resolve(http(originalRequest)))
        })
      } else {
        _redirectToLogin()
        return Promise.reject(new ApiError('UNAUTHORIZED', '请先登录', 401))
      }
    }

    const code = body?.error?.code ?? `HTTP_${statusCode}`
    const message = body?.error?.message ?? '服务异常，请稍后再试'
    return Promise.reject(new ApiError(code, message, statusCode))
  },
)

function _redirectToLogin() {
  localStorage.removeItem('access_token')
  localStorage.removeItem('refresh_token')
  router.replace('/login')
}

// ── 封装方法（解封装 data 字段）─────────────────────────

export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const res = await http.get<ApiResponse<T>>(url, { params })
  return res.data.data
}

export async function apiGetList<T>(
  url: string,
  params?: Record<string, unknown>,
): Promise<ApiListResponse<T>> {
  const res = await http.get<ApiListResponse<T>>(url, { params })
  return res.data
}

export async function apiPost<T>(url: string, data?: unknown): Promise<T> {
  const res = await http.post<ApiResponse<T>>(url, data)
  return res.data.data
}

export async function apiPatch<T>(url: string, data?: unknown): Promise<T> {
  const res = await http.patch<ApiResponse<T>>(url, data)
  return res.data.data
}

export async function apiDelete(url: string): Promise<void> {
  await http.delete(url)
}

export default http
