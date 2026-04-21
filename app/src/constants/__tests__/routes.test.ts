import { describe, expect, it } from 'vitest'
import { isPublicPage, PUBLIC_PAGES } from '../routes'

describe('routes constants', () => {
  it('pUBLIC_PAGES includes login and change-password', () => {
    expect(PUBLIC_PAGES).toContain('/pages/auth/login')
    expect(PUBLIC_PAGES).toContain('/pages/auth/change-password')
  })

  it('isPublicPage returns true for public pages', () => {
    expect(isPublicPage('/pages/auth/login')).toBe(true)
    expect(isPublicPage('/pages/auth/forgot-password')).toBe(true)
    expect(isPublicPage('/pages/auth/change-password')).toBe(true)
  })

  it('isPublicPage returns false for protected pages', () => {
    expect(isPublicPage('/pages/dashboard/index')).toBe(false)
    expect(isPublicPage('/pages/assets/index')).toBe(false)
    expect(isPublicPage('/pages/workorders/index')).toBe(false)
  })

  it('isPublicPage strips query params', () => {
    expect(isPublicPage('/pages/auth/login?redirect=dashboard')).toBe(true)
    expect(isPublicPage('/pages/dashboard/index?tab=1')).toBe(false)
  })
})
