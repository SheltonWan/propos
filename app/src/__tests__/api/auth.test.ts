/**
 * 认证 API 模块单元测试（api/modules/auth.ts）
 *
 * 覆盖场景：
 *  - login：正确传参、成功返回、错误透传
 *  - fetchMe：正确调用 GET、成功返回
 *  - logout：携带 refresh_token 发 POST、成功后清空 token、API 失败后也清空 token
 *  - changePassword：正确传参
 *  - forgotPassword / resetPassword：正确传参
 */

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/types/api'
import type { CurrentUser, LoginResponse } from '@/types/auth'
import {
  AUTH_LOGIN,
  AUTH_ME,
  AUTH_LOGOUT,
  AUTH_CHANGE_PASSWORD,
  AUTH_FORGOT_PASSWORD,
  AUTH_RESET_PASSWORD,
} from '@/constants/api_paths'

// ─── 模拟 client 层 ───────────────────────────────────────────────────────
vi.mock('@/api/client', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  getRefreshToken: vi.fn(),
  setTokens: vi.fn(),
  clearTokens: vi.fn(),
}))

import * as client from '@/api/client'
import {
  login,
  fetchMe,
  logout,
  changePassword,
  forgotPassword,
  resetPassword,
} from '@/api/modules/auth'

// ─── 测试固件 ─────────────────────────────────────────────────────────────
const MOCK_LOGIN_RESPONSE: LoginResponse = {
  access_token: 'access_token',
  refresh_token: 'refresh_token',
  expires_in: 86400,
  user: {
    id: 'user-001',
    name: '张三',
    email: 'zhangsan@test.com',
    role: 'operations_manager',
    department_id: null,
    must_change_password: false,
  },
}

const MOCK_CURRENT_USER: CurrentUser = {
  id: 'user-001',
  name: '张三',
  email: 'zhangsan@test.com',
  role: 'operations_manager',
  department_id: null,
  department_name: null,
  permissions: ['assets.read'],
  bound_contract_id: null,
  is_active: true,
  last_login_at: null,
}

// ─── 测试套件 ─────────────────────────────────────────────────────────────
describe('api/modules/auth', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  // ─── login ─────────────────────────────────────────────────────────────
  describe('login()', () => {
    it('以 POST AUTH_LOGIN 发送邮箱和密码', async () => {
      vi.mocked(client.apiPost).mockResolvedValue(MOCK_LOGIN_RESPONSE)

      const result = await login('zhangsan@test.com', 'Propos123')

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_LOGIN, {
        email: 'zhangsan@test.com',
        password: 'Propos123',
      })
      expect(result).toEqual(MOCK_LOGIN_RESPONSE)
    })

    it('API 抛出 ApiError 时向上透传', async () => {
      vi.mocked(client.apiPost).mockRejectedValue(
        new ApiError('AUTH_INVALID_CREDENTIALS', '用户名或密码错误', 401),
      )

      await expect(login('a@b.com', 'wrong')).rejects.toMatchObject({
        code: 'AUTH_INVALID_CREDENTIALS',
        statusCode: 401,
      })
    })
  })

  // ─── fetchMe ───────────────────────────────────────────────────────────
  describe('fetchMe()', () => {
    it('以 GET AUTH_ME 获取当前用户', async () => {
      vi.mocked(client.apiGet).mockResolvedValue(MOCK_CURRENT_USER)

      const result = await fetchMe()

      expect(client.apiGet).toHaveBeenCalledWith(AUTH_ME)
      expect(result).toEqual(MOCK_CURRENT_USER)
    })
  })

  // ─── logout ────────────────────────────────────────────────────────────
  describe('logout()', () => {
    it('以 POST AUTH_LOGOUT 携带 refresh_token', async () => {
      vi.mocked(client.getRefreshToken).mockReturnValue('refresh_xyz')
      vi.mocked(client.apiPost).mockResolvedValue(undefined)

      await logout()

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_LOGOUT, {
        refresh_token: 'refresh_xyz',
      })
    })

    it('API 成功后调用 clearTokens', async () => {
      vi.mocked(client.getRefreshToken).mockReturnValue('refresh_xyz')
      vi.mocked(client.apiPost).mockResolvedValue(undefined)

      await logout()

      expect(client.clearTokens).toHaveBeenCalledTimes(1)
    })

    it('API 失败后仍调用 clearTokens（finally 保证）', async () => {
      vi.mocked(client.getRefreshToken).mockReturnValue('refresh_xyz')
      vi.mocked(client.apiPost).mockRejectedValue(
        new ApiError('UNAUTHORIZED', '未授权', 401),
      )

      await expect(logout()).rejects.toThrow(ApiError)

      // finally 必须执行
      expect(client.clearTokens).toHaveBeenCalledTimes(1)
    })

    it('refresh_token 为 null 时仍正常发送请求', async () => {
      vi.mocked(client.getRefreshToken).mockReturnValue(null)
      vi.mocked(client.apiPost).mockResolvedValue(undefined)

      await logout()

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_LOGOUT, {
        refresh_token: null,
      })
    })
  })

  // ─── changePassword ────────────────────────────────────────────────────
  describe('changePassword()', () => {
    it('以 POST AUTH_CHANGE_PASSWORD 携带旧密码和新密码', async () => {
      vi.mocked(client.apiPost).mockResolvedValue(undefined)

      await changePassword('OldPass1!', 'NewPass2!')

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_CHANGE_PASSWORD, {
        old_password: 'OldPass1!',
        new_password: 'NewPass2!',
      })
    })
  })

  // ─── forgotPassword ────────────────────────────────────────────────────
  describe('forgotPassword()', () => {
    it('以 POST AUTH_FORGOT_PASSWORD 携带邮箱', async () => {
      vi.mocked(client.apiPost).mockResolvedValue({ message: '已发送' })

      const result = await forgotPassword('a@b.com')

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_FORGOT_PASSWORD, { email: 'a@b.com' })
      expect(result).toEqual({ message: '已发送' })
    })
  })

  // ─── resetPassword ─────────────────────────────────────────────────────
  describe('resetPassword()', () => {
    it('以 POST AUTH_RESET_PASSWORD 携带正确字段名', async () => {
      vi.mocked(client.apiPost).mockResolvedValue({ message: '密码已重置' })

      await resetPassword('a@b.com', '123456', 'NewPass1!')

      expect(client.apiPost).toHaveBeenCalledWith(AUTH_RESET_PASSWORD, {
        email: 'a@b.com',
        otp: '123456',
        new_password: 'NewPass1!',
      })
    })
  })
})
