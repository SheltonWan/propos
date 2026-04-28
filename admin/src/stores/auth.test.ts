/**
 * useAuthStore 单元测试
 *
 * 覆盖范围：
 * - login()：成功路径（token 存储 + profile 填充 + 路由跳转）
 * - login()：失败路径（error.value 设置）
 * - login()：403 特例（clearTokens 调用，不 logout）
 * - login()：loading 状态变化
 * - fetchMe()：成功（profile 填充）
 * - fetchMe()：非 403 错误（自动 logout）
 * - fetchMe()：403（不 logout，重新抛出）
 * - logout()：revokeSession=true / false
 * - computed：isLoggedIn / role
 */

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/types/api'

// ── Mock 外部依赖 ──────────────────────────────────────

vi.mock('@/api/modules/auth', () => ({
  login: vi.fn(),
  logout: vi.fn(),
  // clearTokens 实际清空 localStorage，与生产代码行为一致
  clearTokens: vi.fn(() => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
  }),
}))

vi.mock('@/api/client', () => ({
  apiGet: vi.fn(),
  default: {},
}))

vi.mock('@/router', () => ({
  default: {
    replace: vi.fn(),
    currentRoute: { value: { query: {} } },
  },
}))

import { login as mockLogin, logout as mockLogout, clearTokens } from '@/api/modules/auth'
import { apiGet as mockApiGet } from '@/api/client'
import router from '@/router'

// ── 测试数据 ───────────────────────────────────────────

const fakeProfile = {
  id: 'u1',
  name: '张三',
  email: 'zhang@propos.com',
  role: 'admin',
  departmentId: 'd1',
}

const fakeLoginResponse = {
  access_token: 'access-abc',
  refresh_token: 'refresh-xyz',
  expires_in: 86400,
  user: fakeProfile,
}

// ── 测试套件 ───────────────────────────────────────────

describe('useAuthStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    vi.clearAllMocks()
    // router mock 重置
    vi.mocked(router.replace).mockResolvedValue(undefined as never)
    vi.mocked(router.currentRoute).value.query = {}
  })

  // ── 初始状态 ──────────────────────────────────────────

  describe('初始状态', () => {
    it('profile 为 null，loading 为 false，error 为 null', () => {
      const store = useAuthStore()
      expect(store.profile).toBeNull()
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('isLoggedIn 为 false，role 为 null', () => {
      const store = useAuthStore()
      expect(store.isLoggedIn).toBe(false)
      expect(store.role).toBeNull()
    })
  })

  // ── login() ───────────────────────────────────────────

  describe('login()', () => {
    it('成功：存储 token，填充 profile，跳转 /dashboard', async () => {
      vi.mocked(mockLogin).mockResolvedValue(fakeLoginResponse)
      vi.mocked(mockApiGet).mockResolvedValue(fakeProfile)

      const store = useAuthStore()
      await store.login('zhang@propos.com', 'password123')

      expect(localStorage.getItem('access_token')).toBe('access-abc')
      expect(localStorage.getItem('refresh_token')).toBe('refresh-xyz')
      expect(store.profile).toEqual(fakeProfile)
      expect(router.replace).toHaveBeenCalledWith('/dashboard')
    })

    it('成功：query.redirect 存在时跳转到指定路由', async () => {
      vi.mocked(mockLogin).mockResolvedValue(fakeLoginResponse)
      vi.mocked(mockApiGet).mockResolvedValue(fakeProfile)
      vi.mocked(router.currentRoute).value.query = { redirect: '/contracts' }

      const store = useAuthStore()
      await store.login('zhang@propos.com', 'pass')

      expect(router.replace).toHaveBeenCalledWith('/contracts')
    })

    it('成功：loading 从 false → true → false', async () => {
      const loadingHistory: boolean[] = []
      vi.mocked(mockLogin).mockImplementation(async () => {
        // loading 应该在此时为 true（进入 try 前）
        return fakeLoginResponse
      })
      vi.mocked(mockApiGet).mockResolvedValue(fakeProfile)

      const store = useAuthStore()

      // 监控 loading 变化
      const originalLogin = store.login.bind(store)
      const loginPromise = originalLogin('x@x.com', 'pass')
      // 调用后 loading 立即变为 true
      loadingHistory.push(store.loading)
      await loginPromise
      // 完成后 loading 变回 false
      loadingHistory.push(store.loading)

      expect(loadingHistory[0]).toBe(true)
      expect(loadingHistory[1]).toBe(false)
    })

    it('失败（ApiError）：error.value = e.message', async () => {
      vi.mocked(mockLogin).mockRejectedValue(
        new ApiError('INVALID_CREDENTIALS', '用户名或密码错误', 401),
      )

      const store = useAuthStore()
      await expect(store.login('bad@x.com', 'wrong')).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('用户名或密码错误')
    })

    it('失败（普通 Error）：error.value = 默认消息', async () => {
      vi.mocked(mockLogin).mockRejectedValue(new Error('Network Error'))

      const store = useAuthStore()
      await expect(store.login('x@x.com', 'pass')).rejects.toBeInstanceOf(Error)
      expect(store.error).toBe('登录失败，请重试')
    })

    it('403（账户受限）：调用 clearTokens，不调用 logout', async () => {
      vi.mocked(mockLogin).mockResolvedValue(fakeLoginResponse)
      vi.mocked(mockApiGet).mockRejectedValue(new ApiError('FORBIDDEN', '账号已被禁用', 403))

      const store = useAuthStore()
      await expect(store.login('x@x.com', 'pass')).rejects.toBeInstanceOf(ApiError)
      expect(clearTokens).toHaveBeenCalled()
      // logout（apiLogout）不应被调用
      expect(mockLogout).not.toHaveBeenCalled()
    })

    it('失败后 loading 恢复为 false', async () => {
      vi.mocked(mockLogin).mockRejectedValue(new ApiError('ERR', '错误', 500))

      const store = useAuthStore()
      await store.login('x@x.com', 'pass').catch(() => {})
      expect(store.loading).toBe(false)
    })
  })

  // ── fetchMe() ─────────────────────────────────────────

  describe('fetchMe()', () => {
    it('成功：profile.value 被填充', async () => {
      localStorage.setItem('access_token', 'valid-token')
      vi.mocked(mockApiGet).mockResolvedValue(fakeProfile)

      const store = useAuthStore()
      await store.fetchMe()

      expect(store.profile).toEqual(fakeProfile)
    })

    it('无 access_token 时直接返回，不请求 API', async () => {
      const store = useAuthStore()
      await store.fetchMe()

      expect(mockApiGet).not.toHaveBeenCalled()
    })

    it('非 403 错误：自动调用 logout（通过 router.replace 验证）', async () => {
      localStorage.setItem('access_token', 'token')
      vi.mocked(mockApiGet).mockRejectedValue(new ApiError('UNAUTHORIZED', '未授权', 401))

      const store = useAuthStore()
      await expect(store.fetchMe()).rejects.toBeInstanceOf(ApiError)

      // logout() 内部会调用 router.replace('/login')，以此间接验证 logout 被执行
      expect(router.replace).toHaveBeenCalledWith('/login')
    })

    it('403：不调用 logout，重新抛出错误', async () => {
      localStorage.setItem('access_token', 'token')
      vi.mocked(mockApiGet).mockRejectedValue(new ApiError('FORBIDDEN', '账号受限', 403))

      const store = useAuthStore()
      const logoutSpy = vi.spyOn(store, 'logout')
      await expect(store.fetchMe()).rejects.toMatchObject({ statusCode: 403 })

      expect(logoutSpy).not.toHaveBeenCalled()
    })
  })

  // ── logout() ──────────────────────────────────────────

  describe('logout()', () => {
    it('revokeSession=true：调用 apiLogout，清空 profile 和 token', async () => {
      localStorage.setItem('access_token', 'token')
      localStorage.setItem('refresh_token', 'refresh')
      vi.mocked(mockLogout).mockResolvedValue(undefined)

      const store = useAuthStore()
      store.profile = fakeProfile as typeof store.profile
      await store.logout(true)

      expect(mockLogout).toHaveBeenCalledWith('refresh')
      expect(store.profile).toBeNull()
      expect(localStorage.getItem('access_token')).toBeNull()
    })

    it('revokeSession=false：不调用 apiLogout', async () => {
      localStorage.setItem('refresh_token', 'refresh')

      const store = useAuthStore()
      await store.logout(false)

      expect(mockLogout).not.toHaveBeenCalled()
    })

    it('apiLogout 失败：error.value 被设置，profile 和 token 仍被清除', async () => {
      localStorage.setItem('access_token', 'token')
      localStorage.setItem('refresh_token', 'refresh')
      // ApiError.message = '退出失败'，store 用 e.message 设置 error
      vi.mocked(mockLogout).mockRejectedValue(new ApiError('ERR', '退出失败', 500))

      const store = useAuthStore()
      store.profile = fakeProfile as typeof store.profile
      await store.logout(true)

      expect(store.error).toBe('退出失败')
      expect(store.profile).toBeNull()
    })

    it('logout 后 loading 恢复为 false', async () => {
      vi.mocked(mockLogout).mockResolvedValue(undefined)
      const store = useAuthStore()
      await store.logout()
      expect(store.loading).toBe(false)
    })
  })

  // ── computed ──────────────────────────────────────────

  describe('computed', () => {
    it('isLoggedIn：profile 非空时为 true', () => {
      const store = useAuthStore()
      expect(store.isLoggedIn).toBe(false)
      store.profile = fakeProfile as typeof store.profile
      expect(store.isLoggedIn).toBe(true)
    })

    it('role：返回 profile.role，无 profile 时为 null', () => {
      const store = useAuthStore()
      expect(store.role).toBeNull()
      store.profile = fakeProfile as typeof store.profile
      expect(store.role).toBe('admin')
    })
  })
})
