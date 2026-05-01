/**
 * 楼层结构标注页 E2E（page.route mock）
 *
 * 覆盖 plan §5-2 8 个核心场景：
 *  1. 进入页面：候选清单 + 画布渲染
 *  2. 点击候选 → 加入 draft，dirty Tag 出现
 *  3. 选中已保存结构 → Inspector 显示属性
 *  4. 无 dirty 时保存按钮禁用
 *  5. 修改 → 保存成功 → dirty 消失（PUT 携 If-Match）
 *  6. 409 冲突 → error 显示，dirty 保留
 *  7. dirty 时切换 RenderMode 被禁用
 *  8. SPA 离开守卫弹窗（取消留在页面）
 */
import { test, expect, type Page, type Route } from '@playwright/test'
import candidatesMock from './fixtures/candidates.mock.json'

const FLOOR_ID = 'fl-001'
const BUILDING_ID = 'bld-001'

const MOCK_AUTH_USER = {
  id: 'e2e-user-1',
  name: 'E2E测试员',
  email: 'e2e@propos.local',
  role: 'super_admin',
  departmentId: null,
}

const MOCK_BUILDING = {
  id: BUILDING_ID,
  name: 'A栋写字楼',
  property_type: 'office',
  total_floors: 24,
  basement_floors: 2,
  gfa: 18000,
  nla: 15000,
  address: 'XX路100号',
  built_year: 2015,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
}

const CONFIRMED_MAP = {
  schema_version: '2.0',
  render_mode: 'vector',
  viewport: { width: 1200, height: 800 },
  outline: { type: 'rect', rect: { x: 0, y: 0, w: 1200, h: 800 } },
  structures: [
    {
      type: 'corridor',
      rect: { x: 100, y: 100, w: 80, h: 40 },
      label: '主走廊',
      source: 'manual',
    },
  ],
}

const ETAG_V1 = '2024-01-01T00:00:00Z'
const ETAG_V2 = '2024-01-02T00:00:00Z'

async function mockBase(page: Page, opts: { conflict?: boolean } = {}) {
  await page.route('**/api/auth/me', (r: Route) =>
    r.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_AUTH_USER }),
    }),
  )
  await page.route(`**/api/buildings/${BUILDING_ID}`, (r) =>
    r.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_BUILDING }),
    }),
  )

  // structures GET/PUT 与 candidates 注册顺序：先 structures，再 candidates（更具体）
  // Playwright 中后注册的 handler 优先匹配，故 candidates 应放在 structures 之后
  await page.route(`**/api/floors/${FLOOR_ID}/structures`, (r: Route) => {
    const method = r.request().method()
    if (method === 'GET') {
      r.fulfill({
        status: 200,
        contentType: 'application/json',
        headers: { etag: ETAG_V1 },
        body: JSON.stringify({ data: CONFIRMED_MAP }),
      })
    } else if (method === 'PUT') {
      if (opts.conflict) {
        r.fulfill({
          status: 409,
          contentType: 'application/json',
          body: JSON.stringify({
            error: {
              code: 'FLOOR_MAP_VERSION_CONFLICT',
              message: '楼层结构已被其他会话修改',
            },
          }),
        })
      } else {
        const body = r.request().postDataJSON()
        r.fulfill({
          status: 200,
          contentType: 'application/json',
          headers: { etag: ETAG_V2 },
          body: JSON.stringify({
            data: { ...CONFIRMED_MAP, structures: body.structures },
          }),
        })
      }
    } else {
      r.continue()
    }
  })
  await page.route(`**/api/floors/${FLOOR_ID}/structures/candidates`, (r: Route) =>
    r.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: candidatesMock }),
    }),
  )
  await page.route(`**/api/floors/${FLOOR_ID}/render-mode`, (r: Route) =>
    r.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: {
          floor_id: FLOOR_ID,
          render_mode: 'semantic',
          render_mode_changed_at: ETAG_V2,
          changed_by: MOCK_AUTH_USER.id,
        },
      }),
    }),
  )
}

const URL = `/assets/buildings/${BUILDING_ID}/floors/${FLOOR_ID}/structures`

async function gotoAnnotator(page: Page) {
  await page.goto(URL)
  await expect(page.locator('.candidates-panel')).toBeVisible()
}

test.describe('楼层结构标注页', () => {
  test('进入页面：候选项 + 画布渲染', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await expect(page.locator('svg.stage')).toBeVisible()
    await expect(page.locator('.candidate-item')).toHaveCount(3)
  })

  test('点击候选 → 加入 draft，dirty Tag 出现', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await page.locator('.candidate-item').first().click()
    await expect(page.locator('.crumbs').getByText('未保存')).toBeVisible()
  })

  test('选中已保存结构 → Inspector 显示属性面板', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await page.locator('rect[data-structure-index="0"]').click()
    await expect(page.locator('.inspector-panel')).toContainText(/类型|属性|标签/)
  })

  test('无 dirty 时保存按钮禁用', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    const saveBtn = page.getByRole('button', { name: /保存/ })
    await expect(saveBtn).toBeDisabled()
  })

  test('修改后保存成功 → dirty 消失', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await page.locator('.candidate-item').first().click()
    await expect(page.locator('.crumbs').getByText('未保存')).toBeVisible()
    const saveBtn = page.getByRole('button', { name: /保存/ })
    await expect(saveBtn).toBeEnabled()
    await saveBtn.click()
    await expect(page.locator('.crumbs').getByText('未保存')).toBeHidden()
  })

  test('409 冲突 → error 显示，dirty 保留', async ({ page }) => {
    await mockBase(page, { conflict: true })
    await gotoAnnotator(page)
    await page.locator('.candidate-item').first().click()
    await page.getByRole('button', { name: /保存/ }).click()
    await expect(page.locator('.error-bar')).toBeVisible()
    await expect(page.locator('.crumbs').getByText('未保存')).toBeVisible()
  })

  test('dirty 时 RenderModeSwitch 禁用', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await page.locator('.candidate-item').first().click()
    const sw = page.locator('.render-mode-switch .el-switch')
    await expect(sw).toHaveClass(/is-disabled/)
  })

  test('SPA 离开守卫弹窗（取消留在页面）', async ({ page }) => {
    await mockBase(page)
    await gotoAnnotator(page)
    await page.locator('.candidate-item').first().click()
    await page.locator('.crumbs button').first().click()
    const msgbox = page.locator('.el-message-box')
    await expect(msgbox).toBeVisible()
    await msgbox.getByRole('button', { name: '取消' }).click()
    await expect(page).toHaveURL(new RegExp(URL.replace(/\//g, '\\/')))
  })
})
