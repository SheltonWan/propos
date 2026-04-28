import { defineConfig, devices } from '@playwright/test'

/**
 * PropOS Admin E2E 测试配置（真实后端轨道）
 *
 * 目标：验证前后端集成链路（冒烟测试）
 * 测试前提：
 *   1. 本地后端已在 http://localhost:8080 运行
 *   2. 在 .env.e2e 中配置 E2E_USER_EMAIL / E2E_USER_PASSWORD（参考 .env.e2e.example）
 */
export default defineConfig({
  testDir: './e2e',
  globalSetup: './e2e/global-setup.ts',
  // 真实后端测试超时适当放宽（数据库查询、网络往返）
  timeout: 60_000,
  // 真实后端有状态，顺序执行避免数据冲突
  fullyParallel: false,
  // 真实后端测试不重试（避免副作用累积）
  retries: 0,
  reporter: [['html', { outputFolder: 'e2e/reports/real' }], ['list']],

  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    viewport: { width: 1440, height: 900 },
  },

  projects: [
    // ─── Phase 1：真实后端登录态准备 ────────────────────────────────────────
    // UI 表单填写真实凭据 → 等待后端签发 token → 保存 storageState
    {
      name: 'real-auth-setup',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /e2e\/setup\/auth\.real\.setup\.ts/,
    },

    // ─── Phase 2：Chromium 真实后端测试 ─────────────────────────────────────
    {
      name: 'chromium-real',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'e2e/.auth/real.user.json',
      },
      testMatch: /e2e\/real\/.+\.test\.ts/,
      dependencies: ['real-auth-setup'],
    },

    // ─── Phase 3：Firefox 真实后端测试 ──────────────────────────────────────
    {
      name: 'firefox-real',
      use: {
        ...devices['Desktop Firefox'],
        storageState: 'e2e/.auth/real.user.json',
      },
      testMatch: /e2e\/real\/.+\.test\.ts/,
      dependencies: ['real-auth-setup'],
    },
  ],

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    stdout: 'ignore',
    stderr: 'pipe',
    env: {
      // 真实后端模式：发送相对路径 /api/*，Vite proxy 转发到后端
      // 默认 vite.config.ts 已配置 proxy.'/api'.target = 'http://localhost:8080'
      VITE_API_BASE_URL: '',
    },
  },
})
