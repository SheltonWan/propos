import type { HttpData, HttpError, HttpRequestConfig, HttpResponse } from 'luch-request'
import type { MockMethod } from './mock/types'
import type { ApiErrorResponse, ApiResponse } from '@/types/api'
import Request from 'luch-request'
import { AUTH_REFRESH } from '@/constants/api_paths'
import { ApiError } from '@/types/api'
import { matchMock } from './mock/index'

const BASE_URL = import.meta.env.VITE_API_BASE_URL as string || ''
const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true'

type RetryRequestConfig = HttpRequestConfig & {
  custom?: HttpRequestConfig['custom'] & {
    __retried?: boolean
  }
}

type PatchRequestConfig = Omit<HttpRequestConfig, 'method' | 'data'> & {
  method: 'PATCH'
  data?: HttpData
}

function asHttpData(data?: unknown): HttpData | undefined {
  if (data === undefined) {
    return undefined
  }

  return data as HttpData
}

// ─── Mock（USE_MOCK=false 时不执行任何 mock 逻辑）────────────────────────────
async function tryMock<T>(method: MockMethod, url: string, body?: unknown): Promise<{ hit: true, data: T } | { hit: false }> {
  if (!USE_MOCK)
    return { hit: false }
  const result = await matchMock<T>(method, url, body)
  if (result !== null)
    return { hit: true, data: result }
  return { hit: false }
}

const http = new Request({
  baseURL: BASE_URL,
  timeout: 15000,
  header: {
    'Content-Type': 'application/json',
  },
})

function requestWithPatch<T>(config: PatchRequestConfig) {
  return http.request<ApiResponse<T>>(config as unknown as HttpRequestConfig)
}

// ─── Token 管理 ────────────────────────────────────────────────────────────
function getAccessToken(): string | null {
  return uni.getStorageSync('access_token') || null
}

function getRefreshToken(): string | null {
  return uni.getStorageSync('refresh_token') || null
}

function setTokens(access: string, refresh: string): void {
  uni.setStorageSync('access_token', access)
  uni.setStorageSync('refresh_token', refresh)
}

function clearTokens(): void {
  uni.removeStorageSync('access_token')
  uni.removeStorageSync('refresh_token')
}

// ─── 请求拦截器 ─────────────────────────────────────────────────────────────
http.interceptors.request.use(
  (config: HttpRequestConfig) => {
    const token = getAccessToken()
    if (token) {
      config.header = { ...config.header, Authorization: `Bearer ${token}` }
    }
    return config
  },
  (error: unknown) => Promise.reject(error),
)

// ─── 刷新锁 ─────────────────────────────────────────────────────────────────
let isRefreshing = false
let refreshSubscribers: Array<(token: string) => void> = []

function onRefreshed(cb: (token: string) => void) {
  refreshSubscribers.push(cb)
}

function notifySubscribers(token: string) {
  refreshSubscribers.forEach(cb => cb(token))
  refreshSubscribers = []
}

// ─── 响应拦截器 ─────────────────────────────────────────────────────────────
http.interceptors.response.use(
  (response: HttpResponse) => {
    const data = response.data as Record<string, unknown>
    if (data && typeof data === 'object' && 'error' in data) {
      const err = data.error as { code: string, message: string }
      throw new ApiError(err.code, err.message, response.statusCode)
    }
    return response
  },
  async (error: HttpError<ApiErrorResponse>) => {
    const status = error.statusCode
    const errBody = error.data
    const requestConfig = error.config as RetryRequestConfig

    // 401 → 优先透传后台明确返回的业务错误（如 INVALID_CREDENTIALS），再尝试 refresh
    if (status === 401) {
      // 后台返回了具体错误信息时（如凭据无效、账号锁定），直接透传，不尝试刷新
      if (errBody?.error) {
        throw new ApiError(errBody.error.code, errBody.error.message, 401)
      }
      const refresh = getRefreshToken()
      if (refresh && !requestConfig.custom?.__retried) {
        if (!isRefreshing) {
          isRefreshing = true
          try {
            const res = await http.post<ApiResponse<{ access_token: string, refresh_token: string }>>(AUTH_REFRESH, {
              refresh_token: refresh,
            })
            const { access_token, refresh_token } = res.data.data
            setTokens(access_token, refresh_token)
            isRefreshing = false
            notifySubscribers(access_token)
          }
          catch {
            isRefreshing = false
            refreshSubscribers = []
            clearTokens()
            uni.reLaunch({ url: '/pages/auth/login' })
            throw new ApiError('TOKEN_EXPIRED', '登录已过期，请重新登录', 401)
          }
        }
        // 排队等待 refresh 完成
        return new Promise<HttpResponse>((resolve) => {
          onRefreshed((token) => {
            const retryConfig: RetryRequestConfig = {
              ...requestConfig,
              header: { ...requestConfig.header, Authorization: `Bearer ${token}` },
              custom: { ...requestConfig.custom, __retried: true },
            }
            resolve(http.request(retryConfig))
          })
        })
      }
      throw new ApiError('UNAUTHORIZED', '请先登录', 401)
    }

    if (errBody?.error) {
      throw new ApiError(errBody.error.code, errBody.error.message, status || 500)
    }
    throw new ApiError('NETWORK_ERROR', '网络异常，请检查网络连接', status || 0)
  },
)

// ─── 公共方法（含 mock 拦截：匹配则返回 mock 数据，未匹配则 fallthrough 真实 HTTP）──
export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const mock = await tryMock<T>('GET', url, params)
  if (mock.hit)
    return mock.data
  const res = await http.get<ApiResponse<T>>(url, { params })
  return res.data.data
}

export async function apiPost<T>(url: string, data?: unknown): Promise<T> {
  const mock = await tryMock<T>('POST', url, data)
  if (mock.hit)
    return mock.data
  const res = await http.post<ApiResponse<T>>(url, asHttpData(data))
  return res.data.data
}

export async function apiPut<T>(url: string, data?: unknown): Promise<T> {
  const mock = await tryMock<T>('PUT', url, data)
  if (mock.hit)
    return mock.data
  const res = await http.put<ApiResponse<T>>(url, asHttpData(data))
  return res.data.data
}

export async function apiPatch<T>(url: string, data?: unknown): Promise<T> {
  const mock = await tryMock<T>('PATCH', url, data)
  if (mock.hit)
    return mock.data
  const patchConfig: PatchRequestConfig = {
    url,
    method: 'PATCH',
    data: asHttpData(data),
  }
  const res = await requestWithPatch<T>(patchConfig)
  return res.data.data
}

export async function apiDelete<T = void>(url: string): Promise<T> {
  const mock = await tryMock<T>('DELETE', url)
  if (mock.hit)
    return mock.data
  const res = await http.delete<ApiResponse<T>>(url)
  return res.data.data
}

export { getRefreshToken, setTokens, clearTokens }
