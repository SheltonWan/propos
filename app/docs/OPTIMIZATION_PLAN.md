# PropOS 全维度五星优化计划

> 基于 `ARCHITECTURE_REVIEW.md` 审查报告，将 6 个未满星维度全部提升至 ⭐⭐⭐⭐⭐。

## 目标维度

| 维度 | 当前 | 目标 | 所属 Phase |
|------|------|------|-----------|
| 组件设计 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Phase 3 |
| 状态管理 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Phase 2 |
| 测试覆盖 | ⭐ | ⭐⭐⭐⭐⭐ | Phase 4 |
| 代码规范 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Phase 1 |
| 安全性 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Phase 2 |
| 可维护性 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Phase 3 |

---

## Phase 1 — 代码规范工具链

**提升维度**：代码规范 ⭐⭐⭐ → ⭐⭐⭐⭐⭐

| # | 操作 | 文件 |
|---|------|------|
| 1 | 安装 eslint + @antfu/eslint-config + prettier + husky + lint-staged | `package.json` |
| 2 | 创建 ESLint 配置（Vue + TS，声明 uni-app 全局变量） | `eslint.config.mjs` |
| 3 | 创建 Prettier 配置（与现有风格对齐） | `.prettierrc` |
| 4 | 创建 EditorConfig | `.editorconfig` |
| 5 | 配置 husky pre-commit → lint-staged | `.husky/pre-commit` |
| 6 | 新增 lint / lint:fix / format scripts | `package.json` |

---

## Phase 2 — 状态管理解耦 + 安全性补全

**提升维度**：状态管理 ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐ · 安全性 ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐

### 2A. API 层解耦导航逻辑

| # | 操作 | 文件 |
|---|------|------|
| 7 | 响应拦截器 401 移除 `uni.reLaunch()` 和 `clearTokens()`，只抛 ApiError | `src/api/client.ts` |
| 8 | 不再 export `clearTokens`（只 export `setTokens`） | `src/api/client.ts` |
| 9 | Store 新增 `handleAuthError()` 统一处理认证错误 | `src/stores/auth.ts` |
| 10 | `logout()` 移除 `.finally(() => clearTokens())`，清理收口到 Store | `src/api/modules/auth.ts` |

### 2B. 路由守卫补全

| # | 操作 | 文件 |
|---|------|------|
| 11 | 创建 `PUBLIC_PAGES` 白名单 + `isPublicPage()` 辅助函数 | `src/constants/routes.ts` |
| 12 | 从 constants 导入白名单 + 补充 `redirectTo`/`reLaunch` 拦截器 | `src/App.vue` |
| 13 | 创建生产环境配置确保 `VITE_USE_MOCK=false` | `.env.production` |

---

## Phase 3 — 可维护性 + 组件设计

**提升维度**：可维护性 ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐ · 组件设计 ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐

### 3A. 主题平台代码拆分

| # | 操作 | 文件 |
|---|------|------|
| 14 | 提取 H5 平台 DOM 注入逻辑 | `src/platform/theme-h5.ts` |
| 15 | 提取 App-plus 平台 WebView 注入 + 原生背景色逻辑 | `src/platform/theme-app.ts` |
| 16 | 条件编译统一导出平台接口 | `src/platform/index.ts` |
| 17 | 重构 Store 只保留状态管理，委托给 platform 模块 | `src/stores/theme.ts` |

### 3B. 全局错误处理 + 通用 Composables

| # | 操作 | 文件 |
|---|------|------|
| 18 | 注册 `app.config.errorHandler` 全局错误捕获 | `src/main.ts` |
| 19 | 封装统一 Toast composable | `src/composables/useToast.ts` |
| 20 | 封装通用列表分页 composable | `src/composables/useList.ts` |

### 3C. 文档

| # | 操作 | 文件 |
|---|------|------|
| 21 | 项目 README（技术栈、开发环境、脚本、架构概览） | `README.md` |

---

## Phase 4 — 测试体系

**提升维度**：测试覆盖 ⭐ → ⭐⭐⭐⭐⭐

### 4A. 测试基础设施

| # | 操作 | 文件 |
|---|------|------|
| 22 | 安装 vitest + @vue/test-utils + happy-dom + @pinia/testing | `package.json` |
| 23 | Vitest 配置（happy-dom + 路径别名 + 全局 setup） | `vitest.config.ts` |
| 24 | uni-app API 全局 mock shim | `src/__tests__/setup.ts` |
| 25 | 新增 test / test:run / test:coverage scripts | `package.json` |

### 4B. 单元测试

| # | 测试目标 | 文件 |
|---|----------|------|
| 26 | API client：请求、Mock fallthrough、401 刷新锁 | `src/api/__tests__/client.test.ts` |
| 27 | Mock 引擎：命中/未命中、延迟、错误 | `src/api/mock/__tests__/index.test.ts` |
| 28 | Auth Store：login/logout/fetchMe/hasPermission | `src/stores/__tests__/auth.test.ts` |
| 29 | Theme Store：initializeTheme/setTheme/setThemeById | `src/stores/__tests__/theme.test.ts` |
| 30 | Theme Constants：buildThemeVars/isThemeId/预设完整性 | `src/constants/__tests__/theme.test.ts` |
| 31 | navigationIntent：set/consume 生命周期 | `src/utils/__tests__/navigationIntent.test.ts` |
| 32 | usePageThemeMeta：背景色/文字样式响应式 | `src/composables/__tests__/usePageThemeMeta.test.ts` |
| 33 | AppCard：默认渲染 + variant + loading | `src/components/base/__tests__/AppCard.test.ts` |

### 4C. uni-app Mock 方案

测试基础设施同时支持两种 uni-app Mock 方案：

1. **内置 shim**（`src/__tests__/setup.ts`）：手写轻量 `uni` 全局对象 mock，覆盖核心 API（`getStorageSync`、`setStorageSync`、`removeStorageSync`、`reLaunch`、`navigateTo`、`showToast` 等）。零依赖，即刻可用。

2. **社区插件**（可选升级）：如 `@uni-helper/vite-plugin-uni-mock` 等社区方案成熟后可替换 shim。`vitest.config.ts` 预留 `setupFiles` 数组，插入新 setup 文件即可切换。

---

## 验证清单

- [ ] `pnpm lint` — 零 ESLint 错误
- [ ] `pnpm format --check` — 格式化一致性
- [ ] `pnpm type-check` — TypeScript 编译无错误
- [ ] `pnpm test:run` — 所有测试通过
- [ ] `pnpm lint:theme` — 主题 lint 零违规
- [ ] `pnpm dev:h5` — H5 端功能回归正常
- [ ] `.env.production` 中 `VITE_USE_MOCK=false`

## 边界声明

- **包含**：工具链配置、架构解耦重构、测试代码、通用 composable、文档
- **排除**：具体业务页面实现（Dashboard/工单/财务等，需配合产品需求）
- **E2E 测试**：当前阶段不包含，业务稳定后补充
