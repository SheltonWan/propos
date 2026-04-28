/**
 * Admin 真实后端登录态初始化
 *
 * 依赖真实后端 + .env.e2e 凭据：
 *  1. 打开登录页，填写真实账号密码
 *  2. 提交表单，等待后端验证并跳转 /dashboard
 *  3. 保存含真实 token 的 storageState 到 e2e/.auth/real.user.json
 */
import path from 'node:path'
import * as fs from 'node:fs'
import { test as setup, expect } from '@playwright/test'

const REAL_AUTH_FILE = path.join(__dirname, '../.auth/real.user.json')

setup('真实后端登录并保存登录态', async ({ page }) => {
  const email = process.env.E2E_USER_EMAIL
  const password = process.env.E2E_USER_PASSWORD

  if (!email || !password) {
    throw new Error(
      '[real auth setup] 未配置 E2E_USER_EMAIL / E2E_USER_PASSWORD\n' +
        '请参考 .env.e2e.example 创建 .env.e2e 文件',
    )
  }

  await page.goto('/login')

  // 填写真实账号密码（与 LoginView.vue 的 placeholder 对齐）
  await page.fill('input[placeholder="请输入账号邮箱"]', email)
  await page.fill('input[placeholder="请输入密码"]', password)

  // 提交表单：触发 handleLogin → authStore.login → 后端验证 → 写入 token → 跳转
  await page.click('button[type="submit"]')

  // 等待后端完成认证并跳转（真实网络，适当放宽超时）
  await expect(page).toHaveURL(/\/dashboard/, { timeout: 30_000 })

  // 保存含真实 token 的 localStorage 供后续测试复用
  fs.mkdirSync(path.dirname(REAL_AUTH_FILE), { recursive: true })
  await page.context().storageState({ path: REAL_AUTH_FILE })
})
