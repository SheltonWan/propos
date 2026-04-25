import { defineConfig, devices } from '@playwright/test'

/**
 * PropOS uni-app 集成测试配置
 *
 * 目标平台：WebKit（与 iOS Safari 共享引擎，等效于 iPhone 模拟器）
 * 测试前提：
 *   1. 本地后端已在 http://localhost:8080 运行
 *   2. 在 .env.e2e 中配置 E2E_USER_EMAIL / E2E_USER_PASSWORD（参考 .env.e2e.example）
 */
export default defineConfig({
  testDir: './e2e',
  // 加载 .env.e2e，所有 project 共享此时机注入的环境变量
  globalSetup: './e2e/global-setup.ts',
  timeout: 30_000,
  // 认证测试需要顺序执行，避免 session 互相干扰
  fullyParallel: false,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html', { outputFolder: 'e2e/reports' }], ['list']],

  use: {
    baseURL: 'http://localhost:5174',
    // 保留失败时的完整 trace 便于调试
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    // ─── Phase 1：登录态准备（依赖真实后端）─────────────────────────────────
    {
      name: 'auth-setup',      use: { ...devices['iPhone 14'] },      testMatch: /e2e\/setup\/auth\.setup\.ts/,
    },
    // ─── Phase 2：全场景集成测试（WebKit = iOS Safari 引擎）──────────────────
    {
      name: 'iOS WebKit',
      use: {
        ...devices['iPhone 14'],
        // 已登录态由 auth-setup 写入，复用到此 project
        storageState: 'e2e/.auth/user.json',
      },
      // 排除需要真实后端的 real/ 目录；那些测试由 Real Backend project 覆盖
      testIgnore: /e2e\/real\/.+\.test\.ts/,
      dependencies: ['auth-setup'],
    },
    // ─── 无认证场景（单独 project，不依赖 auth-setup）────────────────────────
    {
      name: 'iOS WebKit (unauthenticated)',
      use: { ...devices['iPhone 14'] },
      testMatch: /e2e\/auth\.test\.ts/,
    },
    // ─── Phase 1（真实后端）：真实登录并保存 token ────────────────────────────
    {
      name: 'real-auth-setup',
      use: { ...devices['iPhone 14'] },
      testMatch: /e2e\/setup\/real-auth\.setup\.ts/,
    },
    // ─── Phase 2（真实后端）：冒烟测试，透传请求至真实后端 ─────────────────────
    {
      name: 'Real Backend',
      use: {
        ...devices['iPhone 14'],
        storageState: 'e2e/.auth/real.user.json',
      },
      testMatch: /e2e\/real\/.+\.test\.ts/,
      dependencies: ['real-auth-setup'],
    },
  ],

  // ─── H5 开发服务器（测试时自动启动，端口 5174 避免与 dev:h5 默认 5173 冲突） ─────
  webServer: {
    // 使用 env 选项注入 API_PROXY_TARGET，比 shell 内联赋值更可靠
    // API_PROXY_TARGET：非 VITE_ 前缀，仅用于 Vite proxy 配置，不会注入客户端包
    // 客户端 BASE_URL 为空字符串，请求走相对路径 /api/* → Vite proxy → 8080
    command: 'pnpm dev:h5',
    env: {
      API_PROXY_TARGET: 'http://localhost:8080',
      // 覆盖 .env.development 中的 VITE_API_BASE_URL=http://localhost:8080
      // 使 luch-request 使用相对路径 /api/*，由 Vite proxy 转发至 8080
      // process.env 的 VITE_* 变量优先级高于 .env 文件
      VITE_API_BASE_URL: '',
      VITE_USE_MOCK: 'false',
      VITE_TEST_PORT: '5174',
    },
    url: 'http://localhost:5174',
    // 非 CI 时复用已启动的测试服务器（5174 上的 server 始终是 VITE_USE_MOCK=false 版本）
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    stdout: 'ignore',
    stderr: 'pipe',
  },
})
