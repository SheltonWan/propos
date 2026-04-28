/**
 * Admin 用户管理 E2E 测试
 *
 * 所有 API 通过 page.route() 在网络层拦截，无需真实后端。
 *
 * 覆盖场景：
 *  1. 用户表格渲染（用户名在 el-table 中可见）
 *  2. 搜索参数正确传递（waitForRequest 捕获包含 search= 的请求）
 *  3. 角色过滤参数正确传递（waitForRequest 捕获包含 role=leasing_specialist 的请求）
 *  4. total > pageSize 时分页器可见
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

const MOCK_USER_SUMMARY = {
  id: 'usr-001',
  name: '张三',
  email: 'zhangsan@propos.local',
  role: 'leasing_specialist',
  department_id: 'dept-001',
  department_name: '租务部',
  is_active: true,
  last_login_at: '2024-04-28T10:00:00Z',
  created_at: '2024-01-01T00:00:00Z',
}

// ─── Mock 工厂函数 ────────────────────────────────────────────────────────────

/**
 * UsersView.onMounted 依赖的全部 API mock
 * - departmentsStore.load() → GET /api/departments
 * - store.load()           → GET /api/users
 */
async function mockUsersAll(page: Page, total = 25) {
  // GET /api/auth/me → main.ts 启动时 fetchMe() 调用，必须拦截否则 logout() 清除 token 并重定向 /login
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_AUTH_USER }),
    }),
  )
  // GET /api/departments → 空列表（部门下拉不影响用户表格渲染）
  await page.route('**/api/departments**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: [] }),
    }),
  )
  // GET /api/users* → 用户列表（total > 20 以触发分页器显示）
  await page.route('**/api/users**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: [MOCK_USER_SUMMARY],
        meta: { page: 1, pageSize: 20, total },
      }),
    }),
  )
}

// ─── 测试 ─────────────────────────────────────────────────────────────────────

test.describe('用户管理页', () => {
  test.beforeEach(async ({ page }) => {
    await mockUsersAll(page)
    await page.goto('/system/users')
    await page.waitForLoadState('networkidle')
  })

  test('用户表格渲染', async ({ page }) => {
    // 页面标题（h2.title = "员工账号管理"）
    await expect(page.locator('h2').filter({ hasText: '员工账号管理' })).toBeVisible()

    // 用户名（store.list[0].name）在 el-table 中可见
    await expect(page.getByText('张三')).toBeVisible()

    // 邮箱脱敏后仍显示（el-table 中的单元格）
    await expect(page.getByText('zhangsan@propos.local')).toBeVisible()
  })

  test('搜索参数正确传递', async ({ page }) => {
    // 注册 waitForRequest 监听（在触发搜索之前）
    const searchPromise = page.waitForRequest(
      req => req.url().includes('/api/users') && req.url().includes('search='),
    )

    // 填写搜索关键词（el-input placeholder="姓名 / 邮箱"）
    await page.fill('input[placeholder="姓名 / 邮箱"]', '张三')
    // 点击「查询」按钮触发 onSearch → store.load({ ...filterForm, page: 1 })
    await page.locator('button').filter({ hasText: '查询' }).click()

    // 等待并捕获含 search= 的 API 请求
    const searchReq = await searchPromise
    expect(searchReq.url()).toContain('search=')
    // 验证搜索关键词已编码进 URL（"张三" URL 编码为 %E5%BC%A0%E4%B8%89 或直接包含）
    expect(decodeURIComponent(searchReq.url())).toContain('search=张三')
  })

  test('角色过滤参数正确传递', async ({ page }) => {
    // 注册 waitForRequest 监听（在触发操作之前）
    const rolePromise = page.waitForRequest(
      req => req.url().includes('/api/users') && req.url().includes('role=leasing_specialist'),
    )

    // 打开角色下拉（el-form-item label="角色" 内的 el-select）
    const roleFormItem = page.locator('.el-form-item').filter({ hasText: '角色' })
    await roleFormItem.locator('.el-select').click()

    // 等待下拉展开后点击「租务专员」选项（value = 'leasing_specialist'）
    await page.locator('.el-select-dropdown .el-select-dropdown__item').filter({ hasText: '租务专员' }).click()

    // 点击「查询」按钮
    await page.locator('button').filter({ hasText: '查询' }).click()

    // 等待并捕获含 role=leasing_specialist 的 API 请求
    const roleReq = await rolePromise
    expect(roleReq.url()).toContain('role=leasing_specialist')
  })

  test('total > pageSize 时分页器可见', async ({ page }) => {
    // total=25 > pageSize=20 → el-pagination 应出现（v-if="store.meta && store.meta.total > 0"）
    await expect(page.locator('.el-pagination')).toBeVisible()
  })
})
