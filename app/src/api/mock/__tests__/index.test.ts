import { describe, expect, it } from 'vitest'
import { matchMock } from '@/api/mock/index'
import { ApiError } from '@/types/api'

describe('matchMock', () => {
  it('returns data for a matching handler', async () => {
    const result = await matchMock('POST', '/api/auth/login', {
      email: 'demo@propos.com',
      password: 'Propos123',
    })
    expect(result).toBeTruthy()
    expect(result).toHaveProperty('access_token')
    expect(result).toHaveProperty('refresh_token')
  })

  it('returns null for unregistered endpoint', async () => {
    const result = await matchMock('GET', '/api/non-existent')
    expect(result).toBeNull()
  })

  it('throws ApiError on handler error response', async () => {
    await expect(
      matchMock('POST', '/api/auth/login', {
        email: 'demo@propos.com',
        password: 'wrong-password',
      }),
    ).rejects.toThrow(ApiError)
  })
})
