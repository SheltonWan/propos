---
applyTo: admin/src/**
---

# Vue3 PC Admin 编码规范（PropOS）

## API 层规则

- 所有 HTTP 请求**必须**通过 `admin/src/api/client.ts` 导出的辅助函数：
  `apiGet` / `apiGetList` / `apiPost` / `apiPatch` / `apiDelete`
- 禁止在 store 或 component 内直接调用 `axios` 实例或 `fetch`
- API 路径**必须**从 `@/constants/api_paths.ts` 导入，禁止字符串字面量硬编码
- API 函数放在 `admin/src/api/modules/<domain>.ts`，通过 `admin/src/api/index.ts` 桶导出

## Store 规则（Pinia setup 风格）

```typescript
// 必须使用 setup 风格，禁止 options 风格
export const useXxxStore = defineStore('xxx', () => {
  const list = ref<Xxx[]>([])
  const item = ref<Xxx | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const meta = ref<PaginationMeta | null>(null)

  const total = computed(() => meta.value?.total ?? 0)

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
- 不透传原始 `AxiosError`

## 路由规则

- 路由定义在 `admin/src/router/index.ts`，使用 `createWebHistory`
- 全局导航守卫在 `router.beforeEach` 中检查 `localStorage.getItem('access_token')`
- 公开路由必须设置 `meta: { public: true }`；其余路由未登录时重定向到 `/login`
- 懒加载所有视图：`component: () => import('@/views/xxx/XxxView.vue')`

## View / Component 规则

- View 和 Component **只**通过 store 的 state/action 获取数据，禁止内联 HTTP 请求
- 禁止在 `<template>` 里写业务逻辑；复杂逻辑抽到 `computed` 或 `composables/`
- View 文件 ≤ 250 行；超限则将子区域提取到 `components/` 下独立组件
- `<script setup lang="ts">` 是唯一允许的脚本形式

## Element Plus 使用规则

- Element Plus 组件**自动按需导入**（由 `unplugin-vue-components` + `ElementPlusResolver` 处理），**禁止手动 import**
- 同理 Element Plus Icons 已在 `main.ts` 全局注册，直接使用 `<el-icon><ComponentName /></el-icon>`
- 状态 Tag 必须通过 `type` prop 声明语义色，禁止自定义 `style` 覆盖颜色：

| 状态 | `type` 值 | 含义 |
|------|-----------|------|
| `leased` / `paid` | `success` | 已租 / 已核销 |
| `expiring_soon` / `warning` | `warning` | 即将到期 / 预警 |
| `vacant` / `overdue` / `error` | `danger` | 空置 / 逾期 / 错误 |
| `non_leasable` | `info` | 非可租区域 |

## 日期处理

- 必须使用 `dayjs`，禁止直接操作 `Date` 对象
- 显示：`dayjs(isoString).format('YYYY-MM-DD')`（本地时区）
- 业务计算（WALE、逾期天数）在后端完成，前端不做日期业务计算

## Token 存储

- `access_token` 和 `refresh_token` 统一存储在 `localStorage`（key 名不得更改）
- 登出时必须同时删除两个 key，并调用 `router.replace('/login')`

## 常量规则

| 类型 | 文件 |
|------|------|
| API 路径 | `@/constants/api_paths.ts` |
| 业务阈值 | `@/constants/business_rules.ts` |
| UI 常量 | `@/constants/ui_constants.ts` |

禁止在业务代码中出现魔法数字或字符串路径。

## TypeScript 规则

- `strict: true` 模式；所有接口定义放 `src/types/`
- API 响应类型必须使用 `ApiResponse<T>` 或 `ApiListResponse<T>` 信封类型
- 禁用 `any`；使用 `unknown` 后做类型收窄

## 构建说明

- 开发：`npm run dev`（port 5173，自动代理 `/api` 到后端）
- 构建：`npm run build`（vue-tsc 类型检查 + vite build）
- 构建产物：`admin/dist/`（已加入 .gitignore）
