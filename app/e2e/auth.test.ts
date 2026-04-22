/**
 * 认证全链路集成测试
 *
 * 所有 API 请求通过 page.route() 在网络层拦截，无需真实后端。
 * 前提：playwright webServer 以 VITE_USE_MOCK=false 启动（playwright.config.ts 已配置）。
 *
 * 覆盖场景：
 *  1. 登录成功流程（填表 → API mock 200 → 跳转首页 → token 写入 localStorage）
 *  2. 密码错误（API mock 401 → 留在登录页 → 显示错误提示）
 *  3. 登录态持久化（注入 token → splash 自动跳转首页）
 *  4. 退出登录（API mock 200 → logout body 携带 refresh_token → 跳转登录页）
 *  5. Token 自动刷新（access_token 过期 → 401 → refresh → 重试 me → 进入首页）
 *  6. 双 token 均失效（me 401 + refresh 401 → 跳回登录页）
 */

import { test, expect, type Page } from '@playwright/test'

// ──────────────────────────────────────────────────────────────────
// 测试固定数据
// ──────────────────────────────────────────────────────────────────
const MOCK_USER = {
  id: 'e2e-user-1',
  name: 'E2E测试员',
  email: 'e2e@propos.local',
  role: 'admin',
  permissions: [] as string[],
}

const MOCK_TOKENS = {
  access_token: 'e2e-mock-access-token',
  refresh_token: 'e2e-mock-refresh-token',
}

// ──────────────────────────────────────────────────────────────────
// 辅助：路由 mock 工厂
// ──────────────────────────────────────────────────────────────────
function mockLoginSuccess(page: Page) {
  return page.route('**/api/auth/login', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: { ...MOCK_TOKENS, user: MOCK_USER } }),
    }),
  )
}

function mockLoginFailure(page: Page) {
  return page.route('**/api/auth/login', route =>
    route.fulfill({
      status: 401,
      contentType: 'application/json',
      body: JSON.stringify({
        error: { code: 'AUTH_INVALID_CREDENTIALS', message: '邮箱或密码错误' },
      }),
    }),
  )
}

function mockMeSuccess(page: Page) {
  return page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_USER }),
    }),
  )
}

function mockLogoutSuccess(page: Page) {
  return page.route('**/api/auth/logout', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: null }),
    }),
  )
}

// ──────────────────────────────────────────────────────────────────
// 辅助：localStorage 工具
// ──────────────────────────────────────────────────────────────────
async function getStorageToken(page: Page, key: string): Promise<string> {
  return page.evaluate((k: string) => localStorage.getItem(k) ?? '', key)
}

/** 在页面脚本运行前注入 token（用 addInitScript 避免 splash 还来不及读到 token） */
async function injectTokensBeforeLoad(
  page: Page,
  accessToken = MOCK_TOKENS.access_token,
  refreshToken = MOCK_TOKENS.refresh_token,
) {
  await page.addInitScript(
    ([at, rt]) => {
      localStorage.setItem('access_token', at)
      localStorage.setItem('refresh_token', rt)
    },
    [accessToken, refreshToken],
  )
}

// ──────────────────────────────────────────────────────────────────
// 所有测试从无登录态开始
// ──────────────────────────────────────────────────────────────────
test.use({ storageState: { cookies: [], origins: [] } })

// ──────────────────────────────────────────────────────────────────
// 1. 登录成功
// ──────────────────────────────────────────────────────────────────
test('登录成功 → 跳转首页，localStorage 存有 token', async ({ page }) => {
  await mockLoginSuccess(page)
  await mockMeSuccess(page)

  await page.goto('/#/pages/auth/login')
  await page.waitForLoadState('networkidle')

  await page.getByTestId('login-email').locator('input').fill('e2e@propos.local')
  await page.getByTestId('login-password').locator('input').fill('test-password-123')
  await page.getByTestId('login-submit').click()

  // 应跳转首页
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // token 已写入 localStorage
  expect(await getStorageToken(page, 'access_token')).toBe(MOCK_TOKENS.access_token)
  expect(await getStorageToken(page, 'refresh_token')).toBe(MOCK_TOKENS.refresh_token)
})

// ──────────────────────────────────────────────────────────────────
// 2. 密码错误
// ──────────────────────────────────────────────────────────────────
test('密码错误 → 留在登录页，显示错误提示', async ({ page }) => {
  await mockLoginFailure(page)

  await page.goto('/#/pages/auth/login')
  await page.waitForLoadState('networkidle')

  await page.getByTestId('login-email').locator('input').fill('e2e@propos.local')
  await page.getByTestId('login-password').locator('input').fill('wrong-password-12345')
  await page.getByTestId('login-submit').click()

  // 仍在登录页
  await expect(page).toHaveURL(/#\/pages\/auth\/login/, { timeout: 8_000 })

  // 显示错误信息
  await expect(page.getByTestId('login-error')).toBeVisible({ timeout: 5_000 })
})

// ──────────────────────────────────────────────────────────────────
// 3. 登录态持久化
// ──────────────────────────────────────────────────────────────────
test('已有 token 时重载 splash → 自动跳转首页', async ({ page }) => {
  // addInitScript 在页面脚本执行前注入 token，splash 读到后直接验证
  await injectTokensBeforeLoad(page)
  await mockMeSuccess(page)

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')

  // splash 校验 token 有效后应跳转首页
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })
})

// ──────────────────────────────────────────────────────────────────
// 4. 退出登录
// ──────────────────────────────────────────────────────────────────
test('退出登录 → logout 请求携带 refresh_token，跳转登录页，token 清除', async ({ page }) => {
  await mockLoginSuccess(page)
  await mockMeSuccess(page)
  await mockLogoutSuccess(page)

  // 先登录
  await page.goto('/#/pages/auth/login')
  await page.waitForLoadState('networkidle')
  await page.getByTestId('login-email').locator('input').fill('e2e@propos.local')
  await page.getByTestId('login-password').locator('input').fill('test-password-123')
  await page.getByTestId('login-submit').click()
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // 监听 logout 网络请求（page.route 已 mock，但 waitForRequest 仍可捕获请求体）
  const logoutReq = page.waitForRequest(
    req => req.url().includes('/api/auth/logout') && req.method() === 'POST',
    { timeout: 10_000 },
  )

  // 触发退出：头像 → ActionSheet → "退出登录" → Modal "确定"
  await page.getByTestId('dashboard-avatar').click()
  await page.getByText('退出登录').first().click()
  // uni.showModal 在 H5 渲染为 <div> 而非 <button>，不具备 role="button"，用精确文本定位
  await page.getByText('确定', { exact: true }).click()

  // 验证 logout 请求体包含 refresh_token
  const logoutRequest = await logoutReq
  const body = JSON.parse(logoutRequest.postData() ?? '{}')
  expect(body.refresh_token).toBe(MOCK_TOKENS.refresh_token)

  // 跳转登录页
  await expect(page).toHaveURL(/#\/pages\/auth\/login/, { timeout: 10_000 })

  // token 已清除
  expect(await getStorageToken(page, 'access_token')).toBe('')
  expect(await getStorageToken(page, 'refresh_token')).toBe('')
})

// ──────────────────────────────────────────────────────────────────
// 5. Token 自动刷新
// ──────────────────────────────────────────────────────────────────
test('access_token 过期但 refresh_token 有效 → 静默刷新后进入首页', async ({ page }) => {
  let meCallCount = 0

  // /api/auth/me：第一次 401（token 过期），之后 200（refresh 后重试）
  await page.route('**/api/auth/me', (route) => {
    meCallCount++
    if (meCallCount === 1) {
      return route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({ error: { code: 'AUTH_TOKEN_EXPIRED', message: 'Token 已过期' } }),
      })
    }
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_USER }),
    })
  })

  // /api/auth/refresh：返回新 token
  await page.route('**/api/auth/refresh', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: {
          access_token: 'refreshed-access-token',
          refresh_token: MOCK_TOKENS.refresh_token,
        },
      }),
    }),
  )

  // 注入过期 access_token + 有效 refresh_token（在脚本执行前写入）
  await injectTokensBeforeLoad(page, 'EXPIRED_ACCESS_TOKEN', MOCK_TOKENS.refresh_token)

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')

  // 最终应进入首页（刷新成功）
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // 新 access_token 已更新
  const newAt = await getStorageToken(page, 'access_token')
  expect(newAt).toBe('refreshed-access-token')
})

// ──────────────────────────────────────────────────────────────────
// 6. 双 token 均失效
// ──────────────────────────────────────────────────────────────────
test('access_token 和 refresh_token 均无效 → 跳回登录页', async ({ page }) => {
  // me: 始终 401
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 401,
      contentType: 'application/json',
      body: JSON.stringify({ error: { code: 'AUTH_TOKEN_EXPIRED', message: 'Token 已过期' } }),
    }),
  )
  // refresh: 也 401
  await page.route('**/api/auth/refresh', route =>
    route.fulfill({
      status: 401,
      contentType: 'application/json',
      body: JSON.stringify({ error: { code: 'AUTH_REFRESH_EXPIRED', message: 'Refresh token 已过期' } }),
    }),
  )

  // 注入双无效 token
  await injectTokensBeforeLoad(page, 'INVALID_TOKEN', 'INVALID_REFRESH')

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')

  // 应强制跳转登录页
  await expect(page).toHaveURL(/#\/pages\/auth\/login/, { timeout: 20_000 })

  // token 已清空
  expect(await getStorageToken(page, 'access_token')).toBe('')
  expect(await getStorageToken(page, 'refresh_token')).toBe('')
})


