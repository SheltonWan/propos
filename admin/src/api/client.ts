/**
 * Axios HTTP 客户端封装
 * 职责：JWT 注入 + Token 刷新 + 信封解析 + ApiError 转换
 * 与 app/src/api/client.ts 约定完全一致
 */

import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios'
import { ApiError } from '@/types/api'
import type { ApiResponse, ApiListResponse, ApiErrorBody } from '@/types/api'
import { API_AUTH_LOGIN, API_AUTH_REFRESH } from '@/constants/api_paths'
import router from '@/router'

// 开发模式：axios 使用相对路径，请求由 Vite proxy 转发到远程后端（VITE_API_BASE_URL 仅控制 proxy target）
// 生产模式：使用 VITE_API_BASE_URL 或同域空字符串
const BASE_URL: string = import.meta.env.DEV ? '' : (import.meta.env.VITE_API_BASE_URL ?? '')

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

    // 登录/刷新端点本身返回 401 时，不触发 token 刷新逻辑，直接走通用错误解析
    const isAuthEndpoint =
      originalRequest.url === API_AUTH_LOGIN || originalRequest.url === API_AUTH_REFRESH

    if (statusCode === 401 && !originalRequest._retry && !isAuthEndpoint) {
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

/** 携带响应头的扩展返回值，用于乐观锁 ETag 等场景 */
export interface WithHeaders<T> {
  data: T
  headers: Record<string, string>
}

interface RequestExtras {
  /** 自定义请求头（如 If-Match） */
  headers?: Record<string, string>
}

/** 仅当显式传入 withResponseHeaders=true 时才返回 WithHeaders<T> */
type GetOptions = RequestExtras & { params?: Record<string, unknown>; withResponseHeaders?: false }
type GetOptionsWithHeaders = RequestExtras & { params?: Record<string, unknown>; withResponseHeaders: true }

export async function apiGet<T>(url: string, options: GetOptionsWithHeaders): Promise<WithHeaders<T>>
export async function apiGet<T>(url: string, options: GetOptions): Promise<T>
export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T>
export async function apiGet<T>(
  url: string,
  arg?: Record<string, unknown> | GetOptions | GetOptionsWithHeaders,
): Promise<T | WithHeaders<T>> {
  const isOptions =
    arg !== undefined &&
    typeof arg === 'object' &&
    ('withResponseHeaders' in arg || 'headers' in arg || 'params' in arg)
  const params = isOptions ? (arg as GetOptions).params : (arg as Record<string, unknown> | undefined)
  const headers = isOptions ? (arg as GetOptions).headers : undefined
  const wantHeaders = isOptions ? (arg as GetOptionsWithHeaders).withResponseHeaders === true : false

  const res = await http.get<ApiResponse<T>>(url, { params, headers })
  if (wantHeaders) {
    return { data: res.data.data, headers: _normalizeHeaders(res.headers) }
  }
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

interface PutOptions extends RequestExtras {
  withResponseHeaders?: false
}
interface PutOptionsWithHeaders extends RequestExtras {
  withResponseHeaders: true
}

export async function apiPut<T>(url: string, data?: unknown, options?: PutOptions): Promise<T>
export async function apiPut<T>(
  url: string,
  data: unknown,
  options: PutOptionsWithHeaders,
): Promise<WithHeaders<T>>
export async function apiPut<T>(
  url: string,
  data?: unknown,
  options?: PutOptions | PutOptionsWithHeaders,
): Promise<T | WithHeaders<T>> {
  const res = await http.put<ApiResponse<T>>(url, data, { headers: options?.headers })
  if (options && (options as PutOptionsWithHeaders).withResponseHeaders === true) {
    return { data: res.data.data, headers: _normalizeHeaders(res.headers) }
  }
  return res.data.data
}

export async function apiDelete(url: string): Promise<void> {
  await http.delete(url)
}

/** 将 Axios 响应头规范化为小写键的纯对象 */
function _normalizeHeaders(headers: unknown): Record<string, string> {
  const out: Record<string, string> = {}
  if (headers && typeof headers === 'object') {
    for (const [k, v] of Object.entries(headers as Record<string, unknown>)) {
      if (v !== undefined && v !== null) {
        out[k.toLowerCase()] = String(v)
      }
    }
  }
  return out
}

/** 获取原始响应体（跳过 JSON 信封解包），适用于 SVG/文本等非 JSON 资源 */
export async function apiGetRaw<T>(
  url: string,
  config?: Record<string, unknown>,
): Promise<T> {
  const res = await http.get<T>(url, config)
  return res.data
}

/** multipart/form-data 上传（Excel 导入、文件上传等） */
export async function apiPostForm<T>(url: string, form: FormData): Promise<T> {
  const res = await http.post<ApiResponse<T>>(url, form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return res.data.data
}

export default http
