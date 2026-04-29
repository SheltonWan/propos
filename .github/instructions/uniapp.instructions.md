---
applyTo: app/src/**
---

# uni-app 端编码规范（PropOS）

## API 层规则

- 所有 HTTP 请求**必须**通过 `app/src/api/client.ts` 导出的辅助函数：
  `apiGet` / `apiGetList` / `apiPost` / `apiPatch` / `apiDelete`
- 禁止在 store 或 component 内直接调用 `uni.request` 或 `luch-request` 实例
- API 路径**必须**从 `@/constants/api_paths.ts` 导入，禁止字符串字面量硬编码
- API 函数放在 `app/src/api/modules/<domain>.ts`，通过 `app/src/api/index.ts` 桶导出

## Mock 数据层规则

通过 `.env.development` 中 `VITE_USE_MOCK=true/false` 控制。mock 拦截在 `api/client.ts` 导出层完成，**store 和页面代码无需任何改动**。

- **新增 API 模块时必须同步创建对应 mock**：`api/modules/xxx.ts` → `api/mock/xxx.ts`
- Mock 文件导出 `xxxMocks: MockHandler[]`，在 `api/mock/index.ts` 的 `handlers` 数组中注册
- 每个 `MockHandler` 必须包含 `method`、`url`（引用 `@/constants/api_paths` 常量）、`handler` 函数
- `handler` 返回 `MockResult`：`{ delay: number, data?, error? }`，delay 模拟网络延迟（200-800ms）
- 错误 mock 使用 `error: { code, message, status }` 格式，由 `matchMock` 自动转为 `ApiError` 抛出
- 未匹配的 URL 自动 fallthrough 到真实 HTTP，支持部分 mock + 部分真实混合
- mock 模块通过动态 `import()` 懒加载，`VITE_USE_MOCK=false` 时零加载、零打包

## Store 规则（Pinia setup 风格）

```typescript
// 必须使用 setup 风格，禁止 options 风格
export const useXxxStore = defineStore('xxx', () => {
  // state = ref
  const list = ref<Xxx[]>([])
  const item = ref<Xxx | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const meta = ref<PaginationMeta | null>(null)

  // getters = computed
  const total = computed(() => meta.value?.total ?? 0)

  // actions = async 函数
  async function fetchList(params: ListParams) {
    loading.value = true
    error.value = null
    try {
      const res = await apiGetList<Xxx>(API_XXX, params)
      list.value = res.data
      meta.value = res.meta
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '操作失败，请重试'
    } finally {
      loading.value = false
    }
  }

  return { list, item, loading, error, meta, total, fetchList }
})
```

- Store state 固定字段：`list / item / loading / error / meta`
- 错误处理：`catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }`
- 不透传原始 `luch-request` 错误对象

## Page / Component 规则

- Page 和 Component **只**通过 store 的 state/action 获取数据，禁止内联 HTTP 请求
- 禁止在 `<template>` 里写业务逻辑（三目运算除外）；复杂逻辑提取到 `computed` 或 `composables/`
- 每个 Page 文件 ≤ 250 行；超限则将子区域提取到 `components/` 下独立组件
- `<script setup lang="ts">` 是唯一允许的脚本形式

## 路由规则

- 所有页面必须在 `app/src/pages.json` 中注册，否则无法被 uni-app 识别
- 导航使用 `uni.navigateTo` / `uni.redirectTo` / `uni.reLaunch` / `uni.switchTab`，禁用原生 `<a>` 或 `history.push`
- 路由守卫通过 `uni.addInterceptor` 在 `App.vue` 中全局注册
- 公开页面路径在 `App.vue` 的 `PUBLIC_PAGES` 数组中声明，其余页面需要 JWT token

## 条件编译

平台差异代码必须用 uni-app 条件编译指令包裹，禁止 `process.env` 或 `navigator.userAgent` 判断：

```vue
<!-- 模板中 -->
<!-- #ifdef APP-HARMONY -->
<HarmonyOnlyComponent />
<!-- #endif -->

<!-- #ifdef MP-WEIXIN -->
<WechatOnlyComponent />
<!-- #endif -->
```

```typescript
// 脚本中
// #ifdef H5
console.log('H5 only')
// #endif
```

## 日期处理

- 必须使用 `dayjs`，禁止直接操作 `Date` 对象
- 显示：`dayjs(isoString).format('YYYY-MM-DD')`（本地时区）
- 业务计算（WALE、逾期天数）在后端完成，前端不做日期业务计算
- 禁止用 `new Date()` 获取当前时间作为业务基准

## 颜色 / UI 规范

- 使用 CSS 变量，禁止内联 `style="color: green"` 或 `style="color: red"`：
  - 成功/已租/已付：`var(--color-success)`
  - 预警/即将到期：`var(--color-warning)`
  - 危险/空置/逾期：`var(--color-danger)`
  - 中性/非可租：`var(--color-neutral)`
  - 主色：`var(--color-primary)`
- wot-design-uni 组件状态通过 `type` prop 传递：`success / warning / error / info`
- app 目录已提供强制校验：提交前运行 `pnpm lint:theme`，页面/业务组件内出现十六进制颜色、数值 `rgba(...)`、硬编码 `font-family`、组件 `color` 字面量会直接失败；主题定义仅允许放在 `src/constants/theme.ts`、`src/styles/tokens.scss` 与 `src/uni.scss`

### 深色背景 token 选用规则（易混淆，必须遵守）

项目中存在两个外观相似但语义不同的深色背景 token，**选错会导致切换主题时卡片背景与品牌色脱节**（如 Apple Blue 主题下呈近纯黑而非深海蓝）：

| Token | SCSS 变量 | 使用场景 |
|-------|-----------|---------|
| `--color-card-dark` | `$color-card-dark` | **品牌深色面板**：Dashboard Header、资产总览卡、任何使用 `AppCard variant="dark"` 的大卡片。该值在 Apple Blue 主题下为 `#001d3d`（深海蓝），随主题正确变色 |
| `--color-background-dark` | `$color-background-dark` | **系统级深色底层**：dark 模式下的页面基础背景层、`PageHeader` 非品牌变体的背景。Apple Blue 主题下为 `#1c1c1e`（近纯黑） |

**判断口诀**：写的是"有品牌感的深色卡片/面板" → 用 `$color-card-dark`；写的是"系统级深色底色/暗模式底层" → 用 `$color-background-dark`。

`AppCard variant="dark"` 的 `.app-card--dark` 规则**必须**使用 `$color-card-dark`，禁止使用 `$color-background-dark`。

## 常量规则

| 类型 | 文件 |
|------|------|
| API 路径 | `@/constants/api_paths.ts` |
| 业务阈值 | `@/constants/business_rules.ts` |
| UI 常量 | `@/constants/ui_constants.ts` |

禁止在业务代码中出现魔法数字（如直接写 `30`、`90` 天）或字符串路径（如直接写 `'/api/contracts'`）。

## TypeScript 规则

- `strict: true` 模式；所有接口定义放 `src/types/`
- API 响应类型必须使用 `ApiResponse<T>` 或 `ApiListResponse<T>` 信封类型
- 禁用 `any`；使用 `unknown` 后做类型收窄

## 页面复刻规则（核心规则）

**唯一事实源**：每个 uni-app 页面必须以 `frontend/src/app/pages/` 下对应的 React 页面作为唯一参照。生成或修改页面前，**必须先读取对应 React 源文件**，理解其布局、交互、数据结构和状态管理，再进行 uni-app 适配。

**设计基线**：严格遵循 Apple Blue 主题（`frontend/design/DESIGN-apple.md`）：
- 主色 `#0071e3`，唯一色彩着色点，仅用于交互元素
- 背景节奏：`#ffffff`（卡片）与 `#f5f5f7`（页面底色）交替
- 文字色：`#1d1d1f`（主文字）、`rgba(0,0,0,0.48)`（辅助文字）
- 标题紧凑行高（1.07–1.14）、正文舒适行高（1.47）
- 圆角：卡片 `$radius-card`（40rpx）、控件 `$radius-control`（24rpx）
- 阴影：仅用于分层，不用于装饰

**适配规范文档**：页面结构、组件映射、弹层策略、样式迁移等遵循 `frontend/docs/prototype/` 下的完整文档集：
- `prototype-spec.md` — 路由、导航、角色可见性
- `uni-app-adaptation.md` — 路由映射、状态管理、组件替代
- `theme-spec.md` — 语义 token、间距、圆角、阴影
- `component-catalog.md` — 组件体系、卡片/列表/弹层模式
- `uni-app-scaffold.md` — AppShell/PageHeader/AppCard/BottomSheet 骨架
- `data-contracts.md` — 数据字段契约

**React → uni-app 页面映射**：

| React 页面 | uni-app 页面 |
|------------|-------------|
| `Home.tsx` | `pages/dashboard/index.vue` |
| `Assets.tsx` | `pages/assets/index.vue` |
| `BuildingFloors.tsx` | `pages/assets/floors.vue` |
| `FloorPlan.tsx` | `pages/assets/floor-plan.vue` |
| `UnitDetail.tsx` | `pages/assets/unit-detail.vue` |
| `Contracts.tsx` | `pages/contracts/index.vue` |
| `ContractDetail.tsx` | `pages/contracts/detail.vue` |
| `WorkOrders.tsx` | `pages/workorders/index.vue` |
| `WorkOrderDetail.tsx` | `pages/workorders/detail.vue` |
| `WorkOrderForm.tsx` | `pages/workorders/form.vue` |
| `Finance.tsx` | `pages/finance/index.vue` |
| `Invoices.tsx` | `pages/finance/invoices.vue` |
| `InvoiceDetail.tsx` | `pages/finance/invoice-detail.vue` |
| `KPIDashboard.tsx` | `pages/finance/kpi.vue` |
| `NOIDashboard.tsx` | `pages/dashboard/noi-detail.vue` |
| `Login.tsx` | `pages/auth/login.vue` |
| `Profile.tsx` | `pages/profile/index.vue` |
| `Notifications.tsx` | `pages/notifications/index.vue` |
| `ChangePassword.tsx` | `pages/auth/change-password.vue` |

**图标映射策略**（React 原型使用 `lucide-react`，uni-app 端按以下三级降级处理）：

1. **优先匹配 wot-design-uni 内置图标** — lucide 图标名在 wot-design-uni 有同名或等价图标时，直接用 `<wd-icon name="xxx">`
2. **近似替代** — 无精确对应时，选择语义或形态最接近的 wot-design-uni 图标（如 lucide `Lock` → `wd-icon name="lock-on"`，lucide `AlertCircle` → `wd-icon name="warning"`）
3. **自制 SVG 兜底** — wot-design-uni 完全没有对应图标时，从 [lucide.dev](https://lucide.dev) 导出原始 SVG，存放到 `app/src/static/icons/` 下，用 `<image>` 渲染

自制 SVG 规范：
- **命名**：`kebab-case`，与 lucide 原始名一致，如 `building-2.svg`、`bar-chart-3.svg`
- **颜色**：深色背景容器内 → `stroke="#ffffff"`；浅色背景 / 需跟随主题 → `stroke="currentColor"`
- **尺寸**：保持 `viewBox="0 0 24 24"`，由外层容器控制实际显示尺寸
- **属性**：保留 `fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"`

禁止事项：
- 禁止使用 Unicode 字符或中文文字模拟图标
- 禁止在 `<template>` 中内联 SVG 代码，必须走 `<image src>` 引用文件
- 禁止自创图标造型，必须基于 lucide 原型的 SVG path data

**tabBar 图标生成规则**：
- 修改 `app/src/pages.json` 的 `tabBar.list` 图标前，必须先校验 `iconPath` / `selectedIconPath` 对应文件是否已存在；**禁止**先写入不存在的图片路径
- 当前项目 tabBar 图标的唯一事实源是 `frontend/src/app/components/BottomTabBar.tsx`；若 `app/src/static/tabbar/` 下缺少目标 PNG，优先从该文件引用的 `lucide-react` 图标生成，而不是手工猜测或临时找替代图
- 生成 tabBar 图标时，默认输出两张透明背景 PNG：未选中态使用 `#717182`，选中态使用 `#0071e3`，与 `pages.json` 中 `tabBar.color` / `tabBar.selectedColor` 保持一致
- 默认使用 `81x81` 画布导出 PNG，命名与 `pages.json` 引用保持一致，例如 `dashboard.png` 与 `dashboard-active.png`；如无明确要求，不要改动现有命名方案
- 生成或替换 tabBar 图标后，必须逐项校验 `app/src/pages.json` 中 `tabBar.list[*].iconPath` 和 `selectedIconPath` 是否全部命中实际文件，再结束任务

**复刻检查清单**（每个页面必须满足）：
1. 卡片结构、字段顺序与 React 原型一致
2. 状态 Badge 颜色语义 与 theme-spec 一致
3. 间距（page-x 40rpx、card 32rpx）、圆角、阴影使用 token 而非硬编码
4. 列表页包含搜索/筛选/空态/加载态/错误态五种状态
5. 详情页信息分组与 React 卡片层级一致
6. 表单页验证规则与 React 一致
7. 弹层使用 BottomSheet，不使用 Dialog（除确认框外）
8. 不复制 Web 手机壳、Portal 容器、Showcase 模式
9. 图标按三级降级策略处理，自制 SVG 放 `static/icons/` 并遵循命名/颜色规范

**居中布局补充规则**：
- 在 `display: flex` 且 `flex-direction: column`、`align-items: center` 的父容器里，若某个子组件需要“视觉居中”的独立入口、胶囊按钮、浮层触发器或状态条，**禁止**同时给子组件根节点和其主容器设置 `width: 100%`
- 这类组件默认使用“居中容器 + 收缩内容”模式：外层负责 `justify-content: center`，内层使用 `width: auto` / `display: inline-flex`，必要时配合 `max-width` 或 `min-width`
- 只有原型明确要求通栏时，才允许使用全宽；否则全宽子节点会抵消父容器的水平居中效果
- 登录页、空态页、成功页这类单列场景里的附属入口（如主题切换、调试入口、二级操作）默认视为独立入口，不应与主卡片机械同宽

**页面背景补充规则**：
- 需要覆盖安全区的页面级背景，必须通过 `AppShell` 注入，不要只写在页面内部容器上；否则顶部或底部安全区会露出 Shell 默认底色
- `AppShell` 负责页面底层背景与安全区连续性，页面内部第一层布局容器默认保持透明，只负责排版和对齐
- 登录页、欢迎页、品牌化落地页、深色看板页等存在整页渐变或整页底色时，优先使用 `AppShell` 的背景注入能力，而不是在中间容器重新铺底
- 当 `scroll=false` 时，也必须保留由 `AppShell` 托管的底部安全区渲染，不能因为走静态分支就丢掉 `safeBottom`
- 仅靠容器背景不足以覆盖 iPhone home indicator 等视口边缘区域时，必须由 `AppShell` 提供固定定位的 viewport background layer，确保底部安全区与上层背景连续

**TabBar 主题补充规则**：
- 面向运行时主题的项目，`pages.json` 中的 `tabBar` 只保留 tab 页声明与 `switchTab` 路由能力；视觉层必须落在自定义 `AppTabBar`，不要继续依赖原生 tabBar 换肤
- tabBar 图标资源优先使用矢量资源并在运行时按主题 token 生成或着色，避免维护多套不可着色的 PNG 资源
- 自定义 tabBar 必须自己处理底部安全区、激活态图标/文案、点击切页以及与 `AppShell` 内容区的占位关系，不能只渲染面板本体而忽略底部 inset

**动效节奏补充规则**：
- `AppTabBar`、`PageHeader`、`AppCard` 的尺寸、位移幅度、时长与 easing 必须复用同一套 UI 常量，不要在各组件里散落不同的 160ms/220ms/260ms 组合
- 页面级节奏遵循“header 先进入，card 再以轻微 stagger 跟进”的顺序；新增卡片型区块优先通过 `motionIndex` 做层次递进，而不是各写一套 keyframes
- 暗色主题下的浮层和底部导航阴影要主动收敛，避免直接沿用浅色主题的高扩散阴影导致界面发灰发脏
- 一级 tab 根页面的切换必须保持稳定直接，不要给 `PageHeader` 或首屏卡片加 mount 入场动画；tab 间切换优先保证定位感，入场节奏留给非 tab 页面或页内新出现区块
- 自定义 `AppTabBar` 本身也不得做“每页实例首次挂载”的入场动画；因为 tab 页通常各自持有一个 tabbar 实例，这类动画会在第一次切到某个 tab 时制造额外闪跃
