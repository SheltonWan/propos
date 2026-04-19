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
| `pnpm test` | 运行测试（watch 模式） |
| `pnpm test:run` | 运行测试（单次） |
| `pnpm test:coverage` | 运行测试 + 覆盖率 |

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
