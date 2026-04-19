import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'
import { useAuthStore } from '../auth'

// vi.hoisted 声明在 vi.mock 工厂中使用的变量
const { mockClearTokens } = vi.hoisted(() => ({
  mockClearTokens: vi.fn(),
}))
vi.mock('@/api/modules/auth', () => ({
  login: vi.fn(() =>
    Promise.resolve({
      access_token: 'test_access',
      refresh_token: 'test_refresh',
      expires_in: 86400,
      user: { id: '1', name: 'Test', email: 'test@test.com', role: 'admin', department_id: 'd1', must_change_password: false },
    }),
  ),
  fetchMe: vi.fn(() =>
    Promise.resolve({
      id: '1',
      name: 'Test User',
      email: 'test@test.com',
      role: 'admin',
      department_id: 'd1',
      department_name: 'Admin',
      permissions: ['org.read', 'assets.read'],
      bound_contract_id: null,
      is_active: true,
      last_login_at: new Date().toISOString(),
    }),
  ),
  logout: vi.fn(() => Promise.resolve()),
  setTokens: vi.fn(),
  clearTokens: mockClearTokens,
}))

describe('auth store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('starts with no user', () => {
    const store = useAuthStore()
    expect(store.isLoggedIn).toBe(false)
    expect(store.user).toBeNull()
  })

  it('login sets user and tokens', async () => {
    const store = useAuthStore()
    await store.login('test@test.com', 'password')
    expect(store.isLoggedIn).toBe(true)
    expect(store.user).toBeTruthy()
    expect(store.user!.name).toBe('Test User')
  })

  it('logout clears user and redirects via clearTokens', async () => {
    const store = useAuthStore()
    await store.login('test@test.com', 'password')
    await store.logout()
    expect(store.user).toBeNull()
    expect(store.isLoggedIn).toBe(false)
    expect(mockClearTokens).toHaveBeenCalled()
    expect(uni.reLaunch).toHaveBeenCalledWith({ url: '/pages/auth/login' })
  })

  it('fetchMe populates user', async () => {
    const store = useAuthStore()
    await store.fetchMe()
    expect(store.user).toBeTruthy()
    expect(store.user!.permissions).toContain('org.read')
  })

  it('hasPermission returns correct results', async () => {
    const store = useAuthStore()
    await store.fetchMe()
    expect(store.hasPermission('org.read')).toBe(true)
    expect(store.hasPermission('non.existent')).toBe(false)
  })

  it('handleAuthError clears state via clearTokens and redirects', async () => {
    const store = useAuthStore()
    await store.login('test@test.com', 'password')
    store.handleAuthError()
    expect(store.user).toBeNull()
    expect(mockClearTokens).toHaveBeenCalled()
    expect(uni.reLaunch).toHaveBeenCalledWith({ url: '/pages/auth/login' })
  })
})
