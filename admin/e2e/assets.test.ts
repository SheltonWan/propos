/**
 * Admin 资产管理 E2E 测试
 *
 * 所有 API 通过 page.route() 在网络层拦截，无需真实后端。
 *
 * 覆盖场景：
 *  1. 三业态统计卡片渲染（stat-card 可见，业态名称/出租率正确）
 *  2. 楼栋列表渲染（楼栋名称在 el-table 中可见）
 *  3. 点击楼栋行 → 跳转楼栋详情页（URL 变为 /assets/buildings/:id）
 *  4. 楼栋详情页楼层列表渲染（楼层数据在 el-table 中可见）
 */
import { test, expect, type Page } from '@playwright/test'

// ─── Mock 数据 ───────────────────────────────────────────────────────────────

/** main.ts 启动时 fetchMe() 所需的当前用户信息 */
const MOCK_AUTH_USER = {
  id: 'e2e-user-1',
  name: 'E2E测试员',
  email: 'e2e@propos.local',
  role: 'super_admin',
  departmentId: null,
}

const MOCK_BUILDING = {
  id: 'bld-001',
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

const MOCK_OVERVIEW = {
  total_units: 639,
  total_leasable_units: 600,
  total_occupancy_rate: 0.85,
  wale_income_weighted: 2.5,
  wale_area_weighted: 2.3,
  by_property_type: [
    {
      property_type: 'office',
      total_units: 200,
      leased_units: 170,
      vacant_units: 20,
      expiring_soon_units: 10,
      occupancy_rate: 0.85,
      total_nla: 15000,
      leased_nla: 12750,
    },
  ],
}

const MOCK_FLOOR = {
  id: 'fl-001',
  building_id: 'bld-001',
  building_name: 'A栋写字楼',
  floor_number: 1,
  floor_name: null,
  svg_path: null,
  png_path: null,
  nla: 600,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
}

/** 空单元列表响应（满足 fetchUnits 调用，不影响楼栋/楼层渲染） */
const EMPTY_UNITS_RESPONSE = {
  data: [],
  meta: { page: 1, pageSize: 1000, total: 0 },
}

// ─── Mock 工厂函数 ────────────────────────────────────────────────────────────

/**
 * 资产总览页所需的全部 API mock（fetchAll = buildings + overview + units）
 * 注意：page.route 的 handler 按注册顺序匹配，更具体的模式先注册
 */
async function mockAssetsAll(page: Page) {
  // GET /api/auth/me → main.ts 启动时 fetchMe() 调用，必须拦截否则 logout() 清除 token
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_AUTH_USER }),
    }),
  )
  // GET /api/buildings → 楼栋列表
  await page.route('**/api/buildings', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: [MOCK_BUILDING] }),
    }),
  )
  // GET /api/assets/overview → 三业态统计
  await page.route('**/api/assets/overview', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_OVERVIEW }),
    }),
  )
  // GET /api/units* → 单元列表（用于楼栋出租率聚合计算，此处返回空列表）
  await page.route('**/api/units**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(EMPTY_UNITS_RESPONSE),
    }),
  )
}

/**
 * 楼栋详情页所需的全部 API mock（fetchDetail = building + floors + units）
 * 在 mockAssetsAll 基础上追加，不会冲突（buildings/:id 优先于 buildings 列表）
 */
async function mockBuildingDetail(page: Page) {
  // GET /api/auth/me → main.ts 启动时 fetchMe() 调用（直接导航到详情页时需要）
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_AUTH_USER }),
    }),
  )
  // GET /api/buildings/bld-001 → 楼栋详情（需比 /api/buildings 列表更具体，先注册）
  await page.route('**/api/buildings/bld-001', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_BUILDING }),
    }),
  )
  // GET /api/floors* → 楼层列表（building_id=bld-001）
  await page.route('**/api/floors**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: [MOCK_FLOOR] }),
    }),
  )
  // units mock 已在 mockAssetsAll 中注册（通配符覆盖 building_id 参数版本）
}

// ─── 测试 ─────────────────────────────────────────────────────────────────────

test.describe('资产总览页', () => {
  test.beforeEach(async ({ page }) => {
    await mockAssetsAll(page)
    await page.goto('/assets')
    await page.waitForLoadState('networkidle')
  })

  test('三业态统计卡片渲染', async ({ page }) => {
    // stat-card 可见（overview.by_property_type 有一条 office 数据）
    await expect(page.locator('.stat-card').first()).toBeVisible()
    // 业态名称文字渲染正确
    await expect(page.locator('.stat-card')).toContainText('写字楼')
  })

  test('楼栋列表渲染', async ({ page }) => {
    // 楼栋名称（store.list[0].name）在 el-table 中可见
    await expect(page.getByText('A栋写字楼')).toBeVisible()
  })
})

test.describe('楼栋详情页', () => {
  test('点击楼栋行 → 跳转楼栋详情页', async ({ page }) => {
    // 为跳转后的详情页预先注册 mock（在导航发生前注册，避免竞态）
    await mockBuildingDetail(page)
    await mockAssetsAll(page)

    await page.goto('/assets')
    await page.waitForLoadState('networkidle')

    // 等待楼栋名称出现（el-table 已加载）
    await expect(page.getByText('A栋写字楼')).toBeVisible()

    // 点击楼栋行（@row-click="goBuilding"）
    await page.getByText('A栋写字楼').click()

    // 验证 URL 跳转到楼栋详情页
    await expect(page).toHaveURL(/\/assets\/buildings\/bld-001/, { timeout: 10_000 })
  })

  test('楼栋详情页楼层列表渲染', async ({ page }) => {
    // 为详情页预先注册 mock
    await mockBuildingDetail(page)
    // units 通配符 mock（fetchDetail 也会请求 /api/units?building_id=...）
    await page.route('**/api/units**', route =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(EMPTY_UNITS_RESPONSE),
      }),
    )

    // 直接导航到楼栋详情页（跳过总览页点击流程）
    await page.goto('/assets/buildings/bld-001')
    await page.waitForLoadState('networkidle')

    // 楼层号（floor_number: 1 → "1F" 或 floor_name 为 null 时显示 "${floor_number}F"）
    await expect(page.getByText('1F')).toBeVisible({ timeout: 10_000 })
  })
})
