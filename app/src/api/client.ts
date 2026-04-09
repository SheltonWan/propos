/**
 * HTTP 客户端封装
 * 基于 luch-request，支持所有 uni-app 平台（iOS / Android / HarmonyOS / 微信 / H5）
 *
 * 职责：
 *  1. 统一注入 Authorization: Bearer <token>
 *  2. 解析后端信封格式，成功时返回 data 字段
 *  3. 错误时统一抛出 ApiError（业务码 + message），不透传原始响应
 *  4. 401 时自动尝试 Token 刷新一次，仍失败则跳转登录页
 */

import Request from 'luch-request'
import type { HttpRequestConfig, HttpData, HttpMethod } from 'luch-request'
import { ApiError } from '@/types/api'
import type { ApiResponse, ApiListResponse, ApiErrorBody } from '@/types/api'
import { API_AUTH_REFRESH } from '@/constants/api_paths'

// 后端基础地址：开发时通过 vite env 注入，生产通过 manifest.json 的 h5.devServer.proxy 代理
const BASE_URL: string = (import.meta.env.VITE_API_BASE_URL as string) ?? ''

const http = new Request({
  baseURL: BASE_URL,
  timeout: 15000,
  header: {
    'Content-Type': 'application/json',
  },
})

// ── 请求拦截：注入 JWT ─────────────────────────────────
http.interceptors.request.use((config: HttpRequestConfig) => {
  const token = uni.getStorageSync('access_token') as string | undefined
  if (token) {
    config.header = {
      ...config.header,
      Authorization: `Bearer ${token}`,
    }
  }
  return config
})

// ── 响应拦截：信封解析 + 错误统一转换 ──────────────────
let isRefreshing = false
let refreshSubscribers: Array<(token: string) => void> = []

http.interceptors.response.use(
  (response) => {
    // luch-request 已将 HTTP 200 系列的响应传到此处
    // 直接返回原始 response（在 get/post 等封装里再解封装 data）
    return response
  },
  async (error) => {
    const statusCode: number = error.statusCode ?? 0
    const body = error.data as ApiErrorBody | undefined

    // 401 → 自动刷新 Token
    if (statusCode === 401 && !isRefreshing) {
      const refreshToken = uni.getStorageSync('refresh_token') as string | undefined
      if (refreshToken) {
        isRefreshing = true
        try {
          const res = await http.post<ApiResponse<{ accessToken: string; refreshToken: string }>>(
            API_AUTH_REFRESH,
            { refreshToken },
          )
          const tokens = res.data.data
          uni.setStorageSync('access_token', tokens.accessToken)
          uni.setStorageSync('refresh_token', tokens.refreshToken)
          refreshSubscribers.forEach((cb) => cb(tokens.accessToken))
          refreshSubscribers = []
          isRefreshing = false
          // 原请求重试由调用方处理（简化：直接告知 token 已刷新）
          throw new ApiError('TOKEN_REFRESHED', '已刷新 Token，请重试', 401)
        } catch {
          isRefreshing = false
          refreshSubscribers = []
          _redirectToLogin()
          throw new ApiError('UNAUTHORIZED', '登录已过期，请重新登录', 401)
        }
      } else {
        _redirectToLogin()
        throw new ApiError('UNAUTHORIZED', '请先登录', 401)
      }
    }

    // 其他错误：从信封提取 code + message
    const code = body?.error?.code ?? `HTTP_${statusCode}`
    const message = body?.error?.message ?? '服务异常，请稍后再试'
    throw new ApiError(code, message, statusCode)
  },
)

function _redirectToLogin() {
  uni.removeStorageSync('access_token')
  uni.removeStorageSync('refresh_token')
  uni.reLaunch({ url: '/pages/auth/login' })
}

// ── 封装方法（解封装 data 字段）─────────────────────────

/** 获取单对象 */
export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const res = await http.get<ApiResponse<T>>(url, { params })
  return res.data.data
}

/** 获取列表（含分页 meta） */
export async function apiGetList<T>(
  url: string,
  params?: Record<string, unknown>,
): Promise<ApiListResponse<T>> {
  const res = await http.get<ApiListResponse<T>>(url, { params })
  return res.data
}

/** POST 创建 */
export async function apiPost<T>(url: string, data?: HttpData): Promise<T> {
  const res = await http.post<ApiResponse<T>>(url, data)
  return res.data.data
}

/** PATCH 局部更新 */
export async function apiPatch<T>(url: string, data?: HttpData): Promise<T> {
  // luch-request 3.1.1 HttpMethod 类型定义缺失 PATCH，运行时实际支持，此处做类型断言
  const res = await http.request<ApiResponse<T>>({ url, method: 'PATCH' as unknown as HttpMethod, data })
  return res.data.data
}

/** DELETE */
export async function apiDelete(url: string): Promise<void> {
  await http.delete(url)
}

export default http
