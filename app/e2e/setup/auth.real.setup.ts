/**
 * 真实后端认证状态初始化
 *
 * 与 auth.setup.ts 的本质区别：
 *  - 不注入任何 page.route() mock
 *  - 直接通过 UI 表单提交，请求透传至真实后端 http://localhost:8080
 *  - token 由后端签发，保存到 e2e/.auth/real.user.json 供后续测试复用
 *
 * 前置条件：
 *  - .env.e2e 中配置 E2E_USER_EMAIL / E2E_USER_PASSWORD
 *  - 后端服务在 http://localhost:8080 正常运行
 */

import path from 'node:path'
import * as fs from 'node:fs'
import { test as setup, expect } from '@playwright/test'

const AUTH_FILE = path.join(__dirname, '../.auth/real.user.json')

setup('真实后端：登录并保存认证状态', async ({ page }) => {
  const email = process.env.E2E_USER_EMAIL
  const password = process.env.E2E_USER_PASSWORD

  if (!email || !password) {
    throw new Error(
      '[e2e:real] 缺少凭据。请在 .env.e2e 中配置 E2E_USER_EMAIL 和 E2E_USER_PASSWORD',
    )
  }

  // ─── 打开登录页 ────────────────────────────────────────────────────────────
  await page.goto('/#/pages/auth/login')
  await page.waitForLoadState('networkidle')

  // ─── 填写真实凭据并提交（请求透传至真实后端） ─────────────────────────────────
  await page.getByTestId('login-email').locator('input').fill(email)
  await page.getByTestId('login-password').locator('input').fill(password)
  await page.getByTestId('login-submit').click()

  // ─── 等待后端响应并跳转首页 ────────────────────────────────────────────────
  await expect(page).toHaveURL(/#\/pages\/dashboard\/index/, { timeout: 20_000 })

  // ─── 验证 token 已写入 localStorage ──────────────────────────────────────
  const accessToken = await page.evaluate(() => localStorage.getItem('access_token'))
  if (!accessToken) {
    throw new Error('[e2e:real] 登录后 access_token 未写入 localStorage，请检查后端和前端实现')
  }

  // ─── 保存含真实 token 的 storageState ────────────────────────────────────
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true })
  await page.context().storageState({ path: AUTH_FILE })

  console.log(`[e2e:real] 登录成功，认证状态已保存至 ${AUTH_FILE}`)
})
