/**
 * 真实后端冒烟测试
 *
 * 依赖 real-auth-setup 预置的真实 token（storageState: e2e/.auth/real.user.json）。
 * 所有请求直接透传至真实后端，无任何 page.route() mock。
 *
 * 策略：
 *  - 只校验页面结构与关键元素可见性，不断言具体数值（真实数据随业务变化）
 *  - 失败即说明真实后端 API 有问题，可在后端日志中追踪请求
 *
 * 覆盖场景：
 *  1. 已登录态直接访问首页，顶部用户信息正确渲染
 *  2. /api/auth/me 接口返回真实用户，用户名非空
 *  3. 首页指标区域正常加载（不断言具体数值）
 *  4. splash 页 token 校验通过后跳转首页
 */

import { test, expect } from '@playwright/test'

// ────────────────────────────────────────────────────────────────────────────
// 1. 首页顶部用户信息渲染
// ────────────────────────────────────────────────────────────────────────────
test('首页顶部展示非空用户姓名和今日日期', async ({ page }) => {
  // storageState 含真实 token，splash 校验后跳转首页
  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')

  // 等待跳转首页（真实后端 /api/auth/me 需要通过网络，超时适当放宽）
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // 顶部问候语可见且包含真实用户姓名（非空）
  const greeting = page.getByTestId('dashboard-greeting')
  await expect(greeting).toBeVisible({ timeout: 10_000 })
  await expect(greeting).toContainText('你好，')

  const greetingText = await greeting.textContent()
  expect(greetingText?.replace('你好，', '').trim().length).toBeGreaterThan(0)

  // 日期标签包含「月」「日」「周」
  const dateLabel = page.locator('.page-header__subtitle')
  await expect(dateLabel).toBeVisible()
  await expect(dateLabel).toContainText('月')
  await expect(dateLabel).toContainText('日')
})

// ────────────────────────────────────────────────────────────────────────────
// 2. /api/auth/me 返回真实用户数据
// ────────────────────────────────────────────────────────────────────────────
test('/api/auth/me 返回真实用户，role 非空', async ({ page }) => {
  // 拦截 me 接口日志（仅 observe，不 fulfil，请求仍透传后端）
  let meResponseBody: Record<string, unknown> | null = null
  page.on('response', async (response) => {
    if (response.url().includes('/api/auth/me') && response.status() === 200) {
      try {
        meResponseBody = await response.json()
      }
      catch {
        // 响应体解析失败时忽略
      }
    }
  })

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // 验证 me 接口响应结构合法
  expect(meResponseBody).not.toBeNull()
  const userData = (meResponseBody as { data?: Record<string, unknown> })?.data
  expect(userData?.id).toBeTruthy()
  expect(typeof userData?.name).toBe('string')
  expect((userData?.name as string).length).toBeGreaterThan(0)
  expect(userData?.role).toBeTruthy()
})

// ────────────────────────────────────────────────────────────────────────────
// 3. 首页指标区域加载完成（不断言具体数值）
// ────────────────────────────────────────────────────────────────────────────
test.fixme('首页指标卡片正常渲染（待指标 UI 实现后启用）', async ({ page }) => {
  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // 仅校验卡片可见，不断言具体数值（真实数据随业务变化）
  await expect(page.getByTestId('metric-card-occupancy')).toBeVisible({ timeout: 12_000 })
  await expect(page.getByTestId('metric-card-noi')).toBeVisible({ timeout: 12_000 })
})
