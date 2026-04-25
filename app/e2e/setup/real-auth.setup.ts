/**
 * 真实后端认证状态初始化
 *
 * 通过 UI 登录表单与真实后端完成认证，
 * 保存 storageState 到 e2e/.auth/real.user.json。
 *
 * 前提：
 *  1. 后端服务运行在 http://localhost:8080（Vite proxy 代理 /api/*）
 *  2. .env.e2e 中配置了有效的 E2E_USER_EMAIL / E2E_USER_PASSWORD
 */

import path from 'node:path'
import * as fs from 'node:fs'
import { test as setup, expect } from '@playwright/test'

const AUTH_FILE = path.join(__dirname, '../.auth/real.user.json')

setup('真实后端：UI 登录并保存认证态', async ({ page }) => {
  const email = process.env.E2E_USER_EMAIL
  const password = process.env.E2E_USER_PASSWORD

  if (!email || !password) {
    throw new Error(
      '[real-auth-setup] 未配置 E2E_USER_EMAIL / E2E_USER_PASSWORD',
    )
  }

  // ─── 打开登录页 ────────────────────────────────────────────────────────────
  await page.goto('/#/pages/auth/login')
  await page.waitForLoadState('networkidle')

  // ─── 填写并提交 ────────────────────────────────────────────────────────────
  const emailInput = page.locator('[data-testid="login-email"] input')
  await expect(emailInput).toBeVisible({ timeout: 10_000 })
  await emailInput.fill(email)

  const passwordInput = page.locator('[data-testid="login-password"] input')
  await expect(passwordInput).toBeVisible()
  await passwordInput.fill(password)

  const submitBtn = page.locator('[data-testid="login-submit"]')
  await expect(submitBtn).toBeVisible()
  await submitBtn.click()

  // ─── 等待跳转首页（真实后端认证，放宽超时） ──────────────────────────────────
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // ─── 保存含真实 token 的 storageState ─────────────────────────────────────
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true })
  await page.context().storageState({ path: AUTH_FILE })

  console.log(`[real-auth-setup] 认证态已保存（用户: ${email}）`)
})
