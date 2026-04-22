---
mode: agent
description: 创建 Vue3 PC Admin feature 模块的完整结构（types + api + store + view + components + router）。Use when implementing any admin feature under admin/src/.
---

# Vue3 PC Admin Feature 模块实现规范

@file:docs/backend/API_CONTRACT_v1.7.md
@file:.github/copilot-instructions.md
@file:admin/src/constants/api_paths.ts
@file:admin/src/api/client.ts
@file:admin/src/router/index.ts
@file:admin/src/stores/auth.ts
@file:admin/src/types/api.ts

## 当前任务

{{TASK}}

## 目录约定

目标路径遵循 `admin/src/` 下的模块结构，必须包含：

```
types/
  <module>.ts              ← TypeScript 接口定义（新增或扩展）

api/
  modules/<module>.ts      ← CRUD 函数，调用 apiGet/apiGetList/apiPost/apiPatch/apiDelete
  index.ts                 ← 桶导出（追加新模块的 re-export）

constants/
  api_paths.ts             ← 追加 API 路径常量（命名导出，前缀 API_）

stores/
  <module>.ts              ← Pinia setup 风格 store

views/
  <module>/
    <Module>View.vue       ← 列表/主视图（≤ 250 行）
    <Module>DetailView.vue ← 详情视图（≤ 250 行，视需要创建）

components/                ← 超过 250 行时提取子区域为独立组件
  <ModuleXxx>.vue
```

同步修改：
```
admin/src/router/index.ts  ← 注册新路由（懒加载）
admin/src/api/index.ts     ← 桶导出新 api module（如文件已存在）
```

## 1. TypeScript 类型定义

在 `admin/src/types/<module>.ts` 中定义接口：

```typescript
import type { PaginationMeta } from './api'

// ─── <Module> 类型定义 ─────────────────────────────────────────────────────

/** <实体> 列表项 */
export interface Xxx {
  id: string
  // 字段名 camelCase，与 API_CONTRACT 一致
  // 证件号 / 手机号字段添加注释：// 脱敏：仅返回后 4 位
  createdAt: string   // ISO 8601，展示时用 dayjs 格式化
  updatedAt: string
}

/** 创建 / 更新请求体 */
export interface XxxRequest {
  // 只含可写字段，不含 id/createdAt/updatedAt
}

/** 列表筛选参数 */
export interface XxxListParams {
  page?: number
  pageSize?: number
  // 业务筛选字段（与后端查询参数一致）
}
```

- 接口放 `types/`，**禁止**在 `api/modules/` 或 `stores/` 内定义业务接口
- 所有字段名与 `API_CONTRACT_v1.7.md` 保持一致，不得自创字段
- 禁用 `any`；使用 `unknown` 后做类型收窄

## 2. API 路径常量

在 `admin/src/constants/api_paths.ts` 中按模块区块追加：

```typescript
// ─── <Module> ─────────────────────────────────────────────────────────────
export const API_XXX = '/api/xxx'
// 带路径参数的接口在函数内用模板字符串拼接：`${API_XXX}/${id}`
```

- 常量名前缀统一 `API_`，全大写 SCREAMING_SNAKE_CASE
- 路径定义遵循 `API_CONTRACT_v1.7.md` 中的端点路径，不得自行设计

## 3. API 模块

在 `admin/src/api/modules/<module>.ts` 中定义 CRUD 函数：

```typescript
import type { ApiListResponse } from '@/types/api'
import type { Xxx, XxxRequest, XxxListParams } from '@/types/<module>'
import { API_XXX } from '@/constants/api_paths'
import { apiDelete, apiGet, apiGetList, apiPatch, apiPost } from '../client'

// ─── <Module> API ──────────────────────────────────────────────────────────

/** 获取列表（分页） */
export function getXxxList(params?: XxxListParams): Promise<ApiListResponse<Xxx>> {
  return apiGetList<Xxx>(API_XXX, params as Record<string, unknown>)
}

/** 获取单条详情 */
export function getXxx(id: string): Promise<Xxx> {
  return apiGet<Xxx>(`${API_XXX}/${id}`)
}

/** 创建 */
export function createXxx(data: XxxRequest): Promise<Xxx> {
  return apiPost<Xxx>(API_XXX, data as Record<string, unknown>)
}

/** 更新 */
export function updateXxx(id: string, data: Partial<XxxRequest>): Promise<Xxx> {
  return apiPatch<Xxx>(`${API_XXX}/${id}`, data as Record<string, unknown>)
}

/** 删除 */
export function deleteXxx(id: string): Promise<void> {
  return apiDelete(`${API_XXX}/${id}`)
}
```

- **禁止**在 store 或 view 内直接调用 `axios` 实例或 `fetch`
- 函数命名：`getXxxList`（列表）/ `getXxx`（详情）/ `createXxx` / `updateXxx` / `deleteXxx`
- 在 `admin/src/api/index.ts`（若存在）中追加：`export * from './modules/<module>'`

## 4. Pinia Store

在 `admin/src/stores/<module>.ts` 中创建 setup 风格 store：

```typescript
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PaginationMeta } from '@/types/api'
import { ApiError } from '@/types/api'
import type { Xxx, XxxListParams } from '@/types/<module>'
import { getXxxList, getXxx, createXxx, updateXxx, deleteXxx } from '@/api/modules/<module>'
import { DEFAULT_PAGE_SIZE } from '@/constants/ui_constants'

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
      const res = await getXxxList({ pageSize: DEFAULT_PAGE_SIZE, ...params })
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

- Store state **固定字段**：`list / item / loading / error / meta`（缺少任何一个均需说明）
- 错误处理：**必须** `e instanceof ApiError ? e.message : '操作失败，请重试'`，不透传原始 `AxiosError`
- **禁止** options API 风格（`state()` / `getters` / `actions` 键）
- 分页大小使用 `DEFAULT_PAGE_SIZE`（来自 `@/constants/ui_constants`），禁止硬编码 `20`

## 5. View（视图）

### 列表视图 `views/<module>/<Module>View.vue`

```vue
<template>
  <div class="<module>-view">
    <!-- 页头：标题 + 操作按钮 -->
    <div class="<module>-view__header">
      <h2>模块名称</h2>
      <el-button type="primary" @click="handleCreate">新建</el-button>
    </div>

    <!-- 筛选区 -->
    <el-card class="<module>-view__filter" shadow="never">
      <!-- el-form + el-form-item 筛选项 -->
    </el-card>

    <!-- 错误提示 -->
    <el-alert v-if="store.error" :title="store.error" type="error" show-icon />

    <!-- 数据表格 -->
    <el-table
      v-loading="store.loading"
      :data="store.list"
      row-key="id"
      border
    >
      <!-- el-table-column 列定义 -->
      <!-- 状态列使用 el-tag :type 语义色（见规范表） -->
    </el-table>

    <!-- 分页 -->
    <el-pagination
      v-if="store.meta"
      :current-page="store.meta.page"
      :page-size="store.meta.pageSize"
      :total="store.total"
      layout="total, prev, pager, next"
      @current-change="(page) => store.fetchList({ page })"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useXxxStore } from '@/stores/<module>'

const router = useRouter()
const store = useXxxStore()

onMounted(() => store.fetchList())

function handleCreate() {
  router.push('/<module>/new')
}
</script>
```

- View 文件 ≤ 250 行；超限时将筛选区 / 表格列 / 操作弹窗提取到 `components/` 下独立组件
- **禁止**在 `<script setup>` 内直接调用 API 函数，只通过 store action
- **禁止**在 `<template>` 内写业务逻辑；复杂逻辑抽到 `computed` 或 `composables/`
- `<script setup lang="ts">` 是唯一允许的脚本形式

### 详情视图 `views/<module>/<Module>DetailView.vue`

- 通过 `useRoute().params.id` 获取路由参数，`onMounted` 调用 `store.fetchItem(id)`
- 表单编辑使用 `el-form` + `el-form-item`，`ref` 存储表单数据（响应式副本）
- 提交调用 store 中的 `createXxx` / `updateXxx` action

## 6. Element Plus 使用规则

Element Plus 组件**自动按需导入**，**禁止手动 import**。

### 状态 Tag 语义色（必须通过 `type` prop，禁止 `style` 覆盖）

| 状态 | `type` 值 | 含义 |
|------|----------|------|
| `leased` / `paid` / `active` | `success` | 已租 / 已核销 / 启用 |
| `expiring_soon` / `warning` / `pending` | `warning` | 即将到期 / 预警 / 待处理 |
| `vacant` / `overdue` / `error` / `rejected` | `danger` | 空置 / 逾期 / 错误 / 已拒绝 |
| `non_leasable` / `inactive` / `cancelled` | `info` | 非可租区域 / 停用 / 已取消 |

### 常用组件要点

- 加载态：`v-loading="store.loading"`（`el-table` 内置属性，不要单独包裹 `el-loading`）
- 错误态：`<el-alert :title="store.error" type="error" show-icon />`（仅 `store.error` 非 null 时渲染）
- 分页：`<el-pagination>` 放在表格下方，`@current-change` 调用 store `fetchList({ page })`
- 表单验证：通过 `el-form` 的 `:rules` prop + `formRef.validate()` 校验，不做内联 `if/else` 校验

## 7. 路由注册

在 `admin/src/router/index.ts` 的布局路由 `children` 数组中追加，**必须使用懒加载**：

```typescript
{
  path: '<module>',
  name: '<module>-list',
  component: () => import('@/views/<module>/<Module>View.vue'),
},
{
  path: '<module>/:id',
  name: '<module>-detail',
  component: () => import('@/views/<module>/<Module>DetailView.vue'),
},
```

- 公开路由（无需登录）设置 `meta: { public: true }`
- 全局导航守卫在 `router.beforeEach` 中检查 `localStorage.getItem('access_token')`，无 token 且非公开路由时 `next('/login')`

## 8. 日期处理

- 显示：`dayjs(isoString).format('YYYY-MM-DD')`（本地时区）
- **禁止**直接操作 `Date` 对象
- 表格列日期：`<template #default="{ row }">{{ dayjs(row.createdAt).format('YYYY-MM-DD') }}</template>`
- 业务计算（WALE、逾期天数）在后端完成，前端不做日期业务计算

## 9. 常量规则

| 类型 | 文件 | 示例 |
|------|------|------|
| API 路径 | `@/constants/api_paths.ts` | `API_XXX` |
| 业务阈值 | `@/constants/business_rules.ts` | `EXPIRY_WARN_DAYS` |
| UI 常量 | `@/constants/ui_constants.ts` | `DEFAULT_PAGE_SIZE` |

禁止在业务代码中出现魔法数字或字符串路径。

## 禁止事项（每条都必须检查）

- ❌ store 或 view 内直接调用 `axios` 实例或 `fetch`
- ❌ API 路径字符串字面量硬编码（必须用 `@/constants/api_paths.ts` 常量）
- ❌ `<template>` 内写业务逻辑（三目运算除外）
- ❌ 手动 import Element Plus 组件（自动按需导入，手动 import 会重复注册）
- ❌ 状态 Tag 用 `style` 覆盖颜色（必须通过 `type` prop 声明语义色）
- ❌ options API 风格 store（`state()` / `getters` / `actions` 键）
- ❌ 错误处理透传原始 `AxiosError`（必须 `e instanceof ApiError ? e.message : '...'`）
- ❌ store 缺少固定字段 `list / item / loading / error / meta`
- ❌ 路由使用非懒加载方式（`component: XxxView` 代替 `() => import(...)`）
- ❌ 使用 `any` 类型（使用 `unknown` 后收窄）
- ❌ 日期直接操作 `Date` 对象（必须用 `dayjs`）
- ❌ 在业务代码中硬编码分页大小 `20`（必须用 `DEFAULT_PAGE_SIZE`）
- ❌ 超前实现 Phase 2 功能（租户门户、门禁、电子签章等）
- ❌ 代码注释使用英文（所有注释统一用中文）
