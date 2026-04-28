/**
 * Admin Mock 认证状态初始化
 *
 * 不依赖真实后端：
 *  1. 通过 page.addInitScript 在页面脚本执行前注入 mock token
 *  2. 导航到 /dashboard，验证 authGuard（检查 localStorage.access_token）放行
 *  3. 保存含 token 的 localStorage 到 e2e/.auth/user.json，供后续 project 复用
 */
import path from 'node:path'
import * as fs from 'node:fs'
import { test as setup, expect } from '@playwright/test'

const AUTH_FILE = path.join(__dirname, '../.auth/user.json')

const MOCK_TOKENS = {
  access_token: 'e2e-mock-access-token',
  refresh_token: 'e2e-mock-refresh-token',
}

setup('初始化并保存 Mock 登录态', async ({ page }) => {
  // 在页面任何脚本执行前注入 token（包括 authGuard 在 router.beforeEach 中的检查）
  await page.addInitScript(
    ([at, rt]) => {
      localStorage.setItem('access_token', at)
      localStorage.setItem('refresh_token', rt)
    },
    [MOCK_TOKENS.access_token, MOCK_TOKENS.refresh_token],
  )

  // 拦截 main.ts 启动时的 fetchMe() 调用
  // main.ts 在 app.mount() 前调用 authStore.fetchMe()，若无响应则触发 logout() 清除 token
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: {
          id: 'e2e-user-1',
          name: 'E2E测试员',
          email: 'e2e@propos.local',
          role: 'super_admin',
          departmentId: null,
        },
      }),
    }),
  )

  // 导航到受保护路由：authGuard 检测到 access_token → 放行（无需后端验证）
  await page.goto('/dashboard')
  await page.waitForLoadState('domcontentloaded')

  // 确认未被重定向到登录页（authGuard 已成功放行）
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10_000 })

  // 保存 localStorage 到 storageState 文件，供后续 project 自动载入
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true })
  await page.context().storageState({ path: AUTH_FILE })
})
