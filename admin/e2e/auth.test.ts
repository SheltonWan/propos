/**
 * Admin 认证全链路 E2E 测试
 *
 * 所有 API 通过 page.route() 在网络层拦截，无需真实后端。
 *
 * 覆盖场景：
 *  [登录表单]
 *   1. 正确凭据 → 跳转 /dashboard + token 写入 localStorage
 *   2. 错误凭据 → 留在 /login + el-alert 显示错误信息
 *   3. 空表单提交 → el-form-item--error 出现（真实浏览器 Element Plus 校验）
 *   4. 格式错误邮箱 blur → 邮箱字段标记为 error 状态
 *  [路由守卫]
 *   5. 未登录访问 /assets → 重定向 /login（含 redirect query 参数）
 *
 * 注意：场景 3、4 是 jsdom 单元测试的盲区（Element Plus Transition stub 导致
 * el-form-item__error 不可见，validate() 链路在 jsdom 中不完整）。
 * 真实浏览器中 Element Plus 完整渲染，表单校验行为与生产一致。
 */
import { test, expect, type Page } from '@playwright/test'

// ─── 测试固定数据 ─────────────────────────────────────────────────────────────

const MOCK_USER = {
  id: 'e2e-user-1',
  name: 'E2E测试员',
  email: 'e2e@propos.local',
  role: 'super_admin',
  permissions: [] as string[],
}

const MOCK_TOKENS = {
  access_token: 'e2e-mock-access-token',
  refresh_token: 'e2e-mock-refresh-token',
  expires_in: 3600,
}

// ─── Mock 工厂函数 ────────────────────────────────────────────────────────────

/** 模拟登录成功（后端返回 token + 用户信息） */
function mockLoginSuccess(page: Page) {
  return page.route('**/api/auth/login', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: { ...MOCK_TOKENS, user: MOCK_USER },
      }),
    }),
  )
}

/** 模拟登录失败（错误凭据，后端返回 401） */
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

/** 模拟 /api/auth/me 返回当前用户信息（登录后 fetchMe 调用） */
function mockMeSuccess(page: Page) {
  return page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_USER }),
    }),
  )
}

/** 填写登录表单（不点击提交） */
async function fillLoginForm(page: Page, email: string, password: string) {
  await page.fill('input[placeholder="请输入账号邮箱"]', email)
  await page.fill('input[placeholder="请输入密码"]', password)
}

// ─── 登录表单场景 ─────────────────────────────────────────────────────────────

test.describe('登录表单', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
  })

  test('正确凭据 → 跳转 /dashboard，token 写入 localStorage', async ({ page }) => {
    await mockLoginSuccess(page)
    await mockMeSuccess(page)

    await fillLoginForm(page, 'admin@propos.local', 'password123')
    await page.click('button[type="submit"]')

    // 等待路由跳转（authStore.login 写入 token 后调用 router.replace('/dashboard')）
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 15_000 })

    // 验证 token 已写入 localStorage
    const accessToken = await page.evaluate(() => localStorage.getItem('access_token'))
    expect(accessToken).toBe(MOCK_TOKENS.access_token)
  })

  test('错误凭据 → 留在 /login，el-alert 显示错误信息', async ({ page }) => {
    await mockLoginFailure(page)

    await fillLoginForm(page, 'admin@propos.local', 'wrong-password')
    await page.click('button[type="submit"]')

    // 未跳转，仍在登录页
    await expect(page).toHaveURL(/\/login/)

    // authStore.error 被赋值为后端返回的 message → el-alert 展示
    await expect(page.locator('.el-alert')).toBeVisible({ timeout: 10_000 })
    await expect(page.locator('.el-alert')).toContainText('邮箱或密码错误')
  })

  test('空表单提交 → el-form-item--error 出现（真实浏览器校验）', async ({ page }) => {
    // 不填任何内容，直接点击提交
    // handleLogin → formRef.validate() → 两个字段均必填校验失败
    await page.click('button[type="submit"]')
    // Element Plus validate() 为异步，等待 Vue 响应式更新应用错误样式
    await page.waitForTimeout(300)

    // 真实浏览器中 Element Plus v2 完整工作：form item 获得 is-error class
    // （注：Element Plus v2 使用 is-error，非 el-form-item--error）
    // jsdom 中此断言会失败（Transition stub 导致校验文字不可见，validate 链断裂）
    await expect(page.locator('.el-form-item.is-error').first()).toBeVisible({
      timeout: 5_000,
    })
  })

  test('格式错误邮箱 blur → 邮箱字段标记为 error 状态', async ({ page }) => {
    const emailInput = page.locator('input[placeholder="请输入账号邮箱"]')

    // 填入无效格式的邮箱（仅 required 通过，type: email 校验失败）
    await emailInput.fill('invalid-email')
    // blur 触发 trigger: 'blur' 的字段级校验
    await emailInput.blur()

    // 包裹邮箱 input 的 el-form-item 应获得 el-form-item--error class
    const emailFormItem = page
      .locator('.el-form-item')
      .filter({ has: page.locator('input[placeholder="请输入账号邮箱"]') })
    // Element Plus v2 使用 is-error class（非 el-form-item--error）
    await expect(emailFormItem).toHaveClass(/is-error/, { timeout: 5_000 })
  })
})

// ─── 路由守卫场景 ─────────────────────────────────────────────────────────────

test.describe('路由守卫', () => {
  test('未登录访问 /assets → 重定向 /login（含 redirect 参数）', async ({ page }) => {
    // 直接访问受保护路由（localStorage 中无 token）
    await page.goto('/assets')

    // authGuard 检测到无 access_token → 重定向到 /login?redirect=%2Fassets
    await expect(page).toHaveURL(/\/login/, { timeout: 10_000 })
    await expect(page).toHaveURL(/redirect=/)
  })
})
