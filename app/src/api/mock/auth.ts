import type { MockHandler } from './types'
import type { CurrentUser, LoginResponse } from '@/types/auth'
import {
  AUTH_CHANGE_PASSWORD,
  AUTH_LOGIN,
  AUTH_LOGOUT,
  AUTH_ME,
  AUTH_REFRESH,
} from '@/constants/api_paths'

const MOCK_USER: CurrentUser = {
  id: 'mock-user-001',
  name: '张三（演示）',
  email: 'demo@propos.com',
  role: 'operations_manager',
  department_id: 'dept-001',
  department_name: '运营管理部',
  permissions: [
    'org.read',
    'assets.read',
    'assets.write',
    'contracts.read',
    'contracts.write',
    'finance.read',
    'finance.write',
    'kpi.view',
    'kpi.manage',
    'workorders.read',
    'workorders.write',
    'sublease.read',
  ],
  bound_contract_id: null,
  is_active: true,
  last_login_at: new Date().toISOString(),
}

const MOCK_LOGIN_RESPONSE: LoginResponse = {
  access_token: `mock_access_token_${Date.now()}`,
  refresh_token: `mock_refresh_token_${Date.now()}`,
  expires_in: 86400,
  user: {
    id: MOCK_USER.id,
    name: MOCK_USER.name,
    email: MOCK_USER.email,
    role: MOCK_USER.role,
    department_id: MOCK_USER.department_id,
    must_change_password: false,
  },
}

export const authMocks: MockHandler[] = [
  {
    method: 'POST',
    url: AUTH_LOGIN,
    handler: (_url, body) => {
      const { password } = (body ?? {}) as { email?: string, password?: string }
      if (password === '123456' || password === 'Propos123') {
        return { delay: 800, data: MOCK_LOGIN_RESPONSE }
      }
      return {
        delay: 500,
        error: { code: 'AUTH_INVALID_CREDENTIALS', message: '用户名或密码错误', status: 401 },
      }
    },
  },
  {
    method: 'GET',
    url: AUTH_ME,
    handler: () => ({ delay: 300, data: MOCK_USER }),
  },
  {
    method: 'POST',
    url: AUTH_LOGOUT,
    handler: () => ({ delay: 200, data: null }),
  },
  {
    method: 'POST',
    url: AUTH_REFRESH,
    handler: () => ({
      delay: 300,
      data: {
        access_token: `mock_access_refreshed_${Date.now()}`,
        refresh_token: `mock_refresh_refreshed_${Date.now()}`,
        expires_in: 86400,
      },
    }),
  },
  {
    method: 'POST',
    url: AUTH_CHANGE_PASSWORD,
    handler: () => ({ delay: 500, data: null }),
  },
]
