# PropOS App

跨平台物业管理应用（H5 / 微信小程序 / App / HarmonyOS）。

## 技术栈

| 类别 | 方案 |
|------|------|
| 框架 | uni-app 3.0 + Vue 3.4 (Composition API) |
| 语言 | TypeScript 5.4 (strict) |
| 状态 | Pinia 2.1 |
| HTTP | luch-request 3.1 + 内置 Mock 引擎 |
| UI | Wot Design Uni 1.5 + 自定义 Design Token |
| 构建 | Vite 5.2 + @dcloudio/vite-plugin-uni |
| 规范 | ESLint (@antfu/eslint-config) + Prettier + Husky |
| 测试 | Vitest + @vue/test-utils + happy-dom |

## 快速开始

```bash
# 安装依赖
pnpm install

# H5 开发
pnpm dev:h5

# 微信小程序开发
pnpm dev:mp-weixin

# App 开发
pnpm dev:app-plus
```

## 常用脚本

| 命令 | 说明 |
|------|------|
| `pnpm dev:h5` | 启动 H5 开发服务器 |
| `pnpm build:h5` | 构建 H5 生产包 |
| `pnpm lint` | ESLint 检查 |
| `pnpm lint:fix` | ESLint 自动修复 |
| `pnpm format` | Prettier 格式化 |
| `pnpm type-check` | TypeScript 类型检查 |
| `pnpm lint:theme` | 主题变量用法校验 |
| `pnpm test` | 单元测试（watch 模式） |
| `pnpm test:run` | 单元测试（单次） |
| `pnpm test:coverage` | 单元测试 + 覆盖率 |
| `pnpm test:e2e` | E2E 集成测试 |
| `pnpm test:e2e:ui` | E2E 集成测试（Playwright UI 模式） |
| `pnpm test:e2e:debug` | E2E 集成测试（逐步调试） |

## 项目结构

```
src/
├── api/            # HTTP 客户端 + Mock 引擎 + API 模块
├── components/     # 通用组件（base / auth / navigation）
├── composables/    # 可复用逻辑（useToast / useList / useSafeArea 等）
├── constants/      # 常量（API 路径 / 业务规则 / 路由 / 主题）
├── pages/          # 页面视图
├── platform/       # 平台适配层（H5 / App-plus DOM 注入）
├── stores/         # Pinia 全局状态
├── styles/         # SCSS Design Tokens + Mixins
├── types/          # TypeScript 类型定义
├── utils/          # 工具函数
└── static/         # 静态资源
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `VITE_API_BASE_URL` | API 基础地址 |
| `VITE_USE_MOCK` | 启用 Mock 引擎（`true` / `false`） |

## 测试说明

### 单元测试（Vitest）

```bash
pnpm test:run        # 单次运行
pnpm test            # watch 模式
pnpm test:coverage   # 生成覆盖率报告
```

- 测试框架：Vitest + @vue/test-utils + happy-dom
- 测试文件位于 `src/**/__tests__/*.test.ts`

### E2E 集成测试（Playwright）

```bash
pnpm test:e2e         # 运行全部 E2E 测试
pnpm test:e2e:ui      # 打开 Playwright UI 模式（可视化调试）
pnpm test:e2e:debug   # 逐步调试模式
```

**无需启动后端服务**。测试流程完全自包含：

- Playwright 自动拉起 H5 开发服务器（端口 5174），测试结束后自动关闭
- 所有 API 请求通过 `page.route()` 在网络层拦截并返回固定 mock 数据，不依赖真实后端
- 认证态（token）通过 `page.addInitScript()` 在页面脚本执行前注入 localStorage

测试目标平台：iOS WebKit（与 iPhone Safari 共享引擎）。

**查看测试报告：**

```bash
pnpm exec playwright show-report e2e/reports
```

**E2E 测试覆盖场景：**

| 场景 | 文件 |
|------|------|
| 登录成功 / 密码错误 / 登录态持久化 | `e2e/auth.test.ts` |
| 退出登录（携带 refresh_token） | `e2e/auth.test.ts` |
| access_token 过期后静默刷新 | `e2e/auth.test.ts` |
| 双 token 均失效跳回登录页 | `e2e/auth.test.ts` |
| 首页用户信息 / API 失败降级 / 断网不崩溃 | `e2e/dashboard.test.ts` |
