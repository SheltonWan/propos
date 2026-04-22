import { defineConfig, devices } from '@playwright/test'

/**
 * PropOS 真实后端 E2E 测试配置
 *
 * 与 playwright.config.ts 的区别：
 *  - 所有 API 请求直接透传至真实后端（不使用 page.route() mock）
 *  - auth-setup 通过 UI 表单真实登录，token 由后端签发
 *  - 测试文件全部位于 e2e/real/ 目录
 *
 * 前置条件：
 *  1. 后端服务已在 http://localhost:8080 运行，数据库已就绪
 *  2. 在 .env.e2e 中配置真实测试账号凭据（E2E_USER_EMAIL / E2E_USER_PASSWORD）
 *  3. 测试账号在后端数据库中存在且角色权限正确
 */
export default defineConfig({
  testDir: './e2e/real',
  globalSetup: './e2e/global-setup.ts',
  timeout: 30_000,
  // 真实后端有状态，顺序执行避免并发写入互相干扰
  fullyParallel: false,
  retries: 0,
  reporter: [['html', { outputFolder: 'e2e/reports/real' }], ['list']],

  use: {
    baseURL: 'http://localhost:5174',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    // ─── Phase 1：真实登录，保存有效 token ────────────────────────────────────
    {
      name: 'real-auth-setup',
      use: { ...devices['iPhone 14'] },
      testMatch: /setup\/auth\.real\.setup\.ts/,
    },
    // ─── Phase 2：携带真实 token 运行冒烟测试 ────────────────────────────────
    {
      name: 'iOS WebKit (real)',
      use: {
        ...devices['iPhone 14'],
        storageState: 'e2e/.auth/real.user.json',
      },
      dependencies: ['real-auth-setup'],
    },
  ],

  // ─── H5 开发服务器（复用已启动的实例） ──────────────────────────────────────
  webServer: {
    command: 'VITE_API_BASE_URL=http://localhost:8080 VITE_USE_MOCK=false VITE_TEST_PORT=5174 pnpm dev:h5',
    url: 'http://localhost:5174',
    // 始终复用（真实后端测试通常在本地手动触发，服务器一般已在运行）
    reuseExistingServer: true,
    timeout: 120_000,
    stdout: 'ignore',
    stderr: 'pipe',
  },
})
