import { describe, expect, it, vi } from 'vitest'

// Mock luch-request before importing client
vi.mock('luch-request', () => {
  const interceptors = {
    request: { use: vi.fn() },
    response: { use: vi.fn() },
  }
  class MockRequest {
    interceptors = interceptors
    constructor(_opts?: any) {}
    get = vi.fn()
    post = vi.fn()
    put = vi.fn()
    delete = vi.fn()
    request = vi.fn()
  }
  return { default: MockRequest }
})

// Mock the mock module
vi.mock('../mock/index', () => ({
  matchMock: vi.fn(() => Promise.resolve(null)),
}))

describe('api/client exports', () => {
  it('exports all expected public functions', async () => {
    const client = await import('../client')
    expect(client).toHaveProperty('setTokens')
    expect(client).toHaveProperty('clearTokens')
    expect(client).toHaveProperty('apiGet')
    expect(client).toHaveProperty('apiPost')
    expect(client).toHaveProperty('apiPut')
    expect(client).toHaveProperty('apiPatch')
    expect(client).toHaveProperty('apiDelete')
  })
})

describe('token management', () => {
  it('setTokens persists to storage', async () => {
    const { setTokens } = await import('../client')
    setTokens('access_123', 'refresh_456')
    expect(uni.setStorageSync).toHaveBeenCalledWith('access_token', 'access_123')
    expect(uni.setStorageSync).toHaveBeenCalledWith('refresh_token', 'refresh_456')
  })

  it('clearTokens removes from storage', async () => {
    const { clearTokens } = await import('../client')
    clearTokens()
    expect(uni.removeStorageSync).toHaveBeenCalledWith('access_token')
    expect(uni.removeStorageSync).toHaveBeenCalledWith('refresh_token')
  })
})
