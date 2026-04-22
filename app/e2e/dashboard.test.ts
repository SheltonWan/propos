/**
 * 首页（Dashboard）集成测试
 *
 * 依赖 auth-setup 预置的登录态（storageState）。
 * 所有 API 接口（含 /api/auth/me）通过 page.route() 拦截，无需真实后端。
 * 数据层采用稳定 mock 数据，保证测试幂等，不受后端实际数值波动影响。
 *
 * 覆盖场景：
 *  1. 首页加载：顶部展示用户姓名和当日日期
 *  2. 指标卡片：综合出租率 / 当月 NOI 正确渲染（待实现后启用）
 *  3. Dashboard API 失败时展示错误状态而非崩溃
 *  4. 网络中断时顶部 Header 仍可见
 */

import { test, expect, type Page } from '@playwright/test'

/** 测试固定用户（与 auth.setup.ts 保持一致） */
const MOCK_USER = {
  id: 'e2e-user-1',
  name: 'E2E测试员',
  email: 'e2e@propos.local',
  role: 'admin',
  permissions: [] as string[],
}

/** 拦截 /api/auth/me 返回固定用户 */
async function mockMe(page: Page) {
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_USER }),
    }),
  )
}

// ─── 稳定 mock 数据（仅用于首页指标接口） ───────────────────────────────────
const MOCK_DASHBOARD = {
  occupancy_rate: 0.875,
  noi_month: 1200000,
  wale_income_weighted: 2.35,
  wale_area_weighted: 2.18,
  collection_rate: 0.96,
}

// ─── 辅助：为指标接口注册 route mock ──────────────────────────────────────
async function mockDashboardApi(page: Page) {
  await page.route('**/api/dashboard/summary**', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_DASHBOARD }),
    })
  })
}

// ────────────────────────────────────────────────────────────────────────────
// 1. 顶部用户信息正确渲染
// ────────────────────────────────────────────────────────────────────────────
test('首页顶部展示用户姓名和今日日期', async ({ page }) => {
  // storageState 含 mock token；me 接口也 mock，保证测试无需真实后端
  await mockMe(page)
  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // 顶部问候语包含用户名（具体姓名取决于测试账号，验证非空即可）
  const greeting = page.getByTestId('dashboard-greeting')
  await expect(greeting).toBeVisible()
  await expect(greeting).toContainText('你好，')
  // 姓名不能是占位符空字符串
  const greetingText = await greeting.textContent()
  expect(greetingText?.replace('你好，', '').trim().length).toBeGreaterThan(0)

  // 日期行包含「月」「日」「周」关键字（PageHeader 的 subtitle slot，选择器用 CSS class）
  const dateLabel = page.locator('.page-header__subtitle')
  await expect(dateLabel).toBeVisible()
  await expect(dateLabel).toContainText('月')
  await expect(dateLabel).toContainText('日')
  await expect(dateLabel).toContainText('周')
})

// ────────────────────────────────────────────────────────────────────────────
// 2. 指标卡片数据渲染（待 Dashboard 指标模块实现后启用）
// ────────────────────────────────────────────────────────────────────────────
test.fixme('首页指标卡片正确展示出租率和 NOI（mock 数据）', async ({ page }) => {
  await mockDashboardApi(page)

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // 出租率卡片
  const occupancyCard = page.getByTestId('metric-card-occupancy')
  await expect(occupancyCard).toBeVisible({ timeout: 10_000 })
  await expect(occupancyCard).toContainText('87.5%')

  // NOI 卡片（120万）
  const noiCard = page.getByTestId('metric-card-noi')
  await expect(noiCard).toBeVisible({ timeout: 10_000 })
  // 金额显示格式包含 "120" 或 "1.2M" 等（由组件决定，此处校验关键数字）
  await expect(noiCard).toContainText(/120|1\.2/)
})

// ────────────────────────────────────────────────────────────────────────────
// 3. API 失败降级
// ────────────────────────────────────────────────────────────────────────────
test('Dashboard API 返回 500 时，页面展示错误状态而非空白崩溃', async ({ page }) => {
  await mockMe(page)
  // 令 dashboard summary 返回服务端错误
  await page.route('**/api/dashboard/summary**', async (route) => {
    await route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({
        error: { code: 'INTERNAL_ERROR', message: '服务器内部错误' },
      }),
    })
  })

  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // 页面不能崩溃（无 JS 报错导致白屏）：至少渲染了顶部 header
  await expect(page.getByTestId('dashboard-greeting')).toBeVisible({ timeout: 10_000 })

  // 指标区域展示 error 态（而非加载态或正常数据）
  // error 态的具体实现由 dashboard 组件决定，此处仅验证不展示模拟数据
  const occupancyCard = page.getByTestId('metric-card-occupancy')
  // 要么不可见（区域整体隐藏），要么显示错误占位
  const isVisible = await occupancyCard.isVisible()
  if (isVisible) {
    const text = await occupancyCard.textContent()
    // 不能展示正常数据
    expect(text).not.toContain('87.5%')
  }
})

// ────────────────────────────────────────────────────────────────────────────
// 4. 断网场景（network offline）
// ────────────────────────────────────────────────────────────────────────────
test('网络中断时页面不崩溃，顶部 Header 仍可见', async ({ page, context }) => {
  // 先正常加载首页（me 接口 mock 后用 storageState token 鉴权）
  await mockMe(page)
  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // 断网（仅断 API，保留 localhost 的 H5 资源访问）
  await context.setOffline(true)

  // 触发一次数据刷新（模拟下拉刷新 or 导航回首页）
  // 注意：WebKit 在离线状态下调用 page.goto 会触发内部错误，改用客户端 hash 导航
  await page.evaluate(() => { location.hash = '/pages/dashboard/index' })
  // 等待 Vue 渲染完成（hash 路由切换是同步的，短暂等待 DOM 更新即可）
  await page.waitForTimeout(500)

  // 顶部 Header 必须仍然可见（不能白屏）
  await expect(page.getByTestId('dashboard-greeting')).toBeVisible({ timeout: 8_000 })

  // 恢复网络
  await context.setOffline(false)
})
