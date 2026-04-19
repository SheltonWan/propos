# PropOS App 架构分析报告

> 审查日期：2026-04-20  
> 技术栈：uni-app 3.0 · Vue 3.4 · TypeScript 5.4 · Pinia 2.1 · Vite 5.2  
> 目标平台：H5 / 微信小程序 / App (iOS·Android) / HarmonyOS

---

## 一、项目概况

PropOS 是一款面向物业运营的多端管理应用，涵盖资产管理、合同租务、财务账单、工单维修、KPI 绩效等核心业务模块。项目当前处于**基础设施搭建阶段**——认证流程、主题系统、基础组件体系已完成，业务页面大部分为占位骨架。

### 技术选型

| 层级 | 选型 | 说明 |
|------|------|------|
| 跨端框架 | uni-app 3.0 (dcloudio) | 一套代码编译多端 |
| 视图层 | Vue 3.4 + Composition API | 响应式 + 组合式开发 |
| 类型系统 | TypeScript 5.4 (strict) | 严格模式，编译期类型检查 |
| 状态管理 | Pinia 2.1.7 | 轻量级、TS 友好的 Store |
| HTTP 客户端 | luch-request 3.1.1 | uni-app 生态 HTTP 库 |
| UI 组件库 | Wot Design Uni 1.5.0 | easycom 自动导入 |
| 样式 | SCSS + CSS 变量 | 主题系统基础 |
| 构建 | Vite 5.2.8 | 快速 HMR + 多端编译 |

---

## 二、目录结构

```
src/
├── api/                    # 数据访问层
│   ├── client.ts           #   HTTP 客户端（拦截器、Token 管理、Mock 桥接）
│   ├── index.ts            #   统一导出
│   ├── mock/               #   Mock 数据层
│   │   ├── auth.ts         #     认证 Mock
│   │   ├── index.ts        #     Mock 路由匹配引擎
│   │   └── types.ts        #     Mock 类型定义
│   └── modules/            #   业务 API 模块
│       └── auth.ts         #     认证 API
├── components/             # UI 组件层
│   ├── auth/               #   认证相关组件
│   ├── base/               #   基础通用组件
│   └── navigation/         #   导航组件
├── composables/            # 逻辑复用层 (Composition Functions)
│   ├── usePageThemeMeta.ts #   页面主题元数据
│   └── useSafeArea.ts      #   安全区适配
├── constants/              # 常量配置层
│   ├── api_paths.ts        #   API 路径
│   ├── business_rules.ts   #   业务规则阈值
│   ├── tabbar.ts           #   TabBar 配置 + SVG 图标
│   ├── theme.ts            #   主题预设定义
│   └── ui_constants.ts     #   UI 尺寸与动画常量
├── pages/                  # 页面视图层
│   ├── assets/             #   资产管理
│   ├── auth/               #   认证（登录/改密）
│   ├── contracts/          #   合同管理
│   ├── dashboard/          #   首页仪表盘
│   ├── finance/            #   财务管理
│   ├── notifications/      #   通知中心
│   ├── profile/            #   个人中心
│   └── workorders/         #   工单管理
├── stores/                 # 状态管理层
│   ├── auth.ts             #   认证状态
│   └── theme.ts            #   主题状态
├── styles/                 # 样式系统层
│   ├── mixins.scss         #   SCSS Mixins
│   └── tokens.scss         #   设计 Token（CSS 变量 → SCSS 变量桥接）
├── types/                  # 类型定义层
│   ├── api.ts              #   API 通用类型（信封、错误类）
│   ├── auth.ts             #   认证领域类型
│   └── index.ts            #   统一 re-export
└── utils/                  # 工具函数层
    └── navigationIntent.ts #   Tab 导航意图管理
```

**评价**：分层清晰，符合**关注点分离 (Separation of Concerns)** 原则。每一层职责明确、边界清楚，数据流向为 `API → Store → Page` 的单向流。

---

## 三、架构优点

### 3.1 API 层封装统一且健壮

**文件**：`src/api/client.ts`

```
请求流程：
  Page/Store
    ↓ 调用 apiGet/apiPost/...
    ↓ tryMock() → Mock 命中？→ 返回 Mock 数据
    ↓ 未命中 → luch-request HTTP
    ↓ 请求拦截器 → 自动注入 Bearer Token
    ↓ 响应拦截器 → 401 自动刷新 Token
    ↓ 返回 data 给调用方
```

**亮点**：

- **统一出口**：所有 HTTP 请求通过 `apiGet/apiPost/apiPut/apiPatch/apiDelete` 五个函数，便于全局拦截、监控和替换底层库。
- **Token 刷新锁**：使用 `isRefreshing` + `refreshSubscribers` 队列，多个并发 401 请求只触发一次 refresh，完成后统一回放，符合 OAuth2 最佳实践。
- **Mock 零开销**：`USE_MOCK=false` 时 `tryMock()` 立即返回 `{ hit: false }`，无额外逻辑执行。

### 3.2 Mock 系统设计精巧

**文件**：`src/api/mock/index.ts`

- 注册表模式：各业务模块导出 `MockHandler[]`，在 `mock/index.ts` 中 spread 汇总。
- Handler 匹配：`method + url` 精确匹配，未匹配则 fallthrough 到真实 HTTP。
- 支持模拟延迟和模拟错误，便于测试边界场景。
- 扩展方便：新增业务 Mock 只需创建文件 + 注册，无需修改框架代码。

### 3.3 主题系统工程化程度极高

**文件**：`src/constants/theme.ts` · `src/stores/theme.ts` · `src/styles/tokens.scss`

```
架构分层：

  constants/theme.ts          → 主题定义（6 预设 × 40+ CSS 变量）
       ↓ buildThemeVars()
  stores/theme.ts             → 运行时状态 + DOM 注入
       ↓ applyThemeToDom()
       ↓ applyThemeToNative()
  styles/tokens.scss          → CSS 变量 → SCSS 变量桥接
       ↓ vite additionalData
  *.vue 组件                  → 直接使用 $color-primary 等
```

**亮点**：

- **工厂模式**：`buildThemeVars(palette)` 从调色板自动派生 40+ CSS 变量（包含 alpha 衍生色），添加新主题只需提供一组基础色。
- **跨平台适配**：
  - H5：直接操作 `document.documentElement.style`
  - App-plus：通过 `plus.webview.evalJS()` 向每个独立 WebView 注入 CSS 变量，同时设置原生容器背景色解决 iOS 弹性回弹白底问题。
  - 多策略重试（遍历所有 webview + 当前页面 + 延迟 150ms 重试）覆盖 webview 创建时序差异。
- **lint 守护**：`scripts/validate-theme-usage.mjs` 自定义 lint 工具扫描所有 `.vue/.ts/.scss` 文件，禁止硬编码颜色/字体，确保主题令牌的一致使用。包含 8 条规则，支持 `theme-guard-ignore-line` 逐行豁免。

### 3.4 类型系统完整

- TypeScript `strict: true`，最大化编译期安全。
- 领域类型完整：`Role`（8 种角色）、`Permission`（25 项权限）使用字面量联合类型，体积小且易维护。
- API 信封 `ApiResponse<T>` / `ApiListResponse<T>` / `ApiErrorResponse` 提供统一的接口契约。
- 自定义 `ApiError` 错误类携带 `code + message + statusCode`，比原生 Error 更具业务语义。
- `types/index.ts` 做统一 re-export，消费方只需 `import type { ... } from '@/types'`。

### 3.5 基础组件设计合理

| 组件 | 职责 | 特性 |
|------|------|------|
| `AppShell` | 页面容器 | 安全区适配、TabBar 集成、loading/empty/error 状态 |
| `PageHeader` | 顶部导航 | Sticky 定位、返回按钮、操作区插槽 |
| `AppCard` | 卡片容器 | 3 种变体、骨架屏、级联动画 |
| `BottomSheet` | 底部弹层 | Mask 关闭、安全区留白、多状态 |
| `AppTabBar` | 自定义 TabBar | 动态 SVG 图标、主题响应、按压动画 |

- 每个页面通过组合 `AppShell` + `PageHeader` + 内容实现统一布局，符合 **Composition over Inheritance**。
- 自定义 TabBar 替代原生 TabBar，解决原生 TabBar 无法自定义样式/动画的限制。

### 3.6 常量管理规范

- `api_paths.ts`：所有 API 路径集中定义（19 个端点），零硬编码 URL。
- `business_rules.ts`：业务阈值（预警天数、逾期节点、KPI 满分线、信用评级周期等）统一提取，避免魔数污染。
- `ui_constants.ts`：动画时长、TabBar 尺寸、分页大小等 UI 常量统一管理。
- `tabbar.ts`：TabBar 配置 + 5 组 SVG 图标渲染函数。

### 3.7 Composables 设计

- `usePageThemeMeta()`：为 `<page-meta>` 元素提供响应式的背景色、文字颜色、页面样式，覆盖 uni-app 原生页面背景。
- `useSafeArea()`：获取设备安全区 insets，适配刘海屏和 Home Indicator。
- 两个 composable 都符合 Vue 3 Composition API 最佳实践：纯函数、返回响应式数据、无副作用。

---

## 四、架构问题与改进建议

### 4.1 🔴 测试体系完全缺失

**严重程度**：高  
**影响范围**：全项目

**现状**：
- 无任何测试文件（无单元测试、组件测试、E2E 测试）
- `package.json` 中无测试相关依赖（vitest、@vue/test-utils 等）
- 无 CI/CD 测试流水线配置

**风险**：
- 重构时无法验证回归
- Token 刷新锁、Mock 匹配等核心逻辑无覆盖
- 业务代码增长后技术债务将急剧累积

**建议**：
```bash
# 推荐工具链
pnpm add -D vitest @vue/test-utils happy-dom

# 优先覆盖：
# 1. src/api/client.ts — Token 刷新流程
# 2. src/api/mock/index.ts — Mock 匹配逻辑
# 3. src/stores/auth.ts — 登录/登出状态流转
# 4. src/constants/theme.ts — buildThemeVars() 输出校验
# 5. src/utils/navigationIntent.ts — set/consume 生命周期
```

---

### 4.2 🔴 缺少 ESLint / Prettier 代码规范工具

**严重程度**：高  
**影响范围**：全项目

**现状**：
- 无 ESLint、Prettier、Stylelint 等代码规范工具
- 无 `.eslintrc` / `.prettierrc` 配置
- 无 husky / lint-staged 做 pre-commit 守卫
- 唯一的 lint 工具是自定义的 `validate-theme-usage.mjs`

**风险**：
- 多人协作时代码风格可能割裂
- 潜在的代码质量问题（未使用变量、隐式 any 等）无法自动发现

**建议**：
```bash
# 推荐 @antfu/eslint-config（Vue + TS 一体化）
pnpm add -D eslint @antfu/eslint-config

# pre-commit 守卫
pnpm add -D husky lint-staged
```

---

### 4.3 🟡 路由守卫实现存在漏洞

**严重程度**：中  
**文件**：`src/App.vue`

**问题 1 — 拦截覆盖不全**：

```ts
// 当前只拦截了两种导航方式
uni.addInterceptor('navigateTo', { ... })
uni.addInterceptor('switchTab', { ... })

// ❌ 未拦截：
// uni.redirectTo — 页面间重定向
// uni.reLaunch  — 关闭所有页面跳转（虽然自身用来跳登录页，但外部调用未拦截）
```

**问题 2 — 仅检查 token 存在性**：

```ts
const token = uni.getStorageSync('access_token')
if (!token && !PUBLIC_PAGES.includes(path)) { ... }
```

只检查 token 是否存在，不检查有效性。如果 token 已过期但未被清除，用户可以绕过守卫进入页面（随后 API 请求才会触发 401 刷新）。

**问题 3 — 公开页面白名单硬编码**：

```ts
const PUBLIC_PAGES = ['/pages/auth/login', '/pages/auth/change-password']
```

直接写在 App.vue 内，而非统一在 `constants/` 管理。

**建议**：
- 补充 `redirectTo` 和 `reLaunch` 的拦截器
- 将 `PUBLIC_PAGES` 移入 `src/constants/` 统一管理
- 考虑在守卫中使用 `useAuthStore().isLoggedIn` 替代直接读 storage

---

### 4.4 🟡 API 层与导航逻辑耦合

**严重程度**：中  
**文件**：`src/api/client.ts`

**问题**：响应拦截器中直接执行页面导航：

```ts
// client.ts 第 128 行 — 数据层不应直接操作页面导航
uni.reLaunch({ url: '/pages/auth/login' })
```

这违反了**分层架构原则**：API 客户端属于数据访问层，不应包含 UI 跳转逻辑。

**Token 清理重复**：`clearTokens()` 在以下三处被调用：
1. `client.ts` 响应拦截器（401 时）
2. `api/modules/auth.ts` 的 `logout()` 中 `.finally(() => clearTokens())`
3. `stores/auth.ts` 的 `logout()` 中 `clearTokens()`

**建议**：
- API 层只负责抛出 `ApiError`，不做导航
- Store 层统一监听 `ApiError`，决定是否跳转登录页
- Token 清理统一收口到 `stores/auth.ts` 的 `logout()` 方法

---

### 4.5 🟡 多端主题注入代码复杂度高

**严重程度**：中  
**文件**：`src/stores/theme.ts`

**问题**：`#ifdef APP-PLUS` 条件编译块内约 120 行 JS 字符串拼接 + webview 遍历 + 延迟重试逻辑，集中在单个 Store 文件中，导致：
- 文件过长（250+ 行），关注点混杂
- 字符串拼接的 JS 代码无法获得 IDE 支持和类型检查
- 难以编写单元测试

**建议**：
```
src/
├── platform/
│   ├── theme-h5.ts        # H5 平台的 DOM 注入
│   ├── theme-app.ts       # App-plus 平台的 WebView 注入
│   └── theme-native.ts    # 原生容器背景色设置
└── stores/
    └── theme.ts           # 只保留状态管理逻辑，调用 platform/ 接口
```

通过条件编译 `import` 不同实现文件，单个文件职责更清晰。

---

### 4.6 🟡 缺少全局错误处理

**严重程度**：中  
**文件**：`src/main.ts`

**问题**：
- 未注册 Vue `app.config.errorHandler` — 未捕获的错误没有兜底处理
- 没有统一的用户错误提示工具（各页面自行 `uni.showToast` 或忽略）
- 无异常上报/监控接入

**建议**：
```ts
// main.ts
app.config.errorHandler = (err, instance, info) => {
  console.error('[Global Error]', err, info)
  // 接入 Sentry / 自建监控
}
```

封装统一的错误提示 composable：
```ts
// composables/useToast.ts
export function useToast() {
  function showError(message: string) { ... }
  function showSuccess(message: string) { ... }
  return { showError, showSuccess }
}
```

---

### 4.7 🟢 navigationIntent 使用模块级全局变量

**严重程度**：低  
**文件**：`src/utils/navigationIntent.ts`

**问题**：使用模块级 `let intendedTabPath` 做跨组件通信。虽然当前场景（单一 tab 切换意图）下可行，但：
- 不具备多实例安全性
- 状态不可追溯、不可调试

**建议**：如后续导航意图管理变复杂，可收入 Pinia Store 统一管理。当前阶段可暂不改动。

---

### 4.8 🟢 TabBar 图标 SVG 逻辑过度集中

**严重程度**：低  
**文件**：`src/constants/tabbar.ts`

**问题**：5 组 SVG 图标的渲染函数（`renderDashboardIcon`、`renderAssetsIcon` 等）全部写在 `tabbar.ts` 常量文件中，该文件已超过 200 行，且 SVG markup 占大部分。

**建议**：将 SVG 渲染函数拆到 `src/components/navigation/icons/` 下，`tabbar.ts` 只保留配置数据。

---

## 五、安全性评估

| 维度 | 状态 | 说明 |
|------|------|------|
| Token 存储 | ✅ 可接受 | `uni.setStorageSync` 在 H5 端等价于 localStorage，对 XSS 有暴露风险，但这是 uni-app 跨端标准做法 |
| Token 刷新 | ✅ 安全 | 刷新锁防并发、失败后清除 Token 并强制登出 |
| 路由守卫 | ⚠️ 部分覆盖 | 未拦截 `redirectTo`/`reLaunch`，详见 4.3 |
| Mock 数据 | ✅ 安全 | 受 `VITE_USE_MOCK` 环境变量控制，生产端需确保不误设为 `true` |
| API 路径 | ✅ 安全 | 集中管理，无硬编码 |
| 密码传输 | ✅ 安全 | 通过 POST body 传输，配合 HTTPS 即可保障 |
| XSS 防护 | ⚠️ 需关注 | 主题系统 `evalJS()` 注入存在间接 XSS 向量，但变量来源是代码硬编码的预设值，非用户输入，风险极低 |

---

## 六、软件工程规范符合度

| 规范 | 符合度 | 说明 |
|------|--------|------|
| 单一职责原则 (SRP) | ✅ 良好 | 各文件职责单一，但 theme store 略有膨胀 |
| 开闭原则 (OCP) | ✅ 良好 | Mock 系统、主题预设均可扩展无需修改框架 |
| 依赖倒置原则 (DIP) | ⚠️ 部分 | API 层直接依赖 UI 导航，应反转 |
| DRY 原则 | ⚠️ 部分 | Token 清理逻辑存在重复 |
| KISS 原则 | ✅ 良好 | 整体设计简洁，无过度抽象 |
| 关注点分离 | ✅ 良好 | 目录层次清晰 |
| 类型安全 | ✅ 优秀 | TypeScript strict + 完整领域类型 |
| 可测试性 | ❌ 缺失 | 无测试代码和工具链 |
| 代码规范 | ⚠️ 部分 | 风格一致但缺乏工具链保障 |
| 文档化 | ⚠️ 部分 | 关键代码有注释，但无 README 或 API 文档 |

---

## 七、评分总结

| 维度 | 评分 | 说明 |
|------|------|------|
| 目录结构 | ⭐⭐⭐⭐⭐ | 分层清晰，命名规范，符合主流 Vue 项目结构 |
| 类型安全 | ⭐⭐⭐⭐⭐ | strict 模式 + 完整的领域类型定义 |
| API 封装 | ⭐⭐⭐⭐⭐ | 统一出口、自动 Token 管理、Mock fallthrough |
| 主题系统 | ⭐⭐⭐⭐⭐ | 工程化程度极高，含自定义 lint 工具 |
| 组件设计 | ⭐⭐⭐⭐ | 基础组件完整，缺少复合业务组件（项目早期正常） |
| 状态管理 | ⭐⭐⭐⭐ | Composition API 风格 Store，但与 API 层职责有交叉 |
| 测试覆盖 | ⭐ | 完全缺失 |
| 代码规范 | ⭐⭐⭐ | 代码风格一致但缺少自动化工具链保障 |
| 安全性 | ⭐⭐⭐⭐ | Token 管理和路由守卫基本完备，有小改进空间 |
| 可维护性 | ⭐⭐⭐⭐ | 常量提取好，但多端条件编译代码复杂度高 |

**综合评价**：项目基建质量 **明显高于平均水平**，架构设计体现了对 uni-app 多端差异的深入理解和工程化思维。主要短板集中在 **测试体系缺失** 和 **代码规范工具链不完整**，建议在业务代码大量填充前尽快补齐。

---

## 八、优先改进路线图

```
Phase 1 — 工具链补齐（建议立即执行）
  ├── 引入 ESLint + Prettier
  ├── 配置 husky + lint-staged
  └── 引入 Vitest + @vue/test-utils

Phase 2 — 架构微调（建议近期执行）
  ├── API 层解耦导航逻辑
  ├── Token 清理收口到 Store
  ├── 补全路由拦截（redirectTo/reLaunch）
  └── 公开页面白名单移入 constants

Phase 3 — 可维护性优化（建议业务开发中渐进执行）
  ├── 主题平台适配代码拆分到 platform/
  ├── TabBar SVG 图标拆分到组件目录
  ├── 全局错误处理 + 统一 Toast
  └── 补充 README 和开发文档
```
