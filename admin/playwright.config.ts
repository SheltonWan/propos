import { defineConfig, devices } from '@playwright/test'

/**
 * PropOS Admin E2E 测试配置（Mock 轨道）
 *
 * 目标：PC 桌面端管理后台，Chromium + Firefox 双浏览器覆盖
 * 测试前提：
 *   - 无需真实后端（所有 API 通过 page.route() 在网络层拦截）
 *   - Vite 开发服务器自动启动（port 5173）
 */
export default defineConfig({
  testDir: './e2e',
  globalSetup: './e2e/global-setup.ts',
  timeout: 30_000,
  // 认证状态初始化需顺序执行，避免并发写入 storageState 文件
  fullyParallel: false,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html', { outputFolder: 'e2e/reports' }], ['list']],

  use: {
    baseURL: 'http://localhost:5173',
    // 首次重试时保存完整 trace，便于排查失败原因
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    // Admin 是 PC 后台，使用桌面分辨率
    viewport: { width: 1440, height: 900 },
  },

  projects: [
    // ─── Phase 1：Mock 登录态准备 ──────────────────────────────────────────
    // 注入 mock token → 验证 authGuard 放行 → 保存 storageState 到 .auth/user.json
    {
      name: 'auth-setup',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /e2e\/setup\/auth\.setup\.ts/,
    },

    // ─── Phase 2：Chromium 已认证场景 ──────────────────────────────────────
    // 复用 auth-setup 写入的 storageState（含 mock access_token）
    {
      name: 'chromium-mock',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'e2e/.auth/user.json',
      },
      // 排除：setup 文件 / 真实后端文件 / 未认证场景（auth.test.ts）
      testIgnore: [/e2e\/setup\/.+/, /e2e\/real\/.+/, /e2e\/auth\.test\.ts/],
      dependencies: ['auth-setup'],
    },

    // ─── Phase 2b：Chromium 未认证场景 ─────────────────────────────────────
    // auth.test.ts 测试登录流程，不应有预设 token
    {
      name: 'chromium-unauthenticated',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /e2e\/auth\.test\.ts/,
    },

    // ─── Phase 3：Firefox 已认证场景 ───────────────────────────────────────
    {
      name: 'firefox-mock',
      use: {
        ...devices['Desktop Firefox'],
        storageState: 'e2e/.auth/user.json',
      },
      testIgnore: [/e2e\/setup\/.+/, /e2e\/real\/.+/, /e2e\/auth\.test\.ts/],
      dependencies: ['auth-setup'],
    },

    // ─── Phase 3b：Firefox 未认证场景 ──────────────────────────────────────
    {
      name: 'firefox-unauthenticated',
      use: { ...devices['Desktop Firefox'] },
      testMatch: /e2e\/auth\.test\.ts/,
    },
  ],

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:5173',
    // 本地开发时复用已启动的 Vite 服务器；CI 每次启动干净实例
    reuseExistingServer: !process.env.CI,
    stdout: 'ignore',
    stderr: 'pipe',
  },
})
