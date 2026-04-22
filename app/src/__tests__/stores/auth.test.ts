/**
 * 认证 Store 全链路单元测试
 *
 * 覆盖场景：
 *  - login：成功流、密码错误、fetchMe 失败回滚
 *  - logout：正常注销、API 失败时仍清理本地状态
 *  - fetchMe：成功更新 user、失败置 null
 *  - forgotPassword / resetPassword：成功与错误透传
 *  - hasPermission：权限判定
 *  - handleAuthError：强制清理并跳转
 */

import { setActivePinia, createPinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/types/api'
import type { CurrentUser, LoginResponse } from '@/types/auth'

// ─── 模拟 API 模块 ─────────────────────────────────────────────────────────
vi.mock('@/api/modules/auth', () => ({
  login: vi.fn(),
  fetchMe: vi.fn(),
  logout: vi.fn(),
  forgotPassword: vi.fn(),
  resetPassword: vi.fn(),
  setTokens: vi.fn(),
  clearTokens: vi.fn(),
}))

import * as authApi from '@/api/modules/auth'
import { useAuthStore } from '@/stores/auth'

// ─── 测试固件 ──────────────────────────────────────────────────────────────
const MOCK_LOGIN_RESPONSE: LoginResponse = {
  access_token: 'access_abc',
  refresh_token: 'refresh_xyz',
  expires_in: 86400,
  user: {
    id: 'user-001',
    name: '张三',
    email: 'zhangsan@test.com',
    role: 'operations_manager',
    department_id: 'dept-001',
    must_change_password: false,
  },
}

const MOCK_CURRENT_USER: CurrentUser = {
  id: 'user-001',
  name: '张三',
  email: 'zhangsan@test.com',
  role: 'operations_manager',
  department_id: 'dept-001',
  department_name: '运营部',
  permissions: ['assets.read', 'contracts.read', 'finance.read'],
  bound_contract_id: null,
  is_active: true,
  last_login_at: '2026-04-22T08:00:00Z',
}

// ─── 测试套件 ──────────────────────────────────────────────────────────────
describe('useAuthStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  // ─── login ──────────────────────────────────────────────────────────────
  describe('login()', () => {
    it('成功登录：存 token、设置 user、loading 归位', async () => {
      vi.mocked(authApi.login).mockResolvedValue(MOCK_LOGIN_RESPONSE)
      vi.mocked(authApi.fetchMe).mockResolvedValue(MOCK_CURRENT_USER)

      const store = useAuthStore()
      await store.login('zhangsan@test.com', 'Propos123')

      // token 写入
      expect(authApi.setTokens).toHaveBeenCalledWith('access_abc', 'refresh_xyz')
      // user 填充
      expect(store.user).toEqual(MOCK_CURRENT_USER)
      expect(store.isLoggedIn).toBe(true)
      expect(store.role).toBe('operations_manager')
      // 状态归位
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('密码错误：error 写入错误信息、user 为 null、loading 归位', async () => {
      vi.mocked(authApi.login).mockRejectedValue(
        new ApiError('AUTH_INVALID_CREDENTIALS', '用户名或密码错误', 401),
      )

      const store = useAuthStore()
      await expect(store.login('zhangsan@test.com', 'wrong')).rejects.toThrow(ApiError)

      expect(store.user).toBeNull()
      expect(store.error).toBe('用户名或密码错误')
      expect(store.loading).toBe(false)
    })

    it('非 ApiError 错误：error 显示通用文案', async () => {
      vi.mocked(authApi.login).mockRejectedValue(new Error('网络超时'))

      const store = useAuthStore()
      await expect(store.login('a@b.com', 'pwd')).rejects.toThrow()

      expect(store.error).toBe('登录失败，请重试')
    })

    it('login 成功但 fetchMe 失败：清空 token、error 写入、user 为 null', async () => {
      vi.mocked(authApi.login).mockResolvedValue(MOCK_LOGIN_RESPONSE)
      vi.mocked(authApi.fetchMe).mockRejectedValue(
        new ApiError('FORBIDDEN', '权限不足', 403),
      )

      const store = useAuthStore()
      await expect(store.login('a@b.com', 'pwd')).rejects.toThrow(ApiError)

      // 回滚：token 必须清除
      expect(authApi.clearTokens).toHaveBeenCalled()
      expect(store.user).toBeNull()
      expect(store.loading).toBe(false)
    })

    it('login 执行期间 loading 为 true', async () => {
      let resolveLogin!: (v: LoginResponse) => void
      vi.mocked(authApi.login).mockReturnValue(
        new Promise<LoginResponse>((res) => { resolveLogin = res }),
      )
      vi.mocked(authApi.fetchMe).mockResolvedValue(MOCK_CURRENT_USER)

      const store = useAuthStore()
      const loginPromise = store.login('a@b.com', 'pwd')
      expect(store.loading).toBe(true)

      resolveLogin(MOCK_LOGIN_RESPONSE)
      await loginPromise
      expect(store.loading).toBe(false)
    })
  })

  // ─── logout ─────────────────────────────────────────────────────────────
  describe('logout()', () => {
    it('正常注销：调用 API、清空 user、跳转登录页', async () => {
      vi.mocked(authApi.logout).mockResolvedValue(undefined)

      const store = useAuthStore()
      // 预设已登录状态
      store.$patch({ user: MOCK_CURRENT_USER })

      await store.logout()

      expect(authApi.logout).toHaveBeenCalledTimes(1)
      expect(store.user).toBeNull()
      expect(authApi.clearTokens).toHaveBeenCalled()
      expect(uni.reLaunch).toHaveBeenCalledWith({ url: '/pages/auth/login' })
    })

    it('API 失败时仍清空本地状态并跳转（静默处理）', async () => {
      vi.mocked(authApi.logout).mockRejectedValue(new ApiError('NETWORK_ERROR', '网络异常', 0))

      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })

      // 不应抛出
      await expect(store.logout()).resolves.toBeUndefined()

      expect(store.user).toBeNull()
      expect(authApi.clearTokens).toHaveBeenCalled()
      expect(uni.reLaunch).toHaveBeenCalledWith({ url: '/pages/auth/login' })
    })
  })

  // ─── fetchMe ──────────────────────────────────────────────────────────
  describe('fetchMe()', () => {
    it('成功：更新 user、loading 归位', async () => {
      vi.mocked(authApi.fetchMe).mockResolvedValue(MOCK_CURRENT_USER)

      const store = useAuthStore()
      await store.fetchMe()

      expect(store.user).toEqual(MOCK_CURRENT_USER)
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('失败：user 置 null、error 写入、loading 归位', async () => {
      vi.mocked(authApi.fetchMe).mockRejectedValue(
        new ApiError('UNAUTHORIZED', '请先登录', 401),
      )

      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })
      await store.fetchMe()

      expect(store.user).toBeNull()
      expect(store.error).toBe('请先登录')
      expect(store.loading).toBe(false)
    })
  })

  // ─── forgotPassword ───────────────────────────────────────────────────
  describe('forgotPassword()', () => {
    it('成功：无抛出、loading 归位', async () => {
      vi.mocked(authApi.forgotPassword).mockResolvedValue({ message: '已发送' })

      const store = useAuthStore()
      await expect(store.forgotPassword('a@b.com')).resolves.toBeUndefined()

      // 邮箱要转小写 + trim
      expect(authApi.forgotPassword).toHaveBeenCalledWith('a@b.com')
      expect(store.loading).toBe(false)
    })

    it('调用时对邮箱执行 trim + toLowerCase', async () => {
      vi.mocked(authApi.forgotPassword).mockResolvedValue({ message: '已发送' })

      const store = useAuthStore()
      await store.forgotPassword('  TEST@Example.COM  ')

      expect(authApi.forgotPassword).toHaveBeenCalledWith('test@example.com')
    })

    it('失败：error 写入、向上透传异常', async () => {
      vi.mocked(authApi.forgotPassword).mockRejectedValue(
        new ApiError('RATE_LIMITED', '请求频率过高', 429),
      )

      const store = useAuthStore()
      await expect(store.forgotPassword('a@b.com')).rejects.toThrow(ApiError)

      expect(store.error).toBe('请求频率过高')
      expect(store.loading).toBe(false)
    })
  })

  // ─── resetPassword ────────────────────────────────────────────────────
  describe('resetPassword()', () => {
    it('成功：无抛出、loading 归位', async () => {
      vi.mocked(authApi.resetPassword).mockResolvedValue({ message: '密码已重置' })

      const store = useAuthStore()
      await expect(store.resetPassword('a@b.com', '123456', 'NewPass1!')).resolves.toBeUndefined()

      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('失败：error 写入、向上透传异常', async () => {
      vi.mocked(authApi.resetPassword).mockRejectedValue(
        new ApiError('OTP_EXPIRED', '验证码已过期', 400),
      )

      const store = useAuthStore()
      await expect(store.resetPassword('a@b.com', '000000', 'Pass1!')).rejects.toThrow(ApiError)

      expect(store.error).toBe('验证码已过期')
    })
  })

  // ─── hasPermission ────────────────────────────────────────────────────
  describe('hasPermission()', () => {
    it('拥有权限时返回 true', () => {
      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })

      expect(store.hasPermission('assets.read')).toBe(true)
    })

    it('无权限时返回 false', () => {
      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })

      expect(store.hasPermission('users.manage')).toBe(false)
    })

    it('未登录时（user=null）返回 false', () => {
      const store = useAuthStore()
      expect(store.hasPermission('assets.read')).toBe(false)
    })
  })

  // ─── handleAuthError ──────────────────────────────────────────────────
  describe('handleAuthError()', () => {
    it('清空 user、清空 token、跳转登录页', () => {
      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })

      store.handleAuthError()

      expect(store.user).toBeNull()
      expect(authApi.clearTokens).toHaveBeenCalled()
      expect(uni.reLaunch).toHaveBeenCalledWith({ url: '/pages/auth/login' })
    })
  })

  // ─── computed getters ─────────────────────────────────────────────────
  describe('computed getters', () => {
    it('未登录：isLoggedIn=false, role=null, permissions=[]', () => {
      const store = useAuthStore()
      expect(store.isLoggedIn).toBe(false)
      expect(store.role).toBeNull()
      expect(store.permissions).toEqual([])
    })

    it('已登录：isLoggedIn=true, role 和 permissions 正确', () => {
      const store = useAuthStore()
      store.$patch({ user: MOCK_CURRENT_USER })

      expect(store.isLoggedIn).toBe(true)
      expect(store.role).toBe('operations_manager')
      expect(store.permissions).toContain('assets.read')
    })
  })
})
