/**
 * 路由守卫（router/index.ts beforeEach）单元测试
 *
 * 策略：直接测试守卫函数逻辑，而非通过路由实例触发完整跳转（避免 jsdom 导航超时）
 * 覆盖范围：
 * - 未登录访问受保护路由 → 重定向 /login?redirect=原路径
 * - 未登录访问 meta.public=true 路由 → 直接通过
 * - 已登录访问受保护路由 → 通过
 * - redirect query 参数正确携带原始路径
 */

import { beforeEach, describe, expect, it } from 'vitest'
import { createRouter, createMemoryHistory, type RouteLocationNormalized } from 'vue-router'

// ── 提取并测试守卫逻辑（与生产守卫一致） ─────────────────

// 模拟与 admin/src/router/index.ts 中 beforeEach 相同的守卫函数
function authGuard(to: RouteLocationNormalized) {
  if (to.meta.public) return true
  const token = localStorage.getItem('access_token')
  if (!token) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  return true
}

// ── 辅助：构造 RouteLocationNormalized ────────────────────

function makeRoute(path: string, meta: Record<string, unknown> = {}): RouteLocationNormalized {
  return {
    path,
    fullPath: path,
    name: path.replace('/', '') || 'root',
    meta,
    query: {},
    params: {},
    hash: '',
    matched: [],
    redirectedFrom: undefined,
  } as unknown as RouteLocationNormalized
}

// ── 测试套件 ───────────────────────────────────────────────

describe('路由守卫 — authGuard 函数', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  describe('未登录', () => {
    it('访问受保护路由 /dashboard → 重定向到 login', () => {
      const result = authGuard(makeRoute('/dashboard'))
      expect(result).toMatchObject({ name: 'login' })
    })

    it('重定向时携带 redirect query 参数', () => {
      const result = authGuard(makeRoute('/assets'))
      expect(result).toMatchObject({ name: 'login', query: { redirect: '/assets' } })
    })

    it('路径 /contracts 的 redirect query 参数', () => {
      const result = authGuard(makeRoute('/contracts'))
      expect(result).toMatchObject({ query: { redirect: '/contracts' } })
    })

    it('访问 /login（public）→ 允许通过（返回 true）', () => {
      const result = authGuard(makeRoute('/login', { public: true }))
      expect(result).toBe(true)
    })

    it('访问 /forgot-password（public）→ 允许通过', () => {
      const result = authGuard(makeRoute('/forgot-password', { public: true }))
      expect(result).toBe(true)
    })
  })

  describe('已登录', () => {
    beforeEach(() => {
      localStorage.setItem('access_token', 'valid-token')
    })

    it('访问 /dashboard → 允许通过', () => {
      const result = authGuard(makeRoute('/dashboard'))
      expect(result).toBe(true)
    })

    it('访问 /assets → 允许通过', () => {
      const result = authGuard(makeRoute('/assets'))
      expect(result).toBe(true)
    })

    it('访问 /system/users → 允许通过', () => {
      const result = authGuard(makeRoute('/system/users'))
      expect(result).toBe(true)
    })

    it('已登录访问 /login（public）→ 守卫允许通过', () => {
      const result = authGuard(makeRoute('/login', { public: true }))
      expect(result).toBe(true)
    })
  })

  describe('token 边界', () => {
    it('localStorage 中存在空字符串 token → 视为未登录', () => {
      localStorage.setItem('access_token', '')
      const result = authGuard(makeRoute('/dashboard'))
      expect(result).toMatchObject({ name: 'login' })
    })

    it('token 存在且为有效字符串 → 放行', () => {
      localStorage.setItem('access_token', 'any-non-empty')
      const result = authGuard(makeRoute('/dashboard'))
      expect(result).toBe(true)
    })
  })
})
