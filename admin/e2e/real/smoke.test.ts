/**
 * Admin 真实后端冒烟测试
 *
 * 依赖真实后端运行（localhost:8080），不 Mock 任何 API。
 * 使用 auth.real.setup.ts 保存的真实 storageState。
 *
 * 覆盖场景：
 *  1. 资产页面真实数据加载（stat-card 可见，页面标题正确）
 *  2. 用户列表真实数据加载（页面标题可见，el-table 行可见）
 *  3. 真实 API 响应状态验证（捕获 /api/assets/overview 响应，确认状态码 200）
 */
import { test, expect } from '@playwright/test'

test.describe('资产管理页', () => {
  test('资产页面真实数据加载', async ({ page }) => {
    await page.goto('/assets')
    await page.waitForLoadState('networkidle')

    // 页面标题
    await expect(page.locator('h2').filter({ hasText: '资产管理' })).toBeVisible({
      timeout: 30_000,
    })
    // 三业态统计卡片（overview 接口正常返回时至少一张卡片出现）
    await expect(page.locator('.stat-card').first()).toBeVisible({ timeout: 30_000 })
  })

  test('API 响应状态验证 — /api/assets/overview 返回 200', async ({ page }) => {
    // 在导航前注册 response 监听
    const overviewResponsePromise = page.waitForResponse(
      resp => resp.url().includes('/api/assets/overview') && resp.status() === 200,
    )

    await page.goto('/assets')

    // 确认接口返回 200（后端数据链路正常）
    const overviewResp = await overviewResponsePromise
    expect(overviewResp.status()).toBe(200)

    // 确认响应 body 符合信封格式（含 data 字段）
    const body = await overviewResp.json()
    expect(body).toHaveProperty('data')
  })
})

test.describe('用户管理页', () => {
  test('用户列表真实数据加载', async ({ page }) => {
    await page.goto('/system/users')
    await page.waitForLoadState('networkidle')

    // 页面标题
    await expect(page.locator('h2').filter({ hasText: '员工账号管理' })).toBeVisible({
      timeout: 30_000,
    })
    // 至少有一行表格数据（系统中有员工数据时）
    await expect(page.locator('.el-table__row').first()).toBeVisible({ timeout: 30_000 })
  })
})
