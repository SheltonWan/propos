/**
 * API 客户端 client.ts 单元测试
 *
 * 覆盖范围：
 * - 请求拦截器：JWT 注入
 * - 响应拦截器：401 token 刷新、并发防重入、刷新失败跳转
 * - 认证端点 401 不触发刷新循环
 * - 错误信封解析为 ApiError
 * - apiGet / apiGetList / apiPost / apiPatch / apiDelete 信封解包
 */

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import MockAdapter from 'axios-mock-adapter'
import http, { apiDelete, apiGet, apiGetList, apiPatch, apiPost } from '@/api/client'
import { ApiError } from '@/types/api'
import { API_AUTH_LOGIN, API_AUTH_REFRESH } from '@/constants/api_paths'

// mock vue-router，避免 client.ts 顶层 import router 触发路由初始化
vi.mock('@/router', () => ({
  default: {
    replace: vi.fn(),
    currentRoute: { value: { query: {} } },
  },
}))

import router from '@/router'

let mock: MockAdapter

beforeEach(() => {
  // 创建 mock 适配器，wraps 已有 http 实例
  mock = new MockAdapter(http, { onNoMatch: 'throwException' })
  localStorage.clear()
  vi.mocked(router.replace).mockReset()
})

afterEach(() => {
  mock.restore()
})

// ─── 请求拦截器 ────────────────────────────────────────────────────────────

describe('请求拦截器 — JWT 注入', () => {
  it('有 access_token 时注入 Authorization 头', async () => {
    localStorage.setItem('access_token', 'test-jwt-token')
    mock.onGet('/api/test').reply((config) => {
      expect(config.headers?.Authorization).toBe('Bearer test-jwt-token')
      return [200, { data: { ok: true } }]
    })
    await apiGet<{ ok: boolean }>('/api/test')
  })

  it('无 access_token 时不注入 Authorization 头', async () => {
    mock.onGet('/api/test').reply((config) => {
      expect(config.headers?.Authorization).toBeUndefined()
      return [200, { data: {} }]
    })
    await apiGet('/api/test')
  })
})

// ─── 响应拦截器：401 刷新链路 ──────────────────────────────────────────────

describe('响应拦截器 — Token 刷新', () => {
  it('401 时调用 refresh 接口并重试原请求', async () => {
    localStorage.setItem('access_token', 'old-token')
    localStorage.setItem('refresh_token', 'old-refresh')

    // 1. 首次 /api/data 返回 401
    // 2. refresh 成功返回新 token
    // 3. 重试 /api/data 返回 200
    let dataCallCount = 0
    mock.onGet('/api/data').reply(() => {
      dataCallCount += 1
      if (dataCallCount === 1) {
        return [401, { error: { code: 'UNAUTHORIZED', message: '未授权' } }]
      }
      return [200, { data: { result: 'ok' } }]
    })
    mock.onPost(API_AUTH_REFRESH).reply(200, {
      data: { accessToken: 'new-token', refreshToken: 'new-refresh' },
    })

    const result = await apiGet<{ result: string }>('/api/data')
    expect(result.result).toBe('ok')
    expect(dataCallCount).toBe(2)
    expect(localStorage.getItem('access_token')).toBe('new-token')
    expect(localStorage.getItem('refresh_token')).toBe('new-refresh')
  })

  it('并发 401 只刷新一次，所有请求共享新 token', async () => {
    localStorage.setItem('access_token', 'old-token')
    localStorage.setItem('refresh_token', 'old-refresh')

    let refreshCallCount = 0
    let dataCallCount = 0

    mock.onGet('/api/data').reply(() => {
      dataCallCount += 1
      if (dataCallCount <= 3) {
        return [401, { error: { code: 'UNAUTHORIZED', message: '未授权' } }]
      }
      return [200, { data: { result: 'ok' } }]
    })

    mock.onPost(API_AUTH_REFRESH).reply(() => {
      refreshCallCount += 1
      return [200, { data: { accessToken: 'shared-new-token', refreshToken: 'new-refresh' } }]
    })

    // 3 个并发请求
    const [r1, r2, r3] = await Promise.all([
      apiGet('/api/data'),
      apiGet('/api/data'),
      apiGet('/api/data'),
    ])

    expect(refreshCallCount).toBe(1)
    expect(r1).toEqual({ result: 'ok' })
    expect(r2).toEqual({ result: 'ok' })
    expect(r3).toEqual({ result: 'ok' })
  })

  it('无 refresh_token 时直接跳转登录页', async () => {
    localStorage.setItem('access_token', 'old-token')
    // 不存 refresh_token

    mock.onGet('/api/data').reply(401, {
      error: { code: 'UNAUTHORIZED', message: '未授权' },
    })

    await expect(apiGet('/api/data')).rejects.toBeInstanceOf(ApiError)
    expect(router.replace).toHaveBeenCalledWith('/login')
  })

  it('refresh 接口失败时清空 token 并跳转登录页', async () => {
    localStorage.setItem('access_token', 'old-token')
    localStorage.setItem('refresh_token', 'bad-refresh')

    mock.onGet('/api/data').reply(401, {
      error: { code: 'UNAUTHORIZED', message: '未授权' },
    })
    mock.onPost(API_AUTH_REFRESH).reply(401, {
      error: { code: 'UNAUTHORIZED', message: 'refresh token 已失效' },
    })

    const err = (await apiGet("/api/data").catch((e) => e)) as ApiError;
    expect(err).toBeInstanceOf(ApiError)
    expect(err.code).toBe('UNAUTHORIZED')
    expect(err.statusCode).toBe(401)
    expect(localStorage.getItem('access_token')).toBeNull()
    expect(localStorage.getItem('refresh_token')).toBeNull()
    expect(router.replace).toHaveBeenCalledWith('/login')
  })

  it('登录端点自身 401 不触发刷新循环', async () => {
    mock.onPost(API_AUTH_LOGIN).reply(401, {
      error: { code: 'INVALID_CREDENTIALS', message: '用户名或密码错误' },
    })

    const err = (await apiPost(API_AUTH_LOGIN, {
      email: "x@x.com",
      password: "wrong",
    }).catch((e) => e)) as ApiError;
    expect(err).toBeInstanceOf(ApiError)
    expect(err.code).toBe('INVALID_CREDENTIALS')
    // refresh 接口不被调用
    expect(mock.history.post.filter((r) => r.url === API_AUTH_REFRESH)).toHaveLength(0)
  })

  it('refresh 端点自身 401 不触发刷新循环', async () => {
    localStorage.setItem('refresh_token', 'token')
    mock.onPost(API_AUTH_REFRESH).reply(401, {
      error: { code: 'UNAUTHORIZED', message: '未授权' },
    })

    const err = await apiPost(API_AUTH_REFRESH, { refreshToken: 'token' }).catch((e) => e)
    expect(err).toBeInstanceOf(ApiError)
    // 只有 1 次 refresh 请求（本身），没有再触发第二次
    expect(mock.history.post.filter((r) => r.url === API_AUTH_REFRESH)).toHaveLength(1)
  })
})

// ─── 错误信封解析 ──────────────────────────────────────────────────────────

describe('响应拦截器 — 错误信封解析', () => {
  it('404 后端信封错误转换为 ApiError（code + message + statusCode）', async () => {
    mock.onGet('/api/contracts/xxx').reply(404, {
      error: { code: 'CONTRACT_NOT_FOUND', message: '合同不存在' },
    })

    const err = (await apiGet("/api/contracts/xxx").catch(
      (e) => e,
    )) as ApiError;
    expect(err).toBeInstanceOf(ApiError)
    expect(err.code).toBe('CONTRACT_NOT_FOUND')
    expect(err.message).toBe('合同不存在')
    expect(err.statusCode).toBe(404)
  })

  it('没有错误体时使用默认消息', async () => {
    mock.onGet('/api/test').reply(500)

    const err = (await apiGet("/api/test").catch((e) => e)) as ApiError;
    expect(err).toBeInstanceOf(ApiError)
    expect(err.code).toBe('HTTP_500')
    expect(err.message).toBe('服务异常，请稍后再试')
  })

  it('网络错误（status=0）', async () => {
    mock.onGet('/api/test').networkError()

    const err = await apiGet('/api/test').catch((e) => e)
    expect(err).toBeInstanceOf(ApiError)
  })
})

// ─── 封装方法信封解包 ──────────────────────────────────────────────────────

describe('apiGet — 信封解包', () => {
  it('返回 data 字段内容', async () => {
    mock.onGet('/api/buildings').reply(200, { data: [{ id: '1', name: '楼A' }] })
    const result = await apiGet<{ id: string; name: string }[]>('/api/buildings')
    expect(result).toEqual([{ id: '1', name: '楼A' }])
  })

  it('带 params 传递查询字符串', async () => {
    mock.onGet('/api/units', { params: { page: '2', pageSize: '20' } }).reply(200, { data: [] })
    const result = await apiGet('/api/units', { page: '2', pageSize: '20' })
    expect(result).toEqual([])
  })
})

describe('apiGetList — 信封解包含 meta', () => {
  it('返回 { data, meta } 完整结构', async () => {
    mock.onGet('/api/users').reply(200, {
      data: [{ id: 'u1' }],
      meta: { page: 1, pageSize: 20, total: 1 },
    })
    const result = await apiGetList<{ id: string }>('/api/users')
    expect(result.data).toEqual([{ id: 'u1' }])
    expect(result.meta.total).toBe(1)
  })
})

describe('apiPost — 发送 body 并解包 data', () => {
  it('POST body 正确传递', async () => {
    mock.onPost('/api/buildings', { name: '新楼' }).reply(201, { data: { id: 'b1', name: '新楼' } })
    const result = await apiPost<{ id: string }>('/api/buildings', { name: '新楼' })
    expect(result.id).toBe('b1')
  })
})

describe('apiPatch — 发送 body 并解包 data', () => {
  it('PATCH body 正确传递', async () => {
    mock.onPatch('/api/units/u1', { current_status: 'vacant' }).reply(200, {
      data: { id: 'u1', current_status: 'vacant' },
    })
    const result = await apiPatch<{ id: string; current_status: string }>('/api/units/u1', {
      current_status: 'vacant',
    })
    expect(result.current_status).toBe('vacant')
  })
})

describe('apiDelete — 无返回体', () => {
  it('DELETE 请求成功无异常', async () => {
    mock.onDelete('/api/buildings/b1').reply(204)
    await expect(apiDelete('/api/buildings/b1')).resolves.toBeUndefined()
  })
})
