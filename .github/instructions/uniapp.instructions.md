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
