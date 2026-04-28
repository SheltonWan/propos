---
mode: agent
description: 创建 uni-app feature 模块的完整结构（types + api + mock + store + page + components）。Use when implementing any uni-app feature under app/src/.
---

# uni-app Feature 模块实现规范

@file:docs/backend/API_CONTRACT_v1.7.md
@file:.github/copilot-instructions.md
@file:app/src/constants/api_paths.ts
@file:app/src/api/client.ts
@file:app/src/api/index.ts
@file:app/src/App.vue
@file:app/src/pages.json

## 当前任务

{{TASK}}

## 目录约定

目标路径遵循 `app/src/` 下的扁平模块结构，必须包含：

```
types/                       ← TypeScript 接口定义（新增或扩展）
  <module>.ts

api/
  modules/<module>.ts        ← CRUD 函数，调用 apiGet/apiGetList/apiPost/apiPatch/apiDelete
  mock/<module>.ts           ← MockHandler[]，模拟接口响应
  index.ts                   ← 桶导出（追加新模块的 re-export）

constants/
  api_paths.ts               ← 追加 API 路径常量（命名导出）

stores/
  <module>.ts                ← Pinia setup 风格 store

pages/
  <module>/
    index.vue                ← 列表页（≤ 250 行）
    detail.vue               ← 详情页（≤ 250 行，视需要创建）

components/                  ← 超过 250 行时将子区域提取为独立组件
  <ModuleXxx>.vue
```

同步修改：
```
app/src/pages.json           ← 注册新页面路由
app/src/api/mock/index.ts    ← 注册新 mock handlers
app/src/api/index.ts         ← 桶导出新 api module
```

## 1. TypeScript 类型定义

在 `app/src/types/<module>.ts` 中定义接口：

```typescript
// ─── <Module> 类型定义 ────────────────────────────────────────────────────

/** <实体> 列表项 */
export interface Xxx {
  id: string
  // 字段名遵循 API_CONTRACT_v1.7.md 实际命名（PropOS 后端使用 snake_case）
  // 证件号 / 手机号字段添加注释：// 脱敏：仅返回后 4 位
}

/** 创建 / 更新请求体 */
export interface XxxRequest {
  // 只含可写字段
}

/** 筛选参数 */
export interface XxxListParams {
  page?: number
  pageSize?: number
  // 业务筛选字段
}
```

- 接口放 `types/`，**禁止**在 `api/modules/` 或 `stores/` 内定义业务接口
- 所有字段名与 `API_CONTRACT_v1.7.md` 保持一致，不得自创字段
- 日期字段类型为 `string`（ISO 8601），展示时用 `dayjs` 格式化

## 2. API 路径常量

在 `app/src/constants/api_paths.ts` 中按模块区块追加：

```typescript
// ─── <Module> ─────────────────────────────────────────────────────────────
export const XXX = '/api/xxx'
export const XXX_DETAIL = '/api/xxx/:id'  // 若路径含参数，用 :id 标注
```

- 所有路径字面量只在此文件定义，**禁止**在 `api/modules/` 或页面组件中硬编码路径字符串
- 带路径参数时函数内使用模板字符串替换：`` `${XXX}/${id}` ``

## 3. API 模块

在 `app/src/api/modules/<module>.ts` 中定义 CRUD 函数：

```typescript
import type { ApiListResponse } from '@/types/api'
import type { Xxx, XxxRequest, XxxListParams } from '@/types/<module>'
import { XXX } from '@/constants/api_paths'
import { apiDelete, apiGet, apiGetList, apiPatch, apiPost } from '../client'

// ─── <Module> API ─────────────────────────────────────────────────────────

/** 获取列表（分页） */
export function getXxxList(params?: XxxListParams) {
  return apiGetList<Xxx>(XXX, params as Record<string, unknown>)
}

/** 获取单条详情 */
export function getXxx(id: string) {
  return apiGet<Xxx>(`${XXX}/${id}`)
}

/** 创建 */
export function createXxx(data: XxxRequest) {
  return apiPost<Xxx>(XXX, data as Record<string, unknown>)
}

/** 更新 */
export function updateXxx(id: string, data: Partial<XxxRequest>) {
  return apiPatch<Xxx>(`${XXX}/${id}`, data as Record<string, unknown>)
}

/** 删除 */
export function deleteXxx(id: string) {
  return apiDelete(`${XXX}/${id}`)
}
```

- **禁止**在 store 或页面组件中直接调用 `uni.request` 或 `luch-request` 实例
- 函数命名：`getXxxList`（列表）/ `getXxx`（详情）/ `createXxx` / `updateXxx` / `deleteXxx`
- 在 `app/src/api/index.ts` 中添加桶导出：`export * from './modules/<module>'`

## 4. Mock 数据

在 `app/src/api/mock/<module>.ts` 中定义 `MockHandler[]`：

```typescript
import type { MockHandler } from '../client'
import { XXX } from '@/constants/api_paths'

/** <Module> Mock 数据 */
export const xxxMocks: MockHandler[] = [
  {
    method: 'GET',
    url: XXX,
    handler: () => ({
      delay: 400,
      data: {
        data: [
          /* 至少 3 条样本数据，字段与 API_CONTRACT 完全一致 */
        ],
        meta: { page: 1, pageSize: 20, total: 3 },
      },
    }),
  },
  {
    method: 'GET',
    url: `${XXX}/:id`,
    handler: () => ({
      delay: 300,
      data: {
        data: { /* 单条样本数据 */ },
      },
    }),
  },
]
```

- 在 `app/src/api/mock/index.ts` 的 `handlers` 数组中注册 `...xxxMocks`
- Mock 字段**必须**与 `API_CONTRACT_v1.7.md` 一致，不得自创字段
- `delay` 范围 200–800ms，模拟真实网络延迟

## 5. Pinia Store

在 `app/src/stores/<module>.ts` 中创建 setup 风格 store：

```typescript
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PaginationMeta } from '@/types/api'
import type { Xxx, XxxListParams } from '@/types/<module>'
import { getXxxList, getXxx, createXxx, updateXxx, deleteXxx } from '@/api'
import { ApiError } from '@/api/client'

/** <Module> store */
export const useXxxStore = defineStore('<module>', () => {
  // ── state ──────────────────────────────────────────────────────────────
  const list = ref<Xxx[]>([])
  const item = ref<Xxx | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const meta = ref<PaginationMeta | null>(null)

  // ── getters ────────────────────────────────────────────────────────────
  const total = computed(() => meta.value?.total ?? 0)

  // ── actions ────────────────────────────────────────────────────────────

  /** 获取列表 */
  async function fetchList(params?: XxxListParams) {
    loading.value = true
    error.value = null
    try {
      const res = await getXxxList(params)
      list.value = res.data
      meta.value = res.meta
    }
    catch (e) {
      error.value = e instanceof ApiError ? e.message : '操作失败，请重试'
    }
    finally {
      loading.value = false
    }
  }

  /** 获取详情 */
  async function fetchItem(id: string) {
    loading.value = true
    error.value = null
    try {
      item.value = await getXxx(id)
    }
    catch (e) {
      error.value = e instanceof ApiError ? e.message : '加载失败，请重试'
    }
    finally {
      loading.value = false
    }
  }

  return { list, item, loading, error, meta, total, fetchList, fetchItem }
})
```

- Store state 固定字段：**`list / item / loading / error / meta`**（缺少任何一个均需说明）
- 错误处理：**必须** `e instanceof ApiError ? e.message : '操作失败，请重试'`，不透传原始错误对象
- **禁止** options API 风格（`state()` / `getters` / `actions` 键）

## 6. 页面（Page）

### 列表页 `pages/<module>/index.vue`

```vue
<template>
  <page-meta ... />
  <AppShell with-tabbar>  <!-- 非 Tab 页去掉 with-tabbar -->
    <template #header>
      <PageHeader title="<模块名>" :sticky="true" :back="false" :animated="false" />
    </template>

    <view class="<module>">
      <!-- 加载态 -->
      <view v-if="store.loading && !store.list.length" class="<module>__loading">
        <wd-loading />
      </view>

      <!-- 错误态 -->
      <view v-else-if="store.error" class="<module>__error">
        <wd-icon name="warning" /><text>{{ store.error }}</text>
      </view>

      <!-- 列表 -->
      <view v-else class="<module>__list">
        <XxxCard
          v-for="item in store.list"
          :key="item.id"
          :item="item"
          @tap="navigateToDetail(item.id)"
        />
      </view>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useXxxStore } from '@/stores/<module>'

const store = useXxxStore()
const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

onMounted(() => store.fetchList())

function navigateToDetail(id: string) {
  uni.navigateTo({ url: `/pages/<module>/detail?id=${id}` })
}
</script>
```

- 状态渲染使用 `v-if / v-else-if / v-else` 控制三态（loading / error / data），**禁止**将状态逻辑写在 `<template>` 的复杂表达式中
- **禁止**在 `<script setup>` 内直接调用 API 函数，只通过 store action
- 页面文件 ≤ 250 行；超限时将卡片/列表项提取为 `components/<ModuleCard>.vue`

### 详情页 `pages/<module>/detail.vue`

- 通过 `onLoad` 钩子获取路由参数 `id`，调用 `store.fetchItem(id)`
- 展示 `store.item`，加载/错误态同列表页

## 7. 路由注册

在 `app/src/pages.json` 的 `pages` 数组中追加：

```json
{
  "path": "pages/<module>/index",
  "style": {
    "navigationBarTitleText": "<模块名>",
    "navigationStyle": "custom"
  }
},
{
  "path": "pages/<module>/detail",
  "style": {
    "navigationBarTitleText": "<模块名>详情",
    "navigationStyle": "custom"
  }
}
```

- 列表页若为 Tab 页面，还需在 `tabBar.list` 中配置，并确保 `iconPath` / `selectedIconPath` 对应文件**已存在**于 `static/tabbar/`
- **禁止**先写入不存在的图片路径；若需要 tabBar 图标，先生成 PNG 文件

## 8. 组件规则

- 子组件统一放 `app/src/components/`，文件名 `PascalCase.vue`
- `<template>` 嵌套超过 4 层或文件超 250 行时，必须拆分为独立组件
- **禁止**在 `<template>` 内写业务逻辑（计算逻辑提取到 `computed` 或 `composables/`）
- `<script setup lang="ts">` 是唯一允许的脚本形式

## 9. 颜色 / UI 规范

- 所有颜色**必须**使用 CSS 变量：

| 语义 | CSS 变量 |
|------|---------|
| 主色 | `var(--color-primary)` |
| 成功 / 已租 / 已付 | `var(--color-success)` |
| 预警 / 即将到期 | `var(--color-warning)` |
| 危险 / 空置 / 逾期 | `var(--color-danger)` |
| 中性 / 非可租 | `var(--color-neutral)` |

- wot-design-uni 组件状态通过 `type` prop：`success / warning / error / info`
- **禁止**内联 `style="color: #xxx"` / `rgba(...)` / `Colors.xxx`
- 提交前运行 `pnpm lint:theme` 确保无颜色硬编码

## 10. 日期处理

- 显示：`dayjs(isoString).format('YYYY-MM-DD')`（本地时区）
- **禁止**直接操作 `Date` 对象
- **禁止** `new Date()` 作为业务基准日期（业务计算由后端完成）

## 11. 条件编译

平台差异代码用 uni-app 条件编译包裹，**禁止** `navigator.userAgent` / `process.env.PLATFORM` 判断：

```vue
<!-- #ifdef APP-HARMONY -->
<HarmonyOnlyView />
<!-- #endif -->
```

```typescript
// #ifdef H5
console.log('H5 only')
// #endif
```

## 禁止事项（每条都必须检查）

- ❌ store 或页面内直接调用 `uni.request` 或 `luch-request` 实例
- ❌ API 路径字符串字面量硬编码（必须用 `@/constants/api_paths` 常量）
- ❌ `<template>` 内写业务逻辑（三目运算除外）
- ❌ 内联颜色（`style="color: #xxx"`、`rgba(...)`、组件 `color` 字面量）
- ❌ options API 风格 store（`state()` / `getters` / `actions` 键）
- ❌ 错误处理透传原始 `luch-request` 错误对象
- ❌ store 缺少固定字段 `list / item / loading / error / meta`
- ❌ 使用 `history.push` 或原生 `<a>` 导航（必须用 `uni.navigateTo` 等）
- ❌ 用 `navigator.userAgent` 判断平台差异（必须用条件编译指令）
- ❌ 在 `pages.json` tabBar 中引用不存在的图片路径
- ❌ 新 mock 未在 `api/mock/index.ts` 的 `handlers` 中注册
- ❌ 新 api 模块未在 `api/index.ts` 中桶导出
- ❌ 代码注释使用英文（所有注释统一用中文）
- ❌ 超前实现 Phase 2 功能（租户门户、门禁、电子签章等）
