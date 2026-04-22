/**
 * 全局认证状态初始化
 *
 * 不依赖真实后端：
 *  1. 通过 page.addInitScript 在页面脚本执行前注入 mock token
 *  2. 通过 page.route 拦截 /api/auth/me，返回固定测试用户
 *  3. 导航到 splash → 检测到 token → 跳转首页
 *  4. 保存含 token 的 localStorage 到 e2e/.auth/user.json 供后续 project 复用
 */

import path from 'node:path'
import * as fs from 'node:fs'
import { test as setup, expect } from '@playwright/test'

const AUTH_FILE = path.join(__dirname, '../.auth/user.json')

/** 测试固定数据（与 auth.test.ts 保持一致） */
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

setup('初始化并保存登录态', async ({ page }) => {
  // ─── 在页面脚本执行前注入 token ──────────────────────────────────────────
  await page.addInitScript(
    ([at, rt]) => {
      localStorage.setItem('access_token', at)
      localStorage.setItem('refresh_token', rt)
    },
    [MOCK_TOKENS.access_token, MOCK_TOKENS.refresh_token],
  )

  // ─── Mock /api/auth/me 返回固定用户 ────────────────────────────────────────
  await page.route('**/api/auth/me', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: MOCK_USER }),
    }),
  )

  // ─── 打开 splash，检测 token 并跳转首页 ───────────────────────────────────
  await page.goto('/#/pages/splash/index')
  await page.waitForLoadState('networkidle')

  // splash 读到 token → fetchMe 成功（已 mock）→ 跳转首页
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 15_000 })

  // ─── 保存 localStorage（含 access_token / refresh_token）─────────────────
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true })
  await page.context().storageState({ path: AUTH_FILE })
})

