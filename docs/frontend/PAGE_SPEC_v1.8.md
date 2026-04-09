# PropOS 前端页面规格说明书

| 元信息 | 值 |
|--------|------|
| 版本 | v1.8 |
| 日期 | 2026-04-12 |
| 依据 | PRD v1.8 · ARCH v1.4 · API_CONTRACT v1.7 |
| 设计体系 | uni-app: `wot-design-uni` + CSS 变量 / Admin: Element Plus + 内置主题 |
| 路由方案 | uni-app: `pages.json` + `uni.navigateTo` / Admin: Vue Router 4 `createWebHistory` |
| 状态管理 | Pinia（`defineStore(id, setup)` 风格） |

> 本文档替代原 PAGE_SPEC_v1.7（Flutter/Material 3 版本）。技术栈已全面迁移至 **uni-app 4.x**（移动端 + 小程序）+ **Vue 3 + Element Plus**（PC Admin），所有 BLoC → Pinia Store、Widget Tree → Vue 组件树、Material Token → CSS 变量 / Element Plus type。

---

## 目录

1. [全局导航与路由结构](#一全局导航与路由结构)
2. [通用组件规范](#二通用组件规范)
3. [认证模块页面](#三认证模块页面)
4. [概览 Dashboard 模块](#四概览-dashboard-模块)
5. [资产模块页面](#五资产模块页面)
6. [租务与合同模块页面](#六租务与合同模块页面)
7. [财务模块页面](#七财务模块页面)
8. [工单模块页面](#八工单模块页面)
9. [二房东门户模块页面](#九二房东门户模块页面)
10. [系统设置模块页面](#十系统设置模块页面)
11. [响应式断点与布局策略](#十一响应式断点与布局策略)
12. [状态色语义映射速查](#十二状态色语义映射速查)
13. [附录 A：页面清单与模块映射](#附录-a页面清单与模块映射)
14. [附录 B：Pinia Store 清单](#附录-bpinia-store-清单)

---

## 一、全局导航与路由结构

### 1.1 双端架构概览

PropOS 前端分为两个独立项目，共享后端 API 但各自维护路由与 UI 体系：

| 端 | 项目目录 | 技术栈 | 导航形式 | 目标用户 |
|----|---------|--------|---------|---------|
| **uni-app 移动端** | `app/` | Vue 3 + TS + Pinia + wot-design-uni | TabBar 5 Tab + `uni.navigateTo` | 内部运营人员（移动办公）|
| **Admin PC 端** | `admin/` | Vue 3 + TS + Pinia + Element Plus | ElMenu 侧边栏 + Vue Router 4 | 管理层 / 专员（PC 操作）|

### 1.2 uni-app 导航结构

**底部 TabBar**（5 个主 Tab）：

| Tab 序号 | 路径 | 文字 | 图标 |
|---------|------|------|------|
| 1 | `pages/dashboard/index` | 总览 | dashboard |
| 2 | `pages/assets/index` | 资产 | assets |
| 3 | `pages/contracts/index` | 合同 | contracts |
| 4 | `pages/workorders/index` | 工单 | workorders |
| 5 | `pages/finance/index` | 财务 | finance |

**非 Tab 子页面**（通过 `uni.navigateTo` 跳转）：

| 路径 | 标题 |
|------|------|
| `pages/auth/login` | 登录 |
| `pages/assets/building-detail` | 楼栋详情 |
| `pages/assets/floor-plan` | 楼层热区图 |
| `pages/assets/unit-detail` | 房源详情 |
| `pages/contracts/detail` | 合同详情 |
| `pages/finance/invoices` | 发票账单 |
| `pages/finance/kpi` | KPI 考核 |
| `pages/workorders/detail` | 工单详情 |
| `pages/workorders/new` | 新建工单 |
| `pages/subleases/index` | 二房东管理 |
| `pages/subleases/detail` | 二房东详情 |

**路由守卫**：`uni.addInterceptor('navigateTo')` 在跳转前检查 `uni.getStorageSync('access_token')`，未登录重定向到 `/pages/auth/login`。

### 1.3 Admin 导航结构

**根布局**：`AppLayout.vue`（侧边栏 + 顶部栏 + 主内容区）

**侧边栏菜单**（ElMenu）：

```
AppLayout
├── ElAside(width: 240px, 可折叠至 64px)
│   └── ElMenu(mode: vertical, router: true)
│       ├── ElMenuItem(index: /dashboard) → "总览" 📊
│       ├── ElSubMenu(index: /assets) → "资产管理"
│       │   ├── ElMenuItem(index: /assets) → "资产总览"
│       │   └── ElMenuItem(index: /assets/import) → "批量导入"
│       ├── ElSubMenu(index: /contracts) → "租务管理"
│       │   ├── ElMenuItem(index: /contracts) → "合同列表"
│       │   └── ElMenuItem(index: /tenants) → "租客管理"
│       ├── ElSubMenu(index: /finance) → "财务管理"
│       │   ├── ElMenuItem(index: /finance) → "财务总览"
│       │   ├── ElMenuItem(index: /finance/invoices) → "账单管理"
│       │   ├── ElMenuItem(index: /finance/expenses) → "费用支出"
│       │   ├── ElMenuItem(index: /finance/meter-readings) → "水电抄表"
│       │   └── ElMenuItem(index: /finance/turnover-reports) → "营业额申报"
│       ├── ElMenuItem(index: /workorders) → "工单管理" 🔧
│       ├── ElMenuItem(index: /subleases) → "二房东管理" 🏘️
│       └── ElSubMenu(index: /settings) → "系统设置"
│           ├── ElMenuItem(index: /settings/users) → "用户管理"
│           ├── ElMenuItem(index: /settings/org) → "组织架构"
│           ├── ElMenuItem(index: /settings/kpi/schemes) → "KPI 方案"
│           ├── ElMenuItem(index: /settings/escalation/templates) → "递增模板"
│           ├── ElMenuItem(index: /settings/alerts) → "预警中心"
│           └── ElMenuItem(index: /settings/audit-logs) → "审计日志"
│
├── ElHeader(height: 56px)
│   └── TopBar
│       ├── Logo + "PropOS"
│       ├── 面包屑 ElBreadcrumb（自动根据路由生成）
│       ├── Spacer
│       ├── 预警铃铛 ElBadge（30s 轮询 GET /api/alerts/unread）
│       └── 头像下拉 ElDropdown
│           ├── "个人信息"
│           ├── "修改密码"
│           └── "退出登录"
│
└── ElMain
    └── <router-view />
```

**Vue Router 路由表**：

```typescript
// admin/src/router/index.ts
routes: [
  { path: '/login', name: 'login', component: LoginView, meta: { public: true } },
  {
    path: '/',
    component: AppLayout,
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'dashboard', component: DashboardView },
      { path: 'assets', name: 'assets', component: AssetsView },
      { path: 'assets/buildings/:id', name: 'building-detail', component: BuildingDetailView },
      { path: 'assets/buildings/:buildingId/floors/:floorId', name: 'floor-plan', component: FloorPlanView },
      { path: 'assets/units/:id', name: 'unit-detail', component: UnitDetailView },
      { path: 'assets/import', name: 'asset-import', component: UnitImportView },
      { path: 'contracts', name: 'contracts', component: ContractsView },
      { path: 'contracts/new', name: 'contract-new', component: ContractFormView },
      { path: 'contracts/:id', name: 'contract-detail', component: ContractDetailView },
      { path: 'contracts/:id/escalation', name: 'escalation-config', component: EscalationConfigView },
      { path: 'contracts/:id/terminate', name: 'contract-terminate', component: ContractTerminateView },
      { path: 'contracts/:id/renew', name: 'contract-renew', component: ContractRenewView },
      { path: 'tenants', name: 'tenants', component: TenantListView },
      { path: 'tenants/new', name: 'tenant-new', component: TenantFormView },
      { path: 'tenants/:id', name: 'tenant-detail', component: TenantDetailView },
      { path: 'finance', name: 'finance', component: FinanceView },
      { path: 'finance/invoices', name: 'invoices', component: InvoicesView },
      { path: 'finance/invoices/:id', name: 'invoice-detail', component: InvoiceDetailView },
      { path: 'finance/invoices/:id/pay', name: 'payment-form', component: PaymentFormView },
      { path: 'finance/expenses', name: 'expenses', component: ExpenseListView },
      { path: 'finance/expenses/new', name: 'expense-new', component: ExpenseFormView },
      { path: 'finance/meter-readings', name: 'meter-readings', component: MeterReadingListView },
      { path: 'finance/meter-readings/new', name: 'meter-reading-new', component: MeterReadingFormView },
      { path: 'finance/turnover-reports', name: 'turnover-reports', component: TurnoverReportListView },
      { path: 'finance/turnover-reports/:id', name: 'turnover-detail', component: TurnoverReportDetailView },
      { path: 'finance/kpi', name: 'kpi', component: KpiView },
      { path: 'finance/kpi/scheme/:schemeId', name: 'kpi-scheme-detail', component: KpiSchemeDetailView },
      { path: 'workorders', name: 'workorders', component: WorkordersView },
      { path: 'workorders/new', name: 'workorder-new', component: WorkorderFormView },
      { path: 'workorders/:id', name: 'workorder-detail', component: WorkorderDetailView },
      { path: 'subleases', name: 'subleases', component: SubleasesView },
      { path: 'subleases/:id', name: 'sublease-detail', component: SubleaseDetailView },
      { path: 'settings/users', name: 'user-management', component: UserManagementView },
      { path: 'settings/users/new', name: 'user-new', component: UserFormView },
      { path: 'settings/users/:id/edit', name: 'user-edit', component: UserFormView },
      { path: 'settings/org', name: 'organization', component: OrganizationManageView },
      { path: 'settings/kpi/schemes', name: 'kpi-schemes', component: KpiSchemeListView },
      { path: 'settings/kpi/schemes/new', name: 'kpi-scheme-new', component: KpiSchemeFormView },
      { path: 'settings/kpi/appeal', name: 'kpi-appeal', component: KpiAppealView },
      { path: 'settings/escalation/templates', name: 'escalation-templates', component: EscalationTemplateListView },
      { path: 'settings/alerts', name: 'alerts', component: AlertCenterView },
      { path: 'settings/audit-logs', name: 'audit-logs', component: AuditLogView },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
]
```

**导航守卫**：`router.beforeEach` 检查 `localStorage.access_token`，公开路由通过 `meta: { public: true }` 标记跳过。

### 1.4 角色路由权限映射

| 角色 | uni-app 可访问 Tab | Admin 可访问路由 |
|------|------------------|----------------|
| `super_admin` / `ops_manager` | 全部 5 Tab | 全部路由 |
| `leasing_agent` | 资产 / 合同 / 工单 | assets / contracts / workorders |
| `finance_staff` | 财务 / 合同（只读） | finance / contracts（只读） |
| `frontline` | 工单 / 资产（只读） | workorders |
| `sub_landlord` | 二房东门户（`subleases/`） | 不开放 Admin |

> 角色在登录后从 JWT Claims 解析写入 Pinia `useAuthStore`；uni-app 守卫读取 store 中的 `role` 字段动态控制 TabBar 可见性；Admin `router.beforeEach` 读取 `localStorage.access_token`，完整角色鉴权委托给后端 RBAC 中间件。

---

## 二、通用组件规范

### 2.1 数据表格

#### Admin: `ProposTable`（基于 ElTable 封装）

```
<ProposTable>
├── ElTable(:data, border, stripe)
│   ├── ElTableColumn(v-for="col in columns")
│   ├── ElTableColumn(type: "index") — 序号列
│   └── ElTableColumn(label: "操作") — 操作列 slot
├── ElPagination(v-model:current-page, v-model:page-size, :total)
│   layout: "total, sizes, prev, pager, next, jumper"
│   page-sizes: [10, 20, 50, 100]
└── 状态处理:
    ├── loading → ElTable v-loading 指令
    ├── empty → ElEmpty(description: "暂无数据")
    └── error → ElResult(icon: "warning", title: error)
```

- 分页参数：`page`（从 1 开始）+ `pageSize`（默认 20，最大 100）
- 排序：`sortBy` + `sortOrder` 传入 Store action
- 筛选栏：表格上方，使用 `ElForm(inline: true)` 布局

#### uni-app: 列表组件（使用 scroll-view + 自定义列表）

```
<template>
  <scroll-view scroll-y @scrolltolower="loadMore">
    <wd-card v-for="item in list" :key="item.id" @click="onItemTap(item)">
      <!-- 卡片内容 -->
    </wd-card>
    <wd-loadmore :state="loadState" /> <!-- loading / finished / error -->
  </scroll-view>
</template>
```

- 移动端无 DataTable，使用卡片列表 + 上拉加载更多
- 下拉刷新：`onPullDownRefresh()` 生命周期钩子
- 加载状态：`wd-loadmore` 组件（loading / finished / error）

### 2.2 状态标签 `StatusTag`

#### Admin:

```html
<el-tag :type="statusTypeMap[status]" size="small">{{ statusLabel }}</el-tag>
```

状态 → Element Plus Tag type 映射见 [第十二节](#十二状态色语义映射速查)。

#### uni-app:

```html
<wd-tag :type="statusTypeMap[status]" size="small">{{ statusLabel }}</wd-tag>
```

- `wd-tag` 的 `type` 取值：`primary` / `success` / `warning` / `danger` / `default`

### 2.3 统计卡片 `MetricCard`

#### Admin:

```
<el-card shadow="hover">
  <div class="metric-card">
    <el-icon :size="40" :color="var(--el-color-primary)"><DataLine /></el-icon>
    <div class="metric-content">
      <span class="metric-label">{{ label }}</span>
      <span class="metric-value">{{ value }}</span>
    </div>
    <span v-if="trend" class="metric-trend" :class="trend > 0 ? 'up' : 'down'">
      {{ trend > 0 ? '↑' : '↓' }} {{ Math.abs(trend) }}%
    </span>
  </div>
</el-card>
```

#### uni-app:

```
<wd-card>
  <view class="metric-card">
    <wd-icon :name="icon" :size="36" />
    <view class="metric-content">
      <text class="metric-label">{{ label }}</text>
      <text class="metric-value">{{ value }}</text>
    </view>
  </view>
</wd-card>
```

### 2.4 表单页通用结构

#### Admin:

```
<ElForm ref="formRef" :model="form" :rules="rules" label-width="120px">
  <ElDivider content-position="left">基本信息</ElDivider>
  <ElRow :gutter="24">
    <ElCol :span="12">
      <ElFormItem label="字段名" prop="fieldName">
        <ElInput v-model="form.fieldName" />
      </ElFormItem>
    </ElCol>
    ...
  </ElRow>
  <ElDivider content-position="left">详细配置</ElDivider>
  ...
</ElForm>
```

- 表单双列布局（`ElRow` + `ElCol :span="12"`），移动端自适应单列
- 校验规则集中在 `rules` 对象，不散落在 template

#### uni-app:

```
<wd-form ref="formRef" :model="form">
  <wd-cell-group title="基本信息">
    <wd-input label="字段名" v-model="form.fieldName" :rules="[{ required: true }]" />
    ...
  </wd-cell-group>
  <wd-cell-group title="详细配置">
    ...
  </wd-cell-group>
  <view style="height: 80px;" /> <!-- 留白防键盘遮挡 -->
</wd-form>
```

### 2.5 Pinia Store 状态分支渲染

所有页面统一使用 Store 三态（loading / error / data）进行条件渲染：

#### Admin:

```vue
<template>
  <div v-loading="store.loading">
    <el-result v-if="store.error" icon="warning" :title="store.error">
      <template #extra>
        <el-button @click="store.fetch()">重试</el-button>
      </template>
    </el-result>
    <template v-else-if="store.item">
      <!-- 实际内容 -->
    </template>
  </div>
</template>
```

#### uni-app:

```vue
<template>
  <wd-status-tip v-if="store.error" type="error" :tip="store.error">
    <wd-button @click="store.fetch()">重试</wd-button>
  </wd-status-tip>
  <view v-else-if="store.loading">
    <wd-skeleton :row="5" />
  </view>
  <view v-else>
    <!-- 实际内容 -->
  </view>
</template>
```

### 2.6 确认弹窗

#### Admin: `ElMessageBox`

三种变体：

| 变体 | 使用场景 | 类型 |
|------|---------|------|
| `ElMessageBox.confirm` | 普通确认（提交审核、派单） | `type: 'info'` |
| `ElMessageBox.confirm` | 不可逆操作（终止合同、作废账单） | `type: 'warning'`，确认按钮 `type: 'danger'` |
| `ElMessageBox.prompt` | 需要输入理由/金额（退回原因、冲抵金额） | `inputType` / `inputValidator` |

```typescript
// admin/src/utils/confirm.ts
await ElMessageBox.confirm('终止后未出账账单将自动取消，此操作不可撤销。', '终止合同', {
  confirmButtonText: '确认终止',
  cancelButtonText: '取消',
  type: 'warning',
  confirmButtonClass: 'el-button--danger',
})
```

#### uni-app: `wd-message-box`

```typescript
// app/src/utils/confirm.ts
import { useMessage } from 'wot-design-uni'
const { show } = useMessage()
await show({
  title: '终止合同',
  msg: '终止后未出账账单将自动取消，此操作不可撤销。',
  confirmButtonText: '确认终止',
})
```

**通用约定**：
- 确认类弹窗点击遮罩不可关闭
- 弹窗内按钮须处理 loading 态：点击确认 → 按钮显示 loading + 禁用取消 → 成功关闭 / 失败恢复并显示错误
- 弹窗最大宽度 560px

### 2.7 Toast / 消息提示

#### Admin: `ElMessage`

```typescript
ElMessage.success('合同保存成功')
ElMessage.error('保存失败: 网络异常')
ElMessage.warning('该合同即将到期')
ElMessage.info('已复制到剪贴板')
```

| 语义 | 图标 | 时长 | 示例 |
|------|------|------|------|
| `success` | ✓ | 3s | "合同保存成功" |
| `error` | ✗ | 5s | "保存失败: 网络异常" |
| `warning` | ⚠ | 4s | "该合同即将到期" |
| `info` | ℹ | 3s | "已复制到剪贴板" |

#### uni-app: `wd-toast` / `uni.showToast`

```typescript
import { useToast } from 'wot-design-uni'
const { success, error, warning, info } = useToast()
success('合同保存成功')
error('保存失败: 网络异常')
```

**队列行为**：同一语义的消息覆盖前一条，不堆叠。

### 2.8 加载状态

**三种使用场景及对应方案**：

| 场景 | Admin 方案 | uni-app 方案 |
|------|-----------|-------------|
| 页面级加载 | `v-loading` 指令 | `wd-skeleton` 骨架屏 |
| 全屏阻塞操作 | `ElLoading.service({ fullscreen: true })` | `wd-overlay` + `wd-loading` |
| 按钮级加载 | `ElButton :loading="submitting"` | `wd-button :loading="submitting"` |

**使用规则**：
- `loading` 状态由 Store 驱动，**不在组件中维护本地 loading 状态**
- 全屏遮罩用于写操作提交；骨架屏用于首次加载；不得混用

### 2.9 Store Action 反馈模式

**规则**：Store 负责数据操作，UI 反馈在组件层统一响应。

**标准模式**（Admin）：

```vue
<script setup lang="ts">
const store = useContractStore()

async function handleSubmit() {
  try {
    await store.create(form.value)
    ElMessage.success('保存成功')
    router.push({ name: 'contracts' })
  } catch {
    // error 已由 store 设置到 error.value，ElMessage.error 在 api/client 拦截器中统一处理
  }
}
</script>
```

**标准模式**（uni-app）：

```vue
<script setup lang="ts">
const store = useContractStore()
const { success } = useToast()

async function handleSubmit() {
  try {
    await store.create(form.value)
    success('保存成功')
    uni.navigateBack()
  } catch {
    // error 已由 store 设置到 error.value
  }
}
</script>
```

### 2.10 弹窗选型规则

#### Admin（PC 端）：

| 弹窗类型 | 组件 | 适用场景 |
|---------|------|---------|
| 二次确认 | `ElMessageBox.confirm` | 删除、终止、作废等不可逆操作 |
| 带输入弹窗 | `ElMessageBox.prompt` | 退回原因、冲抵金额、审批备注 |
| 复杂表单弹窗 | `ElDialog` | 编辑详情、配置规则 |
| 抽屉详情预览 | `ElDrawer` | 快速预览（楼层图单元详情） |
| 日期选取 | `ElDatePicker` | 日期 / 日期范围 |

#### uni-app（移动端）：

| 弹窗类型 | 组件 | 适用场景 |
|---------|------|---------|
| 二次确认 | `wd-message-box` | 删除、终止、作废 |
| 选择列表 | `wd-action-sheet` / `wd-picker` | 指派处理人、选择模板 |
| 详情预览 | `wd-popup(position: bottom)` | 楼层图单元详情 |
| 日期选取 | `wd-datetime-picker` | 日期选择 |

**通用约定**：
- 确认弹窗外部点击不可关闭；信息预览类可关闭
- 弹窗最大宽度：Dialog ≤ 560px；BottomPopup 高度 ≤ 屏幕 85%

### 2.11 暗色模式策略

**Phase 1 不实现暗色模式**。仅预留以下约束确保后续可快速接入：

1. uni-app 全部使用 `wot-design-uni` CSS 变量（`--wot-color-*`），禁止内联 `style="color: #xxx"`
2. Admin 全部使用 Element Plus 内置变量（`--el-color-*`），禁止硬编码颜色值
3. 后续实现时只需覆盖 CSS 变量根值即可

---

## 三、认证模块页面

### 3.1 登录页

**Admin**: `LoginView.vue`  
**路由**: `/login`（`meta: { public: true }`）  
**uni-app**: `pages/auth/login.vue`  
**Store**: `useAuthStore`  
**API**: `POST /api/auth/login`

#### Admin 组件树：

```
LoginView
└── div.login-container(居中, max-width: 400px)
    └── ElCard
        └── ElForm(:model="form" :rules="rules")
            ├── Logo + "PropOS" 标题
            ├── ElFormItem(prop: "email")
            │   └── ElInput(v-model="form.email" prefix-icon="User")
            ├── ElFormItem(prop: "password")
            │   └── ElInput(v-model="form.password" type="password" show-password prefix-icon="Lock")
            ├── div.login-actions
            │   └── ElLink("忘记密码？")
            ├── ElButton(type="primary" :loading="loading" @click="handleLogin" style="width:100%")
            │   "登 录"
            └── ElAlert(v-if="error" type="error" :title="error" show-icon)
```

#### uni-app 组件树：

```
login.vue
└── view.login-container
    ├── view.logo-area
    │   └── image(src: logo) + text "PropOS"
    ├── wd-input(label="邮箱" v-model="form.email")
    ├── wd-input(label="密码" v-model="form.password" show-password)
    ├── wd-button(type="primary" block :loading="loading" @click="handleLogin")
    │   "登 录"
    └── wd-notice(v-if="error" type="danger") {{ error }}
```

**交互流程**:

```
用户输入邮箱+密码 → 点击"登录"
  → store.login(email, password)
  → loading = true → POST /api/auth/login
  ├── 成功 → 存储 JWT → authStore.setUser(data)
  │   ├── Admin → router.push('/dashboard')
  │   └── uni-app → uni.switchTab({ url: '/pages/dashboard/index' })
  ├── INVALID_CREDENTIALS → error = "用户名或密码错误"
  ├── ACCOUNT_LOCKED → error = "账号已锁定至 {locked_until}"
  ├── ACCOUNT_FROZEN → error = "账号已冻结"
  └── 网络错误 → error = "网络连接失败，请重试"
```

**特殊逻辑**:
- 二房东账号 `must_change_password == true` 时，登录成功后强制跳转修改密码页
- 密码输入框支持切换明文/密文

### 3.2 修改密码页

**Admin**: `ChangePasswordView.vue`（Dialog 或独立页面）  
**uni-app**: 从个人中心发起  
**API**: `POST /api/auth/change-password`

#### Admin 组件树：

```
ElDialog(title="修改密码" width="400px")
└── ElForm(:model="form" :rules="rules")
    ├── ElFormItem(label="旧密码" prop="oldPassword")
    │   └── ElInput(type="password" show-password)
    ├── ElFormItem(label="新密码" prop="newPassword")
    │   └── ElInput(type="password" show-password)
    │       └── div.password-strength(密码强度指示条)
    ├── ElFormItem(label="确认密码" prop="confirmPassword")
    │   └── ElInput(type="password" show-password)
    ├── ElText(type="info") "密码要求：8位以上，含大小写字母+数字"
    └── ElButton(type="primary" :loading="submitting") "确认修改"
```

**校验规则**:
- 新密码 ≥ 8 位，含大小写字母 + 数字
- 新密码 ≠ 旧密码
- 两次输入一致

---

## 四、概览 Dashboard 模块

### 4.1 总览页

**Admin**: `DashboardView.vue`  
**路由**: `/dashboard`  
**uni-app**: `pages/dashboard/index.vue`（TabBar 首页）  
**Store**: `useDashboardStore`  
**API**: `GET /api/assets/overview` + `GET /api/noi/summary` + `GET /api/contracts/wale` + `GET /api/alerts/unread`

#### Admin 组件树：

```
DashboardView
└── div.dashboard-container
    ├── ── 第一行：核心指标卡片 ──
    │   ElRow(:gutter="24")
    │   ├── ElCol(:span="6") → MetricCard(label: "总出租率", value: "87.5%")
    │   ├── ElCol(:span="6") → MetricCard(label: "当月 NOI", value: "¥1,234,567")
    │   ├── ElCol(:span="6") → MetricCard(label: "WALE(收入)", value: "2.35 年")
    │   └── ElCol(:span="6") → MetricCard(label: "WALE(面积)", value: "2.18 年")
    │
    ├── ── 第二行：业态出租率分拆 ──
    │   ElRow(:gutter="24")
    │   ├── ElCol(:span="8") → PropertyTypeCard("写字楼", 441套, 88.4%)
    │   ├── ElCol(:span="8") → PropertyTypeCard("商铺", 25套, 88.0%)
    │   └── ElCol(:span="8") → PropertyTypeCard("公寓", 173套, 85.5%)
    │
    ├── ── 第三行：图表区 ──
    │   ElRow(:gutter="24")
    │   ├── ElCol(:span="12") → ElCard
    │   │   └── NOI 近12月趋势折线图（ECharts）
    │   │       └── 点击跳转 /dashboard/noi-detail
    │   └── ElCol(:span="12") → ElCard
    │       └── 收款进度环形图（本月应收 vs 实收）
    │
    └── ── 第四行：预警汇总 + 快捷入口 ──
        ElRow(:gutter="24")
        ├── ElCol(:span="12") → ElCard(header="最近预警")
        │   ├── ElTimeline(最多 5 条)
        │   │   └── ElTimelineItem(v-for="alert in alerts")
        │   └── ElLink("查看全部预警" → /settings/alerts)
        └── ElCol(:span="12") → ElCard(header="快捷操作")
            ├── ElButton("新建合同" → /contracts/new)
            ├── ElButton("提交报修" → /workorders/new)
            ├── ElButton("录入收款" → /finance/invoices)
            └── ElButton("抄表录入" → /finance/meter-readings/new)
```

#### uni-app 组件树：

```
dashboard/index.vue
└── scroll-view(scroll-y)
    ├── ── 核心指标（2×2 网格）──
    │   view.metric-grid
    │   ├── MetricCard("总出租率", "87.5%")
    │   ├── MetricCard("当月 NOI", "¥1,234,567")
    │   ├── MetricCard("WALE(收入)", "2.35 年")
    │   └── MetricCard("WALE(面积)", "2.18 年")
    │
    ├── ── 三业态分拆（横向滚动卡片）──
    │   scroll-view(scroll-x)
    │   ├── PropertyTypeCard("写字楼")
    │   ├── PropertyTypeCard("商铺")
    │   └── PropertyTypeCard("公寓")
    │
    ├── ── 预警列表（最多 5 条）──
    │   wd-card(title="最近预警")
    │   ├── wd-cell(v-for="alert in alerts")
    │   └── wd-button(type="text" @click="toAlerts") "查看全部"
    │
    └── ── 快捷操作 ──
        view.action-grid
        ├── ActionCard("新建合同" → /pages/contracts/detail?mode=new)
        ├── ActionCard("提交报修" → /pages/workorders/new)
        └── ActionCard("录入收款" → /pages/finance/invoices)
```

### 4.2 NOI 明细页 `NoiDetailView`

**Admin**: `admin/src/views/dashboard/NoiDetailView.vue`  
**路由**: `/dashboard/noi-detail`  
**Store**: `useNoiDetailStore`  
**API**: `GET /api/noi/summary` + `GET /api/noi/trend` + `GET /api/noi/breakdown` + `GET /api/noi/vacancy-loss`

> uni-app 端不设 NOI 明细独立页面，通过 Dashboard 卡片下钻到 Admin 端查看。

#### Admin 组件树：

```
NoiDetailView
└── div
    ├── ── 视角切换 ──
    │   ElRadioGroup(v-model="perspective")
    │   ├── ElRadioButton("应收视角")
    │   └── ElRadioButton("实收视角")
    │
    ├── ── 汇总卡片行 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("PGI 潜在总收入", "¥xxx")
    │   ├── MetricCard("空置损失", "-¥xxx", type="danger")
    │   └── MetricCard("NOI 净营运收入", "¥xxx", type="primary")
    │
    ├── ── 业态 NOI 分拆表格 ──
    │   ElTable(:data="breakdown")
    │   ├── ElTableColumn(label="业态")
    │   ├── ElTableColumn(label="收入")
    │   ├── ElTableColumn(label="支出")
    │   ├── ElTableColumn(label="NOI")
    │   └── ElTableColumn(label="出租率")
    │
    ├── ── 近12月 NOI 趋势折线图 ──
    │   ECharts(type: line, data: monthlyNoi)
    │
    ├── ── 运营支出构成饼图 ──
    │   ECharts(type: pie, data: expenseCategories)
    │
    └── ── 空置损失测算列表 ── (Should)
        ElCollapse
        └── ElCollapseItem(title="空置损失明细")
            └── ElTable: 单元编号 | 面积 | 参考市场租金 | 月损失额
```

### 4.3 WALE 明细页 `WaleDetailView`

**Admin**: `admin/src/views/dashboard/WaleDetailView.vue`  
**路由**: `/dashboard/wale-detail`  
**Store**: `useWaleDetailStore`  
**API**: `GET /api/contracts/wale` + `GET /api/contracts/wale/trend`(Should) + `GET /api/contracts/wale/waterfall`(Should)

#### Admin 组件树：

```
WaleDetailView
└── div
    ├── ── 汇总卡片 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("收入加权 WALE", "2.35 年")
    │   └── MetricCard("面积加权 WALE", "2.18 年")
    │
    ├── ── 分维度 WALE 表格 ──
    │   ElRadioGroup(v-model="groupBy"): [楼栋] / [业态]
    │   ElTable(:data="waleData")
    │   ├── ElTableColumn(label="维度")
    │   ├── ElTableColumn(label="收入加权 WALE")
    │   ├── ElTableColumn(label="面积加权 WALE")
    │   └── ElTableColumn(label="在租合同数")
    │
    ├── ── WALE 趋势折线图 ── (Should: S-02)
    │   ECharts(双线: 收入WALE + 面积WALE)
    │
    └── ── 到期瀑布图 ── (Should: S-02)
        ECharts(type: bar, x: 年份, y: 到期面积/租金)
```

### 4.4 KPI 考核看板

**Admin**: `KpiView.vue`  
**路由**: `/finance/kpi`  
**uni-app**: `pages/finance/kpi.vue`  
**Store**: `useKpiDashboardStore`  
**API**: `GET /api/kpi/schemes` + `GET /api/kpi/scores` + `GET /api/kpi/rankings` + `GET /api/kpi/trends`

#### Admin 组件树：

```
KpiView
└── div
    ├── ── 方案与周期选择器 ──
    │   ElForm(inline)
    │   ├── ElSelect(v-model="schemeId" :options="schemes")
    │   ├── ElSelect(v-model="period" :options="periods") "2026Q1 / 2026-03"
    │   └── ElButton(icon="Download") "导出 Excel"
    │
    ├── ── 当前用户 KPI 总览 ── (员工视角)
    │   ElCard
    │   ├── div: ElStatistic("总分", 87.5) + ElTag("排名 #3")
    │   ├── ECharts(type: radar, 各指标雷达图)
    │   └── ElCollapse(各指标明细)
    │       ├── ElCollapseItem: K01 出租率 | 实际: 92% | 得分: 85 | 加权: 12.75
    │       └── ...
    │
    ├── ── 排名榜 ── (管理层视角)
    │   ElCard(header="排名榜")
    │   ├── ElRadioGroup: [员工] / [部门]
    │   └── ElTable
    │       ├── ElTableColumn(label="排名")
    │       ├── ElTableColumn(label="姓名/部门")
    │       ├── ElTableColumn(label="总分")
    │       └── ElTableColumn(label="较上期变化")
    │
    ├── ── 趋势折线图 ──
    │   ElCard(header="历史趋势")
    │   ├── ECharts(type: line, 6~12个月 KPI 总分趋势)
    │   └── div: 同比 +5.2% | 环比 +1.3%
    │
    └── ── 申诉入口 ──
        ElCard
        ├── 快照状态: frozen / recalculated
        ├── ElText "申诉窗口剩余: X 天"
        └── ElButton(type="primary" plain) "提交申诉" → /settings/kpi/appeal
```

#### uni-app 组件树：

```
finance/kpi.vue
└── scroll-view(scroll-y)
    ├── ── 方案/周期选择 ──
    │   wd-picker(columns="schemes")
    │   wd-picker(columns="periods")
    │
    ├── ── KPI 总览卡片 ──
    │   wd-card
    │   ├── text.score "87.5 分"
    │   ├── wd-tag "排名 #3"
    │   └── 雷达图区域（ECharts uni-app 版）
    │
    ├── ── 指标明细折叠 ──
    │   wd-collapse
    │   └── wd-collapse-item(v-for="metric in metrics")
    │
    └── ── 排名列表 ──
        wd-card(title="排名榜")
        └── view(v-for="item in rankings")
```

### 4.5 KPI 方案详情页

**Admin**: `KpiSchemeDetailView.vue`  
**路由**: `/finance/kpi/scheme/:schemeId`  
**Store**: `useKpiSchemeDetailStore`  
**API**: `GET /api/kpi/schemes/:id` + `GET /api/kpi/schemes/:id/metrics`

#### Admin 组件树：

```
KpiSchemeDetailView
└── div
    ├── ── 方案基本信息 ──
    │   ElDescriptions(border)
    │   ├── ElDescriptionsItem(label="名称") {{ scheme.name }}
    │   ├── ElDescriptionsItem(label="评估周期") {{ scheme.cycle }}
    │   ├── ElDescriptionsItem(label="有效期") {{ scheme.valid_range }}
    │   └── ElDescriptionsItem(label="适用对象数") {{ scheme.target_count }}
    │
    ├── ── 指标配置表 ──
    │   ElTable(:data="metrics")
    │   ├── ElTableColumn(label="指标编号")
    │   ├── ElTableColumn(label="名称")
    │   ├── ElTableColumn(label="方向") ← 正向↑ / 反向↓
    │   ├── ElTableColumn(label="权重")
    │   ├── ElTableColumn(label="满分标准")
    │   └── ElTableColumn(label="及格标准")
    │   Footer: 权重合计: 100%
    │
    └── ── 绑定对象列表 ──
        ElTable(:data="targets")
        ├── ElTableColumn(label="类型")
        ├── ElTableColumn(label="名称")
        └── ElTableColumn(label="部门")
```

---

## 五、资产模块页面

### 5.1 资产概览页

**Admin**: `AssetsView.vue`  
**路由**: `/assets`  
**uni-app**: `pages/assets/index.vue`（TabBar 第 2 Tab）  
**Store**: `useAssetOverviewStore`  
**API**: `GET /api/assets/overview` + `GET /api/buildings`

#### Admin 组件树：

```
AssetsView
└── div
    ├── div.header-actions
    │   ├── ElButton(icon="Upload") "批量导入" → /assets/import
    │   └── ElButton(icon="Download") "导出"
    │
    ├── ── 三业态汇总卡片 ──
    │   ElRow(:gutter="24")
    │   ├── ElCol(:span="8") → PropertyTypeCard("写字楼", 441套, 88.4%)
    │   ├── ElCol(:span="8") → PropertyTypeCard("商铺", 25套, 88.0%)
    │   └── ElCol(:span="8") → PropertyTypeCard("公寓", 173套, 85.5%)
    │
    └── ── 楼栋列表 ──
        ElTable(:data="buildings" @row-click="toDetail")
        ├── ElTableColumn(label="楼栋名称")
        ├── ElTableColumn(label="业态") → ElTag
        ├── ElTableColumn(label="总楼层")
        ├── ElTableColumn(label="NLA(m²)")
        ├── ElTableColumn(label="出租率") → ElProgress(:percentage)
        └── ElTableColumn(label="操作") → ElButton("查看")
```

#### uni-app 组件树：

```
assets/index.vue
└── scroll-view(scroll-y)
    ├── ── 三业态汇总（横向滚动）──
    │   scroll-view(scroll-x)
    │   └── PropertyTypeCard(v-for="type in types")
    │
    └── ── 楼栋列表 ──
        wd-card(v-for="building in buildings" @click="toDetail(building.id)")
        ├── view.building-header
        │   ├── text.building-name {{ building.name }}
        │   └── wd-tag {{ building.property_type }}
        ├── text "共 {{ building.total_floors }} 层 | NLA: {{ building.nla }} m²"
        └── wd-progress(:percentage="building.occupancy_rate")
```

### 5.2 楼栋详情页

**Admin**: `BuildingDetailView.vue`  
**路由**: `/assets/buildings/:id`  
**uni-app**: `pages/assets/building-detail.vue`（navigateTo，query: id）  
**Store**: `useBuildingDetailStore`  
**API**: `GET /api/buildings/:id` + `GET /api/floors?building_id=`

#### Admin 组件树：

```
BuildingDetailView
└── div
    ├── ── 楼栋信息卡片 ──
    │   ElDescriptions(border :column="2")
    │   ├── ElDescriptionsItem(label="楼栋名称")
    │   ├── ElDescriptionsItem(label="业态")
    │   ├── ElDescriptionsItem(label="总楼层")
    │   ├── ElDescriptionsItem(label="GFA(m²)")
    │   ├── ElDescriptionsItem(label="NLA(m²)")
    │   └── ElDescriptionsItem(label="出租率")
    │
    └── ── 楼层列表 ──
        ElTable(:data="floors")
        ├── ElTableColumn(label="楼层")
        ├── ElTableColumn(label="单元数")
        ├── ElTableColumn(label="出租率") → ElProgress
        ├── ElTableColumn(label="操作")
        │   ├── ElButton(link) "查看楼层图" → /assets/buildings/:bid/floors/:fid
        │   └── ElButton(link) "单元列表"
```

#### uni-app 组件树：

```
building-detail.vue
└── scroll-view(scroll-y)
    ├── wd-card(title="楼栋信息")
    │   └── wd-cell-group
    │       ├── wd-cell(title="楼栋名称" :value="building.name")
    │       ├── wd-cell(title="业态" :value="building.property_type")
    │       ├── wd-cell(title="总楼层" :value="building.total_floors")
    │       └── wd-cell(title="出租率" :value="building.occupancy_rate + '%'")
    │
    └── wd-card(title="楼层列表")
        └── wd-cell(v-for="floor in floors" @click="toFloor(floor.id)")
            ├── title: "{{ floor.floor_number }}层"
            ├── label: "共 {{ floor.unit_count }} 个单元"
            └── value: wd-progress(:percentage)
```

### 5.3 楼层热区图页

**Admin**: `FloorPlanView.vue`  
**路由**: `/assets/buildings/:buildingId/floors/:floorId`  
**uni-app**: `pages/assets/floor-plan.vue`  
**Store**: `useFloorMapStore`  
**API**: `GET /api/floors/:id` + `GET /api/floors/:id/heatmap`

#### Admin 组件树：

```
FloorPlanView
└── div.floor-plan-container
    ├── ── 工具栏 ──
    │   ElSpace
    │   ├── ElSwitch(v-model="penetrateMode") "穿透模式"
    │   ├── ElSelect(v-model="filterType") "业态筛选: 全部/写字楼/商铺/公寓"
    │   └── ElButtonGroup(缩放控制: + / - / 重置)
    │
    ├── ── SVG 楼层图 ── (flex: 1)
    │   div.svg-container(v-html="svgContent" @click="onUnitClick")
    │   <!-- 热区元素 data-unit-id 通过事件委托处理点击 -->
    │   <!-- 状态色通过 CSS class 动态注入 SVG style -->
    │
    ├── ── 状态色块图例 ── (Positioned 右上角)
    │   div.legend-panel
    │   ├── LegendItem(🟢 已租, --el-color-success)
    │   ├── LegendItem(🟡 即将到期, --el-color-warning)
    │   ├── LegendItem(🔴 空置, --el-color-danger)
    │   └── LegendItem(⚪ 非可租, --el-color-info)
    │
    └── ── 侧边详情抽屉 ── (点击热区后弹出)
        ElDrawer(v-model="drawerVisible" direction="rtl" size="360px")
        ├── ElDescriptions
        │   ├── "单元编号": unit.unit_number
        │   ├── "业态": unit.property_type
        │   ├── "面积": unit.area + " m²"
        │   ├── "状态": StatusTag(unit.status)
        │   ├── "租户": unit.tenant_name (如有)
        │   ├── "月租金": unit.monthly_rent (如有)
        │   └── "到期日": unit.end_date (如有)
        └── ElSpace
            ├── ElButton("查看详情" → unit-detail)
            └── ElButton("查看合同" → contract-detail)
```

#### uni-app 组件树：

```
floor-plan.vue
└── view.floor-plan
    ├── ── SVG 渲染区 ──
    │   <!-- #ifdef APP-PLUS -->
    │   web-view(:src="floorPlanUrl") <!-- WebView 内加载 SVG + 交互脚本 -->
    │   <!-- #endif -->
    │   <!-- #ifdef MP-WEIXIN -->
    │   canvas(type="2d" @tap="onCanvasTap") <!-- 小程序用 canvas 绘制 -->
    │   <!-- #endif -->
    │
    ├── ── 图例 ──
    │   view.legend: 已租(绿) | 即将到期(黄) | 空置(红) | 非可租(灰)
    │
    └── ── 底部详情弹窗 ──
        wd-popup(v-model="popupVisible" position="bottom" :style="{ height: '40vh' }")
        ├── wd-cell-group
        │   ├── wd-cell(title="单元" :value="unit.unit_number")
        │   ├── wd-cell(title="面积" :value="unit.area + ' m²'")
        │   ├── wd-cell(title="状态") StatusTag
        │   └── wd-cell(title="租户" :value="unit.tenant_name")
        └── view.popup-actions
            ├── wd-button("查看详情" → unit-detail)
            └── wd-button("查看合同" → contract-detail)
```

### 5.4 房源详情页

**Admin**: `UnitDetailView.vue`  
**路由**: `/assets/units/:id`  
**uni-app**: `pages/assets/unit-detail.vue`  
**Store**: `useUnitDetailStore`  
**API**: `GET /api/units/:id` + `GET /api/renovations?unit_id=`

#### Admin 组件树：

```
UnitDetailView
└── div
    ├── ── 状态标签行 ──
    │   ElSpace
    │   ├── StatusTag(unit.current_status)
    │   ├── ElTag(unit.property_type)
    │   └── ElButton(icon="Edit") "编辑"
    │
    ├── ── 基本信息 ──
    │   ElDescriptions(border :column="2" title="基本信息")
    │   ├── ElDescriptionsItem(label="单元编号")
    │   ├── ElDescriptionsItem(label="建筑面积") "{{ unit.gfa }} m²"
    │   ├── ElDescriptionsItem(label="套内面积") "{{ unit.nia }} m²"
    │   ├── ElDescriptionsItem(label="朝向")
    │   ├── ElDescriptionsItem(label="层高") "{{ unit.floor_height }} m"
    │   ├── ElDescriptionsItem(label="装修状态")
    │   ├── ElDescriptionsItem(label="参考市场租金") "¥{{ unit.market_rent_reference }}/m²/月"
    │   └── ElDescriptionsItem(label="前序单元") // 拆分/合并时显示
    │
    ├── ── 业态扩展字段 ── (根据 property_type 动态展示)
    │   ElDescriptions(border title="业态信息")
    │   └── 写字楼: 工位数 + 分隔间数
    │     / 商铺: 门面宽度 + 临街面 + 层高
    │     / 公寓: 卧室数 + 独立卫生间
    │
    ├── ── 当前租赁信息 ── (仅 status=leased 时显示)
    │   ElCard(header="当前租赁")
    │   ├── ElDescriptions: 租户名称, 合同编号, 月租金, 到期日, 剩余天数
    │   └── ElButton(link) "查看合同详情"
    │
    └── ── 改造记录 ──
        ElCard(header="改造记录")
        ├── ElTable(:data="renovations")
        │   ├── ElTableColumn(label="改造类型")
        │   ├── ElTableColumn(label="日期")
        │   └── ElTableColumn(label="造价")
        └── ElButton(icon="Plus") "新增改造记录"
```

#### uni-app 组件树：

```
unit-detail.vue
└── scroll-view(scroll-y)
    ├── ── 状态 ──
    │   view.status-bar
    │   ├── StatusTag(unit.status) + wd-tag(unit.property_type)
    │
    ├── ── 基本信息 ──
    │   wd-cell-group(title="基本信息")
    │   ├── wd-cell(title="单元编号" :value="unit.unit_number")
    │   ├── wd-cell(title="建筑面积" :value="unit.gfa + ' m²'")
    │   ├── wd-cell(title="套内面积" :value="unit.nia + ' m²'")
    │   ├── wd-cell(title="市场租金" :value="'¥' + unit.market_rent_reference + '/m²/月'")
    │   └── ...
    │
    ├── ── 当前租赁信息 ── (v-if="unit.status === 'leased'")
    │   wd-cell-group(title="当前租赁")
    │   ├── wd-cell(title="租户" :value="unit.tenant_name")
    │   ├── wd-cell(title="月租金" :value="'¥' + unit.monthly_rent")
    │   └── wd-cell(title="到期日" :value="unit.end_date" is-link @click="toContract")
    │
    └── ── 改造记录 ──
        wd-cell-group(title="改造记录")
        └── wd-cell(v-for="item in renovations" is-link)
```

### 5.5 Excel 批量导入页

**Admin**: `UnitImportView.vue`  
**路由**: `/assets/import`  
**Store**: `useUnitImportStore`  
**API**: `POST /api/imports`（含 `dry_run` 模式）

> 批量导入仅 Admin 端提供，uni-app 端不支持。

#### Admin 组件树：

```
UnitImportView
└── div
    └── ElSteps(:active="currentStep" align-center)
        ├── ElStep(title="选择文件")
        │   ├── ElSelect(v-model="dataType") "数据类型: 单元台账 / 历史合同 / 子租赁"
        │   ├── ElUpload(:auto-upload="false" accept=".xlsx,.xls" :limit="1")
        │   ├── ElLink("下载导入模板")
        │   └── ElAlert(type="info") "注意: 单元台账导入采用整批回滚模式"
        │
        ├── ElStep(title="预校验")
        │   ├── ElButton(type="primary" :loading="validating") "执行试导入 (dry_run)"
        │   └── 校验结果:
        │       ├── ElAlert(type="success") "共 639 条，校验通过 635 条，错误 4 条"
        │       ├── ElTable(:data="errors")
        │       │   ├── ElTableColumn(label="行号")
        │       │   ├── ElTableColumn(label="字段")
        │       │   └── ElTableColumn(label="错误原因")
        │       └── ElButton("下载错误报告 Excel")
        │
        └── ElStep(title="确认导入")
            ├── ElText "确认将 635 条数据写入数据库？"
            ├── ElText "导入批次号: BATCH-2026-04-08-001"
            ├── ElButton(type="primary" :loading="importing") "确认导入"
            └── ElProgress(:percentage="importProgress")
```

---

## 六、租务与合同模块页面

### 6.1 合同列表页

**Admin**: `ContractsView.vue`  
**路由**: `/contracts`  
**uni-app**: `pages/contracts/index.vue`（TabBar 第 3 Tab）  
**Store**: `useContractListStore`  
**API**: `GET /api/contracts`

#### Admin 组件树：

```
ContractsView
└── div
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElSelect(v-model="filters.status") "状态: 全部/报价中/执行中/即将到期/已终止..."
    │   ├── ElSelect(v-model="filters.property_type") "业态: 全部/写字楼/商铺/公寓"
    │   ├── ElSelect(v-model="filters.building_id") "楼栋"
    │   ├── ElInput(v-model="filters.keyword" prefix-icon="Search") "搜索: 合同编号/租户名称"
    │   ├── ElButton(icon="RefreshRight") "重置"
    │   └── ElButton(type="primary" icon="Plus") "新建合同" → /contracts/new
    │
    └── ProposTable(:data="contracts" :total="meta.total")
        ├── ElTableColumn(label="合同编号" sortable)
        ├── ElTableColumn(label="租户")
        ├── ElTableColumn(label="业态") → ElTag
        ├── ElTableColumn(label="单元") // 多单元逗号分隔
        ├── ElTableColumn(label="月租金") → "¥{amount}/月"
        ├── ElTableColumn(label="状态") → StatusTag
        ├── ElTableColumn(label="到期日")
        └── ElTableColumn(label="操作")
            └── ElDropdown
                ├── ElDropdownItem("续签" → /contracts/:id/renew)
                ├── ElDropdownItem("终止" → /contracts/:id/terminate)
                └── ElDropdownItem("查看押金" → /contracts/:id?tab=deposits)
```

#### uni-app 组件树：

```
contracts/index.vue
└── view
    ├── ── 筛选 ──
    │   view.filter-bar
    │   ├── wd-drop-menu
    │   │   ├── wd-drop-menu-item(title="状态" :options="statusOptions")
    │   │   ├── wd-drop-menu-item(title="业态" :options="typeOptions")
    │   │   └── wd-drop-menu-item(title="楼栋" :options="buildingOptions")
    │   └── wd-search(v-model="keyword" placeholder="搜索合同/租户")
    │
    └── scroll-view(scroll-y @scrolltolower="loadMore")
        ├── wd-card(v-for="contract in list" @click="toDetail(contract.id)")
        │   ├── view.card-header
        │   │   ├── text.contract-no {{ contract.contract_number }}
        │   │   └── StatusTag(:status="contract.status")
        │   ├── wd-cell(title="租户" :value="contract.tenant_name")
        │   ├── wd-cell(title="月租金" :value="'¥' + contract.monthly_rent")
        │   └── wd-cell(title="到期日" :value="contract.end_date")
        └── wd-loadmore(:state="loadState")
```

### 6.2 合同新建/编辑页

**Admin**: `ContractFormView.vue`  
**路由**: `/contracts/new` 或 `/contracts/:contractId/edit`  
**Store**: `useContractFormStore`  
**API**: `POST /api/contracts` / `PATCH /api/contracts/:id`

> 合同新建/编辑为复杂表单，仅 Admin 端提供完整表单；uni-app 端只提供查看合同详情功能。

#### Admin 组件树：

```
ContractFormView
└── div
    └── ElForm(ref="formRef" :model="form" :rules="rules" label-width="120px")
        ├── ── Section: 租户信息 ──
        │   ElDivider "租户信息"
        │   ElRow(:gutter="24")
        │   ├── ElCol(:span="12")
        │   │   └── ElFormItem(label="选择租户" prop="tenant_id")
        │   │       └── ElSelect(v-model="form.tenant_id" filterable remote)
        │   └── ElCol(:span="12")
        │       └── ElButton(type="primary" link) "新建租户" → /tenants/new
        │
        ├── ── Section: 合同基本信息 ──
        │   ElDivider "合同基本信息"
        │   ElRow(:gutter="24")
        │   ├── ElCol(:span="12") → ElFormItem("合同编号") → ElInput(自动生成可修改)
        │   ├── ElCol(:span="12") → ElFormItem("付款周期") → ElSelect(月付/季付/半年付/年付)
        │   ├── ElCol(:span="12") → ElFormItem("起租日") → ElDatePicker
        │   ├── ElCol(:span="12") → ElFormItem("到期日") → ElDatePicker
        │   ├── ElCol(:span="12") → ElFormItem("免租天数") → ElInputNumber
        │   ├── ElCol(:span="12") → ElFormItem("装修期天数") → ElInputNumber
        │   ├── ElCol(:span="12") → ElFormItem("含税") → ElSwitch(v-model="form.tax_inclusive")
        │   └── ElCol(:span="12") → ElFormItem("税率 %") → ElInputNumber(:disabled="!form.tax_inclusive")
        │
        ├── ── Section: 单元绑定（M:N）──
        │   ElDivider "关联单元"
        │   ElTable(:data="form.units" border)
        │   ├── ElTableColumn(type="selection")
        │   ├── ElTableColumn(label="单元编号")
        │   ├── ElTableColumn(label="楼层")
        │   ├── ElTableColumn(label="面积")
        │   ├── ElTableColumn(label="计费面积") → ElInputNumber(可编辑)
        │   └── ElTableColumn(label="单价(¥/m²/月)") → ElInputNumber(可编辑)
        │   Footer: "合计计费面积: {{ totalArea }} m² | 月租金合计: ¥{{ totalRent }}"
        │   ElButton(icon="Plus") "添加单元"
        │
        ├── ── Section: 押金信息 ──
        │   ElDivider "押金"
        │   ElFormItem(label="押金金额") → ElInputNumber(prefix="¥")
        │
        ├── ── Section: 商铺营业额分成 ── (v-if="form.property_type === 'retail'")
        │   ElDivider "营业额分成"
        │   ├── ElFormItem(label="保底月租金") → ElInputNumber
        │   └── ElFormItem(label="分成比例 %") → ElInputNumber
        │
        └── ── Section: 附件上传 ──
            ElDivider "合同附件"
            ElUpload(multiple accept=".pdf" :limit="10" :auto-upload="false")
```

### 6.3 合同详情页

**Admin**: `ContractDetailView.vue`  
**路由**: `/contracts/:contractId`  
**uni-app**: `pages/contracts/detail.vue`  
**Store**: `useContractDetailStore`  
**API**: `GET /api/contracts/:id` + `GET /api/contracts/:id/escalation-phases` + `GET /api/contracts/:id/attachments`

#### Admin 组件树：

```
ContractDetailView
└── div
    └── ElTabs(v-model="activeTab")
        ├── ── Tab 1: 基本信息 ──
        │   ElTabPane(label="基本信息")
        │   ├── ElSpace: StatusTag(状态) + ElTag(业态) + ElTag(含税/不含税)
        │   ├── ElDescriptions(border :column="2" title="合同信息")
        │   │   ├── ElDescriptionsItem("合同编号")
        │   │   ├── ElDescriptionsItem("租户")
        │   │   ├── ElDescriptionsItem("起租日")
        │   │   ├── ElDescriptionsItem("到期日")
        │   │   ├── ElDescriptionsItem("月租金(含税)")
        │   │   ├── ElDescriptionsItem("月租金(不含税)")
        │   │   ├── ElDescriptionsItem("付款周期")
        │   │   ├── ElDescriptionsItem("免租天数")
        │   │   └── ElDescriptionsItem("终止类型") // 已终止时显示
        │   │
        │   ├── ElCard(header="关联单元")
        │   │   └── ElTable: 单元编号 | 楼层 | 计费面积 | 单价
        │   │
        │   ├── ElCard(header="续签链")
        │   │   └── ElTimeline(合同链: 原合同 → 续签1 → 续签2 ...)
        │   │
        │   └── ElSpace(操作按钮)
        │       ├── ElButton(type="primary") "续签" → /contracts/:id/renew
        │       ├── ElButton "终止" → /contracts/:id/terminate
        │       └── ElButton "租金预测" → /contracts/:id/rent-forecast (Should)
        │
        ├── ── Tab 2: 递增规则 ──
        │   ElTabPane(label="递增规则")
        │   ├── ElTimeline
        │   │   └── ElTimelineItem(v-for="phase in phases")
        │   │       "阶段{{ n }}: {{ range }}, {{ type }}"
        │   └── ElButton "编辑递增规则" → /contracts/:id/escalation
        │
        ├── ── Tab 3: 押金 ──
        │   ElTabPane(label="押金")
        │   ├── ElDescriptions: 押金总额 | 当前余额 | 状态
        │   ├── ElTable(交易流水): 时间 | 类型 | 金额 | 余额 | 操作人 | 原因
        │   └── ElSpace(操作): [冻结] [冲抵] [退还] [转移]
        │
        ├── ── Tab 4: 子租赁 ── (仅二房东主合同显示)
        │   ElTabPane(label="子租赁")
        │   └── ElTable: 单元 | 终端租客 | 月租金 | 入住状态 | 审核状态
        │
        └── ── Tab 5: 附件 ──
            ElTabPane(label="附件")
            ├── ElTable: 文件名 | 大小 | 上传时间 | 操作(下载/删除)
            └── ElUpload "上传附件"
```

#### uni-app 组件树：

```
contracts/detail.vue
└── scroll-view(scroll-y)
    ├── ── 状态标签 ──
    │   view.status-bar
    │   ├── StatusTag(:status="contract.status")
    │   └── wd-tag {{ contract.property_type }}
    │
    ├── ── 基本信息 ──
    │   wd-cell-group(title="合同信息")
    │   ├── wd-cell(title="合同编号" :value="contract.contract_number")
    │   ├── wd-cell(title="租户" :value="contract.tenant_name")
    │   ├── wd-cell(title="起租日" :value="contract.start_date")
    │   ├── wd-cell(title="到期日" :value="contract.end_date")
    │   ├── wd-cell(title="月租金" :value="'¥' + contract.monthly_rent")
    │   └── wd-cell(title="付款周期" :value="contract.payment_cycle")
    │
    ├── ── 关联单元 ──
    │   wd-cell-group(title="关联单元")
    │   └── wd-cell(v-for="unit in contract.units" is-link @click="toUnit(unit.id)")
    │       ├── title: unit.unit_number
    │       └── label: "{{ unit.area }}m² | ¥{{ unit.unit_price }}/m²/月"
    │
    ├── ── 递增规则 ──
    │   wd-cell-group(title="递增规则")
    │   └── wd-steps(:active="currentPhaseIndex" vertical)
    │       └── wd-step(v-for="phase in phases")
    │
    └── ── 押金概况 ──
        wd-cell-group(title="押金")
        ├── wd-cell(title="押金总额" :value="'¥' + deposit.total")
        └── wd-cell(title="当前余额" :value="'¥' + deposit.balance")
```

### 6.4 合同终止页

**Admin**: `ContractTerminateView.vue`  
**路由**: `/contracts/:contractId/terminate`  
**Store**: `useContractTerminateStore`  
**API**: `POST /api/contracts/:id/terminate`

#### Admin 组件树：

```
ContractTerminateView
└── div
    └── ElForm(:model="form" :rules="rules" label-width="120px")
        ├── ── 合同概要（只读）──
        │   ElDescriptions(border): 合同编号 + 租户 + 起止日期 + 月租金
        │
        ├── ── 终止信息 ──
        │   ElDivider "终止信息"
        │   ├── ElFormItem(label="终止类型")
        │   │   └── ElSelect: "租户提前退租" / "协商提前终止" / "业主单方解约"
        │   ├── ElFormItem(label="终止日期") → ElDatePicker
        │   └── ElFormItem(label="终止原因") → ElInput(type="textarea" :rows="3")
        │
        ├── ── 违约金 & 押金处理 ──
        │   ElDivider "违约金与押金处理"
        │   ├── ElFormItem(label="违约金") → ElInputNumber(prefix="¥")
        │   ├── ElCard(header="押金处理")
        │   │   ├── ElText "当前押金余额: ¥{{ deposit.balance }}"
        │   │   ├── ElFormItem(label="扣除金额") → ElInputNumber
        │   │   └── ElText "预计退还: ¥{{ remainder }}"
        │
        ├── ── 影响预览 ──
        │   ElAlert(type="warning" title="终止影响" :closable="false")
        │   ├── • 将有 X 张未出账账单被自动取消
        │   ├── • 关联单元将恢复为空置状态
        │   ├── • WALE 中该合同剩余租期归零
        │   └── • 递增规则将被关闭
        │
        └── ElButton(type="danger" :loading="submitting") "确认终止"
            └── ElMessageBox.confirm(type: warning, 确认按钮 danger)
```

### 6.5 递增规则配置页

**Admin**: `EscalationConfigView.vue`  
**路由**: `/contracts/:contractId/escalation`  
**Store**: `useEscalationConfigStore`  
**API**: `PUT /api/contracts/:id/escalation-phases`

#### Admin 组件树：

```
EscalationConfigView
└── div
    ├── ── 模板选择 ──
    │   ElButton(icon="CopyDocument") "从模板套用"
    │   └── ElDialog → 模板列表 → 选择 → 自动填入各阶段
    │
    ├── ── 递增阶段列表 ──
    │   div(v-for="(phase, index) in form.phases" :key="phase.id")
    │   └── ElCard
    │       ├── div.phase-header
    │       │   ├── ElText "阶段 {{ index + 1 }}"
    │       │   ├── ElDatePicker(type="daterange" v-model="phase.range")
    │       │   └── ElButton(icon="Delete" circle @click="removePhase(index)")
    │       ├── ElSelect(v-model="phase.type")
    │       │   ├── "固定比例递增" → ElInputNumber(suffix="%")
    │       │   ├── "固定金额递增" → ElInputNumber(prefix="¥" suffix="/m²")
    │       │   ├── "阶梯式递增" → 阶梯表编辑器
    │       │   ├── "CPI 挂钩递增" → ElInputNumber(年份 + 涨幅)
    │       │   ├── "每N年递增" → ElInputNumber(间隔年数 + 涨幅)
    │       │   └── "免租后基准调整" → ElInputNumber(基准价)
    │       └── ElText(type="info") "预计第{{ n }}年月租: ¥{{ estimated }}"
    │
    ├── ElButton(icon="Plus") "添加阶段"
    │
    └── ── 租金预测预览 ── (实时计算)
        ElCard(header="全生命周期租金预测")
        └── ElTable
            ├── ElTableColumn(label="年份")
            ├── ElTableColumn(label="月租金")
            ├── ElTableColumn(label="年化租金")
            └── ElTableColumn(label="较上期涨幅")
```

### 6.6 租客列表页

**Admin**: `TenantListView.vue`  
**路由**: `/tenants`  
**Store**: `useTenantListStore`  
**API**: `GET /api/tenants`

#### Admin 组件树：

```
TenantListView
└── div
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElInput(v-model="keyword" prefix-icon="Search") "搜索: 名称/证件号后4位"
    │   ├── ElSelect(v-model="creditRating") "信用评级: 全部/A/B/C"
    │   ├── ElSelect(v-model="tenantType") "类型: 企业/个人"
    │   └── ElButton(type="primary" icon="Plus") "新建租客" → /tenants/new
    │
    └── ProposTable
        ├── ElTableColumn(label="名称")
        ├── ElTableColumn(label="类型")
        ├── ElTableColumn(label="证件号(脱敏)") "****5678"
        ├── ElTableColumn(label="信用评级") → StatusTag
        ├── ElTableColumn(label="在租合同数")
        └── ElTableColumn(label="联系人") "***1234"
```

### 6.7 租客详情页

**Admin**: `TenantDetailView.vue`  
**路由**: `/tenants/:tenantId`  
**Store**: `useTenantDetailStore`  
**API**: `GET /api/tenants/:id`

#### Admin 组件树：

```
TenantDetailView
└── div
    ├── ── 基本信息 ──
    │   ElDescriptions(border :column="2")
    │   ├── ElDescriptionsItem(label="名称")
    │   ├── ElDescriptionsItem(label="类型")
    │   ├── ElDescriptionsItem(label="证件号") "****5678"
    │   │   └── ElButton(icon="Unlock" link) "查看完整"
    │   │       → 密码二次验证 → POST /api/tenants/:id/unmask
    │   ├── ElDescriptionsItem(label="联系人")
    │   ├── ElDescriptionsItem(label="联系电话") "***1234"
    │   │   └── ElButton(icon="Unlock" link)
    │   └── ElDescriptionsItem(label="信用评级") → StatusTag
    │
    ├── ── 信用评级面板 ── (Should: S-06)
    │   ElCard(header="信用评级详情")
    │   ├── ElDescriptions: 当前评级 | 评级日期
    │   ├── ElText "过去12个月逾期 0 次"
    │   └── ECharts(type: line, 评级历史趋势)
    │
    ├── ── 租赁历史 ──
    │   ElCard(header="租赁历史")
    │   └── ElTable: 合同编号 | 单元 | 起止日期 | 状态
    │
    └── ── 关联工单 ──
        ElCard(header="报修工单")
        └── ElTable(最近工单列表)
```

### 6.8 押金管理（合同详情 Tab 3 集成）

押金管理在合同详情页 Tab 3 中展示，独立操作通过弹窗完成：

**操作弹窗**：

| 操作 | 弹窗类型 | 内容 |
|------|---------|------|
| 冻结 | `ElMessageBox.confirm` | "确认冻结押金？冻结后不可进行冲抵/退还操作" |
| 冲抵 | `ElDialog` | 冲抵金额 + 原因 |
| 退还 | `ElDialog` | 退还金额 + 收款方式 + 银行流水号 |
| 转移 | `ElDialog` | 目标合同选择 |

### 6.9 合同续签页

**Admin**: `ContractRenewView.vue`  
**路由**: `/contracts/:contractId/renew`  
**Store**: `useContractRenewStore`  
**API**: `POST /api/contracts/:id/renew`

#### Admin 组件树：

```
ContractRenewView
└── div
    └── ElForm(:model="form" :rules="rules" label-width="120px")
        ├── ── 原合同信息（只读）──
        │   ElDescriptions(border title="原合同概要")
        │   └── 合同编号 | 租户 | 单元 | 原到期日 | 当前月租
        │
        ├── ── 续签参数 ──
        │   ElDivider "续签条款"
        │   ├── ElFormItem("新起始日") → ElDatePicker(默认=原到期日+1天)
        │   ├── ElFormItem("新到期日") → ElDatePicker
        │   ├── ElFormItem("新月租金(¥)") → ElInputNumber
        │   └── ElFormItem("递增规则") → ElRadioGroup
        │       ├── "延用原合同"
        │       └── "重新配置" → 展开 EscalationConfigWidget
        │
        ├── ── 押金处理 ──
        │   ElDivider "押金处理"
        │   ElRadioGroup(v-model="form.deposit_mode")
        │   ├── ElRadio "原押金自动转入续签合同"
        │   ├── ElRadio "退还原押金 + 重新收取"
        │   └── ElRadio "补差额" → ElInputNumber(差额金额)
        │
        └── ElButton(type="primary" :loading="submitting") "提交续签"
            └── ElMessageBox.confirm("将基于原合同生成新合同，原合同状态变为已续签。")
```

### 6.10 租客新增/编辑页

**Admin**: `TenantFormView.vue`  
**路由**: `/tenants/new` 或 `/tenants/:tenantId/edit`  
**Store**: `useTenantFormStore`  
**API**: `POST /api/tenants` / `PATCH /api/tenants/:id`

#### Admin 组件树：

```
TenantFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ── 基本信息 ──
    │   ElDivider "基本信息"
    │   ├── ElFormItem(label="租客名称" prop="name") → ElInput
    │   ├── ElFormItem(label="类型" prop="type") → ElSelect("企业" / "个人")
    │   └── ElFormItem(label="证件号" prop="id_number") → ElInput
    │       └── ⚠️ 加密存储，API 层脱敏显示
    │
    ├── ── 联系人 ──
    │   ElDivider "联系人"
    │   ├── ElFormItem(label="联系人姓名") → ElInput
    │   ├── ElFormItem(label="联系电话") → ElInput
    │   │   └── ⚠️ 加密存储，API 层脱敏显示
    │   └── ElFormItem(label="邮箱") → ElInput
    │
    ├── ── 开票信息 ──（可选）
    │   ElDivider "开票信息"
    │   ├── ElFormItem(label="开票抬头") → ElInput
    │   ├── ElFormItem(label="税号") → ElInput
    │   ├── ElFormItem(label="开户行") → ElInput
    │   └── ElFormItem(label="银行账号") → ElInput
    │
    └── ElButton(type="primary" :loading="submitting") {{ isEdit ? '保存' : '创建租客' }}
```

---

## 七、财务模块页面

### 7.1 财务概览页

**Admin**: `FinanceView.vue`  
**路由**: `/finance`  
**uni-app**: `pages/finance/index.vue`（TabBar 第 5 Tab）  
**Store**: `useFinanceOverviewStore`  
**API**: `GET /api/noi/summary` + `GET /api/invoices?status=overdue`

#### Admin 组件树：

```
FinanceView
└── div
    ├── ── NOI 汇总卡片 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("本月应收", "¥2,345,678")
    │   ├── MetricCard("本月实收", "¥2,100,000")
    │   ├── MetricCard("收款率", "89.5%")
    │   └── MetricCard("NOI", "¥1,234,567")
    │
    ├── ── 快捷入口 ──
    │   ElRow(:gutter="24")
    │   ├── ActionCard("账单管理" → /finance/invoices)
    │   ├── ActionCard("费用支出" → /finance/expenses)
    │   ├── ActionCard("水电抄表" → /finance/meter-readings)
    │   └── ActionCard("营业额申报" → /finance/turnover-reports)
    │
    ├── ── 逾期账单警示 ──
    │   ElCard(header="逾期账单")
    │   └── ElTable(top 10 逾期账单)
    │       ├── ElTableColumn(label="租户")
    │       ├── ElTableColumn(label="单元")
    │       ├── ElTableColumn(label="费项")
    │       ├── ElTableColumn(label="金额")
    │       └── ElTableColumn(label="逾期天数") → ElText(type="danger")
    │
    └── ── 收款进度 ──
        ElCard(header="本月收款进度")
        └── ElProgress(:percentage="89.5" :stroke-width="20")
```

#### uni-app 组件树：

```
finance/index.vue
└── scroll-view(scroll-y)
    ├── ── 汇总卡片 ──
    │   view.metric-grid
    │   ├── MetricCard("本月应收", "¥2,345,678")
    │   ├── MetricCard("本月实收", "¥2,100,000")
    │   ├── MetricCard("收款率", "89.5%")
    │   └── MetricCard("NOI", "¥1,234,567")
    │
    ├── ── 快捷入口 ──
    │   view.action-grid
    │   ├── ActionCard("账单" → /pages/finance/invoices)
    │   ├── ActionCard("KPI" → /pages/finance/kpi)
    │   └── ActionCard("抄表" → 抄表功能)
    │
    └── ── 逾期提醒 ──
        wd-card(title="逾期账单")
        └── wd-cell(v-for="invoice in overdueList" is-link)
```

### 7.2 账单列表页

**Admin**: `InvoicesView.vue`  
**路由**: `/finance/invoices`  
**uni-app**: `pages/finance/invoices.vue`  
**Store**: `useInvoiceListStore`  
**API**: `GET /api/invoices`

#### Admin 组件树：

```
InvoicesView
└── div
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElSelect "状态: 全部/已出账/已核销/逾期/已作废"
    │   ├── ElSelect "费项: 全部/租金/物管费/水电/分成"
    │   ├── ElSelect "楼栋"
    │   ├── ElSelect "业态"
    │   ├── ElDatePicker(type="daterange") "账期范围"
    │   ├── ElInput "租户名称搜索"
    │   └── ElSpace
    │       ├── ElButton(icon="Download") "导出 Excel"
    │       └── ElButton(type="primary") "手工触发生成"
    │
    └── ProposTable
        ├── ElTableColumn(label="账单号")
        ├── ElTableColumn(label="租户")
        ├── ElTableColumn(label="费项")
        ├── ElTableColumn(label="含税金额")
        ├── ElTableColumn(label="不含税金额")
        ├── ElTableColumn(label="状态") → StatusTag
        ├── ElTableColumn(label="到期日")
        └── ElTableColumn(label="操作")
            ├── ElButton(link) "核销"
            └── ElButton(link type="danger") "作废"
```

### 7.3 账单详情页

**Admin**: `InvoiceDetailView.vue`  
**路由**: `/finance/invoices/:invoiceId`  
**Store**: `useInvoiceDetailStore`  
**API**: `GET /api/invoices/:id` + `GET /api/invoices/:id/items`

#### Admin 组件树：

```
InvoiceDetailView
└── div
    ├── StatusTag(invoice.status)
    │
    ├── ── 账单基本信息 ──
    │   ElDescriptions(border :column="2")
    │   ├── 账单号 | 租户 | 合同 | 账期
    │   ├── 含税金额 | 不含税金额 | 已收金额 | 未收余额
    │   └── 到期日 | 发票状态
    │
    ├── ── 费项明细 ──
    │   ElCard(header="费项明细")
    │   └── ElTable: 费项类型 | 说明 | 金额
    │       Footer: 合计
    │
    ├── ── 核销记录 ──
    │   ElCard(header="收款核销记录")
    │   └── ElTable: 收款日期 | 收款方式 | 核销金额 | 操作人
    │
    └── ── 操作按钮 ──
        ElSpace
        ├── ElButton(type="primary") "录入收款" → /finance/invoices/:id/pay
        ├── ElButton "录入发票号"
        └── ElButton(type="danger") "作废"
```

### 7.4 收款录入页

**Admin**: `PaymentFormView.vue`  
**路由**: `/finance/invoices/:invoiceId/pay`  
**Store**: `usePaymentFormStore`  
**API**: `POST /api/payments`

#### Admin 组件树：

```
PaymentFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ── 收款信息 ──
    │   ├── ElFormItem(label="收款金额") → ElInputNumber(prefix="¥")
    │   ├── ElFormItem(label="到账日期") → ElDatePicker
    │   ├── ElFormItem(label="收款方式") → ElSelect(银行转账/现金/支票/POS)
    │   ├── ElFormItem(label="银行流水号") → ElInput
    │   └── ElFormItem(label="备注") → ElInput
    │
    ├── ── 核销分配 ──
    │   ElCard(header="核销分配")
    │   ├── ElText(type="info") "默认按先到期先核销分配，可手工调整"
    │   └── ElTable(border)
    │       ├── ElTableColumn(label="账单号")
    │       ├── ElTableColumn(label="费项")
    │       ├── ElTableColumn(label="应收")
    │       └── ElTableColumn(label="本次核销") → ElInputNumber(可编辑)
    │       Footer: "本次核销合计: ¥{{ totalAlloc }} | 剩余未分配: ¥{{ remaining }}"
    │
    └── ElButton(type="primary" :loading="submitting") "确认收款"
```

### 7.5 水电抄表录入页

**Admin**: `MeterReadingFormView.vue`  
**路由**: `/finance/meter-readings/new`  
**Store**: `useMeterReadingFormStore`  
**API**: `POST /api/meter-readings`

#### Admin 组件树：

```
MeterReadingFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ElFormItem(label="单元") → ElSelect(filterable remote :remote-method="searchUnits")
    ├── ElFormItem(label="表计类型") → ElSelect(水表/电表/燃气表)
    ├── ElFormItem(label="抄表周期") → ElDatePicker(type="month")
    ├── ElRow(:gutter="24")
    │   ├── ElCol(:span="12") → ElFormItem("上期读数") → ElInput(disabled, 自动填充)
    │   └── ElCol(:span="12") → ElFormItem("本期读数") → ElInputNumber
    │
    ├── ── 费用预览 ──
    │   ElCard(header="费用预览")
    │   ├── ElText "用量: {{ current - previous }} 度"
    │   ├── ElText "单价: ¥{{ tier1Price }}/度"
    │   ├── ElText "阶梯部分: {{ excess }} 度 × ¥{{ tier2Price }}"
    │   └── ElStatistic(title="合计费用" :value="total" prefix="¥")
    │
    └── ElButton(type="primary" :loading="submitting") "确认提交"
```

### 7.6 营业额申报管理页

**Admin**: `TurnoverReportListView.vue` / `TurnoverReportDetailView.vue`  
**路由**: `/finance/turnover-reports` / `/finance/turnover-reports/:reportId`  
**Store**: `useTurnoverReportStore`  
**API**: `GET /api/turnover-reports` + `PATCH /api/turnover-reports/:id/approve|reject`

#### 列表页组件树：

```
TurnoverReportListView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "状态: 全部/待审核/已通过/已退回"
    │   └── ElInput "商户搜索"
    │
    └── ProposTable
        ├── ElTableColumn(label="申报月")
        ├── ElTableColumn(label="商户(合同)")
        ├── ElTableColumn(label="申报营业额")
        ├── ElTableColumn(label="保底租金")
        ├── ElTableColumn(label="分成额")
        ├── ElTableColumn(label="状态") → StatusTag
        └── ElTableColumn(label="操作")
            ├── ElButton(link type="success") "通过"
            └── ElButton(link type="danger") "退回"
```

#### 详情页组件树：

```
TurnoverReportDetailView
└── div
    ├── ElDescriptions(border title="申报信息")
    │   ├── 合同 | 申报月 | 申报营业额
    │   ├── 分成比例 | 保底租金
    │   └── 应收 = MAX(保底, 营业额×比例)
    │
    ├── ElCard(header="证明材料")
    │   └── ElTable(附件列表: 文件名 | 大小 | 操作(下载))
    │
    └── ElSpace
        ├── ElButton(type="success") "审核通过" → PATCH /approve
        └── ElButton(type="danger") "退回"
            → ElMessageBox.prompt(title: "退回申报", inputPlaceholder: "退回原因")
            → PATCH /reject
```

### 7.7 费用列表页

**Admin**: `ExpenseListView.vue`  
**路由**: `/finance/expenses`  
**Store**: `useExpenseListStore`  
**API**: `GET /api/expenses`

#### Admin 组件树：

```
ExpenseListView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "费用类型: 全部/物管费/维修费/公共能耗/保险/其他"
    │   ├── ElDatePicker(type="daterange") "费用期间"
    │   ├── ElSelect "楼栋"
    │   └── ElButton(type="primary" icon="Plus") "新增费用" → /finance/expenses/new
    │
    ├── ── 费用汇总 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("本月支出", "¥128,500", trend: "+3.2%")
    │   ├── MetricCard("本年累计", "¥1,542,000")
    │   └── MetricCard("OpEx 占比", "34.2%")
    │
    └── ProposTable
        ├── ElTableColumn(label="费用编号")
        ├── ElTableColumn(label="类型")
        ├── ElTableColumn(label="金额")
        ├── ElTableColumn(label="归属楼栋")
        ├── ElTableColumn(label="发生日期")
        ├── ElTableColumn(label="录入人")
        └── ElTableColumn(label="操作") [编辑] [作废]
```

### 7.8 费用录入页

**Admin**: `ExpenseFormView.vue`  
**路由**: `/finance/expenses/new` 或 `/finance/expenses/:expenseId/edit`  
**Store**: `useExpenseFormStore`  
**API**: `POST /api/expenses` / `PATCH /api/expenses/:id`

#### Admin 组件树：

```
ExpenseFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ElFormItem(label="费用类型") → ElSelect("物管费" / "维修费" / "公共能耗" / "保险" / "税费" / "其他")
    ├── ElFormItem(label="金额") → ElInputNumber(prefix="¥")
    ├── ElFormItem(label="发生日期") → ElDatePicker
    ├── ElFormItem(label="归属楼栋") → ElSelect
    ├── ElFormItem(label="供应商/对方") → ElInput
    ├── ElFormItem(label="摘要") → ElInput(type="textarea" :rows="3")
    ├── ElFormItem(label="凭证附件")
    │   └── ElUpload(accept=".pdf,.jpg,.png" :limit="5")
    └── ElButton(type="primary" :loading="submitting") {{ isEdit ? '保存' : '提交费用' }}
```

### 7.9 水电抄表列表页

**Admin**: `MeterReadingListView.vue`  
**路由**: `/finance/meter-readings`  
**Store**: `useMeterReadingListStore`  
**API**: `GET /api/meter-readings`

#### Admin 组件树：

```
MeterReadingListView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "类型: 全部/电表/水表"
    │   ├── ElSelect "楼栋"
    │   ├── ElDatePicker(type="daterange") "抄表日期"
    │   ├── ElInput "单元搜索"
    │   └── ElButton(type="primary" icon="Plus") "新增抄表" → /finance/meter-readings/new
    │
    └── ProposTable
        ├── ElTableColumn(label="抄表日期")
        ├── ElTableColumn(label="单元")
        ├── ElTableColumn(label="表类型")
        ├── ElTableColumn(label="上期读数")
        ├── ElTableColumn(label="本期读数")
        ├── ElTableColumn(label="用量")
        ├── ElTableColumn(label="费用")
        ├── ElTableColumn(label="账单状态") → StatusTag
        └── ElTableColumn(label="操作") [详情] [编辑](仅未生成账单时)
```

---

## 八、工单模块页面

### 8.1 工单列表页

**Admin**: `WorkordersView.vue`  
**路由**: `/workorders`  
**uni-app**: `pages/workorders/index.vue`（TabBar 第 4 Tab）  
**Store**: `useWorkOrderListStore`  
**API**: `GET /api/workorders`

#### Admin 组件树：

```
WorkordersView
└── div
    ├── ElForm(inline)
    │   ├── ElRadioGroup(v-model="filters.status" size="small")
    │   │   ├── ElRadioButton "全部"
    │   │   ├── ElRadioButton "已提交"
    │   │   ├── ElRadioButton "处理中"
    │   │   ├── ElRadioButton "待验收"
    │   │   ├── ElRadioButton "已完成"
    │   │   └── ElRadioButton "挂起"
    │   ├── ElInput "搜索: 工单号/描述"
    │   └── ElButton(type="primary" icon="Plus") "新建工单" → /workorders/new
    │
    └── ProposTable
        ├── ElTableColumn(label="工单编号")
        ├── ElTableColumn(label="问题描述")
        ├── ElTableColumn(label="位置") "{{ building }} {{ floor }} {{ unit }}"
        ├── ElTableColumn(label="类型")
        ├── ElTableColumn(label="优先级") → ElTag(:type="priorityType")
        ├── ElTableColumn(label="状态") → StatusTag
        ├── ElTableColumn(label="处理人")
        ├── ElTableColumn(label="提报时间")
        └── ElTableColumn(label="操作") → ElButton(link) "查看"
```

#### uni-app 组件树：

```
workorders/index.vue
└── view
    ├── ── 状态筛选标签栏 ──
    │   scroll-view(scroll-x)
    │   └── wd-tag(v-for="status in statusOptions" :type="selected === status ? 'primary' : 'default'"
    │           @click="filterByStatus(status)")
    │
    ├── ── 工单列表 ──
    │   scroll-view(scroll-y @scrolltolower="loadMore")
    │   └── wd-card(v-for="order in list" @click="toDetail(order.id)")
    │       ├── view.card-header
    │       │   ├── text.title {{ order.title }}
    │       │   ├── StatusTag(:status="order.status")
    │       │   └── wd-tag(:type="priorityType") {{ order.priority }}
    │       ├── text.location {{ order.building }} {{ order.floor }} {{ order.unit }}
    │       └── view.card-footer
    │           ├── text "提报: {{ order.submitter }}"
    │           └── text {{ timeAgo(order.submitted_at) }}
    │
    └── ── FAB 报修按钮 ──
        view.fab(@click="onNewOrder")
        └── wd-icon(name="plus")
```

**FAB 点击逻辑**（uni-app）：

```typescript
async function onNewOrder() {
  // #ifdef APP-PLUS
  // 弹出选择：[扫码报修] / [手动填报]
  uni.showActionSheet({
    itemList: ['扫码报修', '手动填报'],
    success(res) {
      if (res.tapIndex === 0) {
        uni.scanCode({ success(res) { /* 解析 unit_id → 带参数跳转 */ } })
      } else {
        uni.navigateTo({ url: '/pages/workorders/new' })
      }
    },
  })
  // #endif
  // #ifdef MP-WEIXIN
  wx.scanCode({ success(res) { /* ... */ } })
  // #endif
}
```

### 8.2 工单提报页

**Admin**: `WorkorderFormView.vue`  
**路由**: `/workorders/new`  
**uni-app**: `pages/workorders/new.vue`  
**Store**: `useWorkOrderFormStore`  
**API**: `POST /api/workorders`

#### Admin 组件树：

```
WorkorderFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ── 位置选择（级联）──
    │   ElFormItem(label="楼栋") → ElSelect(v-model="form.building_id")
    │   ElFormItem(label="楼层") → ElSelect(v-model="form.floor_id" :disabled="!form.building_id")
    │   ElFormItem(label="单元") → ElSelect(v-model="form.unit_id" :disabled="!form.floor_id")
    │
    ├── ElFormItem(label="问题描述") → ElInput(type="textarea" :rows="5")
    ├── ElFormItem(label="问题类型") → ElSelect(水电/空调/门窗/网络/保洁/其他)
    ├── ElFormItem(label="紧急程度") → ElRadioGroup(一般/紧急/非常紧急)
    │
    ├── ElFormItem(label="现场照片")
    │   └── ElUpload(:list-type="picture-card" accept="image/*" :limit="5")
    │
    └── ElButton(type="primary" :loading="submitting") "提交工单"
```

#### uni-app 组件树：

```
workorders/new.vue
└── scroll-view(scroll-y)
    └── wd-form(ref="formRef" :model="form")
        ├── ── 位置选择 ──
        │   wd-picker(label="楼栋" :columns="buildings" v-model="form.building_id")
        │   wd-picker(label="楼层" :columns="floors" v-model="form.floor_id")
        │   wd-picker(label="单元" :columns="units" v-model="form.unit_id")
        │   // 扫码场景: 以上三项已预填，只读显示
        │
        ├── wd-textarea(label="问题描述" v-model="form.description" :maxlength="500")
        ├── wd-picker(label="问题类型" :columns="categories" v-model="form.category")
        ├── wd-radio-group(label="紧急程度" v-model="form.priority")
        │
        ├── ── 照片上传 ──
        │   wd-upload(v-model:file-list="form.photos" :limit="5" accept="image")
        │
        └── wd-button(type="primary" block :loading="submitting") "提交工单"
```

### 8.3 工单详情页

**Admin**: `WorkorderDetailView.vue`  
**路由**: `/workorders/:orderId`  
**uni-app**: `pages/workorders/detail.vue`  
**Store**: `useWorkOrderDetailStore`  
**API**: `GET /api/workorders/:id`

#### Admin 组件树：

```
WorkorderDetailView
└── div
    ├── ── 状态 & 优先级 ──
    │   ElSpace: StatusTag(status) + ElTag(:type="priorityType") {{ priority }}
    │
    ├── ── 基本信息 ──
    │   ElDescriptions(border :column="2")
    │   ├── 工单编号 | 位置 | 问题类型 | 提报人
    │   ├── 提报时间 | 处理人 | 预计完成 | SLA 状态
    │
    ├── ── 问题描述 ──
    │   ElCard: ElText(order.description)
    │
    ├── ── 照片 ──
    │   ElCard(header="现场照片")
    │   └── ElImage(v-for="photo in photos" :src="photo" :preview-src-list="photos" fit="cover")
    │
    ├── ── 维修成本 ── (completed 状态显示)
    │   ElDescriptions(border title="维修成本")
    │   ├── 材料费 | 人工费 | 合计 | 归口
    │
    ├── ── 操作时间线 ──
    │   ElCard(header="操作记录")
    │   └── ElTimeline
    │       └── ElTimelineItem(v-for="log in logs" :timestamp="log.time")
    │           {{ log.description }}
    │
    └── ── 操作按钮 ── (根据状态动态显示)
        ElSpace
        ├── v-if="status === 'submitted'": ElButton(type="primary") "审核派单"
        ├── v-if="status === 'approved'": ElButton(type="primary") "开始处理"
        ├── v-if="status === 'in_progress'": ElButton(type="primary") "提交完工"
        ├── v-if="status === 'pending_inspection'": ElButton(type="success") "验收通过" / ElButton(type="warning") "返工"
        └── v-if="status === 'completed'": ElButton "重开工单"(7 天内)
```

**审核派单弹窗**（Admin）：

```
ElDialog(title="审核派单" v-model="assignDialogVisible")
├── ElForm
│   ├── ElFormItem(label="指派处理人") → ElSelect(filterable)
│   └── ElFormItem(label="预计完成") → ElDateTimePicker
└── ElButton(type="primary" :loading) "确认派单"
    → PATCH /api/workorders/:id/approve { assignee_id, estimated_completion }
```

#### uni-app 组件树：

```
workorders/detail.vue
└── scroll-view(scroll-y)
    ├── ── 状态/优先级 ──
    │   view.status-bar
    │   ├── StatusTag(:status="order.status")
    │   └── wd-tag(:type="priorityType") {{ order.priority }}
    │
    ├── ── 基本信息 ──
    │   wd-cell-group(title="工单信息")
    │   ├── wd-cell(title="工单编号" :value="order.order_number")
    │   ├── wd-cell(title="位置" :value="locationText")
    │   ├── wd-cell(title="问题类型" :value="order.category")
    │   ├── wd-cell(title="提报人" :value="order.submitter")
    │   └── wd-cell(title="处理人" :value="order.assignee")
    │
    ├── ── 问题描述 ──
    │   wd-card(title="问题描述")
    │   └── text {{ order.description }}
    │
    ├── ── 照片 ──
    │   wd-card(title="现场照片")
    │   └── view.photo-grid
    │       └── image(v-for="photo in photos" :src="photo" @click="previewImage")
    │
    ├── ── 操作时间线 ──
    │   wd-card(title="操作记录")
    │   └── wd-steps(vertical :active="logs.length - 1")
    │       └── wd-step(v-for="log in logs" :title="log.description" :description="log.time")
    │
    └── ── 操作按钮 ──
        view.action-bar(fixed bottom)
        // 根据 status 动态显示对应操作按钮
```

### 8.4 扫码报修

> uni-app 移动端通过 `uni.scanCode` 原生 API 实现，不需要独立页面。  
> 微信小程序通过 `wx.scanCode` 实现。  
> Admin PC 端不支持扫码，降级为手动选择楼栋/楼层/单元。

**扫码流程**：

```
uni.scanCode() → 解析 QR 码中的 unit_id
  → GET /api/units/by-qr/:qrCode
  ├── 成功 → uni.navigateTo({ url: '/pages/workorders/new?unit_id=xxx&building_id=xxx&floor_id=xxx' })
  └── 失败 → showToast('无法识别二维码，请重试或手动输入')
```

---

## 九、二房东门户模块页面

> 二房东门户独立于主导航骨架，使用精简布局，仅二房东角色可访问。

### 9.1 二房东管理列表（内部管理视角）

**Admin**: `SubleasesView.vue`  
**路由**: `/subleases`  
**uni-app**: `pages/subleases/index.vue`  
**Store**: `useSubleaseListStore`  
**API**: `GET /api/subleases` + `GET /api/sublease-portal/units`

#### Admin 组件树：

```
SubleasesView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "审核状态: 全部/待审核/已通过/已退回"
    │   ├── ElSelect "二房东(主合同)"
    │   └── ElInput "搜索: 单元编号/终端租客"
    │
    └── ProposTable
        ├── ElTableColumn(label="单元")
        ├── ElTableColumn(label="二房东(主合同)")
        ├── ElTableColumn(label="终端租客")
        ├── ElTableColumn(label="月租金")
        ├── ElTableColumn(label="入住状态")
        ├── ElTableColumn(label="审核状态") → StatusTag
        └── ElTableColumn(label="操作")
            ├── ElButton(link type="success") "通过"
            └── ElButton(link type="danger") "退回"
```

### 9.2 单元填报列表页（二房东视角）

**外部 Web 页面**（二房东登录后看到的首页）  
**Store**: `useSubLandlordUnitListStore`  
**API**: `GET /api/sublease-portal/units` + `GET /api/sublease-portal/subleases`

#### 组件树：

```
SubLandlordPortalLayout
├── Header: Logo + "PropOS 二房东平台" + 退出登录
└── Main
    ├── ── 填报进度卡片 ──
    │   ElCard
    │   ├── ElText "填报截止日: 本月5日"
    │   ├── ElProgress(:percentage="filledPercent" :stroke-width="20")
    │   └── ElText "已填报 45/60 个单元"
    │
    ├── ── 筛选 ──
    │   ElForm(inline)
    │   ├── ElSelect "填报状态: 全部/已填报/未填报/退回待修改"
    │   └── ElInput "搜索单元编号"
    │
    └── ElTable(:data="units" @row-click="toFill")
        ├── ElTableColumn(label="单元编号")
        ├── ElTableColumn(label="面积(m²)")
        ├── ElTableColumn(label="填报状态") → StatusTag
        ├── ElTableColumn(label="审核状态") → StatusTag
        └── ElTableColumn(label="操作") → ElButton(link) "填报"
```

### 9.3 子租赁填报页

**Store**: `useSubleaseFillingStore`  
**API**: `POST|PATCH /api/sublease-portal/subleases`

#### 组件树：

```
SubleaseFillingView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ── 单元信息(只读) ──
    │   ElDescriptions(border): 单元编号 | 面积 | 主合同到期日
    │
    ├── ── 入住状态 ──
    │   ElFormItem(label="入住状态") → ElSelect(已入住/已签约未入住/已退租/空置)
    │
    ├── ── 租客信息 ── (v-if 非空置)
    │   ElDivider "终端租客信息"
    │   ├── ElFormItem("名称") → ElInput
    │   ├── ElFormItem("类型") → ElSelect(企业/个人)
    │   ├── ElFormItem("联系人") → ElInput
    │   ├── ElFormItem("联系电话") → ElInput
    │   └── ElFormItem("证件号") → ElInput (可选)
    │
    ├── ── 租赁信息 ──
    │   ElDivider "租赁信息"
    │   ├── ElFormItem("起租日") → ElDatePicker
    │   ├── ElFormItem("到期日") → ElDatePicker(:disabled-date="afterMainContractEnd")
    │   ├── ElFormItem("月租金(¥)") → ElInputNumber
    │   ├── ElText(type="info") "自动计算单价: ¥{{ rent / area }}/m²/月"
    │   └── ElFormItem("入住人数") // v-if 公寓
    │
    ├── ElFormItem("备注") → ElInput(type="textarea")
    │
    ├── ── 审核退回面板 ── (v-if="form.review_status === 'rejected'")
    │   ElAlert(type="error" title="审核退回原因" :closable="false")
    │   └── {{ form.reject_reason }}
    │
    └── ElSpace
        ├── ElButton "暂存草稿" (review_status = draft)
        └── ElButton(type="primary") "提交审核" (review_status = pending)
            → ElMessageBox.confirm("提交后数据将进入审核流程")
```

### 9.4 批量导入页

**Store**: `useSubleaseImportStore`  
**API**: `POST /api/sublease-portal/subleases/import`

#### 组件树：

```
SubleaseImportView
└── div
    ├── ElButton(icon="Download") "下载导入模板"
    ├── ElUpload(:auto-upload="false" accept=".xlsx" :limit="1")
    ├── ElButton(type="primary" :loading="importing") "开始导入"
    └── ElCard(v-if="result" header="导入结果")
        ├── ElAlert(:type="result.errors.length ? 'warning' : 'success'")
        │   "成功: {{ result.success }} 条 | 失败: {{ result.errors.length }} 条"
        └── ElTable(v-if="result.errors.length" :data="result.errors")
            ├── ElTableColumn(label="行号")
            ├── ElTableColumn(label="字段")
            └── ElTableColumn(label="原因")
```

---

## 十、系统设置模块页面

> 系统设置仅 Admin 端提供，uni-app 端不包含设置页面。

### 10.1 设置侧边栏

设置页面通过侧边栏 ElMenu 的 "系统设置" 子菜单进入，无独立设置首页。

### 10.2 用户管理页

**Admin**: `UserManagementView.vue`  
**路由**: `/settings/users`  
**Store**: `useUserManagementStore`  
**API**: `GET /api/users`

#### 组件树：

```
UserManagementView
└── div
    ├── ElButton(type="primary" icon="Plus") "新建用户" → /settings/users/new
    └── ProposTable
        ├── ElTableColumn(label="姓名")
        ├── ElTableColumn(label="邮箱")
        ├── ElTableColumn(label="角色") → ElTag
        ├── ElTableColumn(label="部门")
        ├── ElTableColumn(label="状态") → StatusTag
        ├── ElTableColumn(label="上次登录")
        └── ElTableColumn(label="操作")
            └── ElDropdown: [编辑] [启/停用] [变更角色] [变更部门]
```

### 10.3 用户新建/编辑页

**Admin**: `UserFormView.vue`  
**路由**: `/settings/users/new` 或 `/settings/users/:userId/edit`  
**Store**: `useUserFormStore`  
**API**: `POST /api/users` / `PATCH /api/users/:id`

> 仅 `super_admin` 可创建用户；`ops_manager` 可编辑同组织下用户。

#### 组件树：

```
UserFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ElDivider "基本信息"
    ├── ElFormItem(label="姓名") → ElInput
    ├── ElFormItem(label="邮箱") → ElInput
    ├── ElFormItem(label="手机号") → ElInput
    │
    ├── ElDivider "角色与权限"
    ├── ElFormItem(label="角色") → ElSelect
    │   options: super_admin / ops_manager / leasing_specialist / finance / frontline / sub_landlord
    ├── ElFormItem(label="所属部门") → ElTreeSelect(:data="departments")
    │
    ├── ElDivider "初始密码" (v-if="!isEdit")
    ├── ElFormItem(label="初始密码") → ElInput(type="password" show-password)
    ├── ElCheckbox(disabled modelValue) "首次登录强制修改密码"
    │
    └── ElButton(type="primary" :loading="submitting") {{ isEdit ? '保存' : '创建用户' }}
```

### 10.4 组织架构管理页

**Admin**: `OrganizationManageView.vue`  
**路由**: `/settings/org`  
**Store**: `useOrganizationStore`  
**API**: `GET /api/departments` + `GET/PUT /api/managed-scopes`

#### 组件树：

```
OrganizationManageView
└── div.org-layout(display: flex)
    ├── ── 左侧: 部门树 ── (width: 320px)
    │   ElCard(header="部门架构")
    │   ├── ElButton(icon="Plus" size="small") "新建部门"
    │   └── ElTree(:data="departments" node-key="id" @node-click="onNodeClick"
    │            :props="{ label: 'name', children: 'children' }")
    │       └── #default="{ node, data }"
    │           ├── span {{ data.name }}
    │           ├── ElBadge(:value="data.member_count")
    │           └── ElDropdown: [编辑] [新建子部门] [停用]
    │
    └── ── 右侧: 部门详情 & 管辖范围 ── (flex: 1)
        div(v-if="selectedDept")
        ├── ElDescriptions(border title="部门信息")
        │   └── 名称 | 层级 | 上级部门 | 状态
        │
        ├── ElCard(header="管辖范围配置")
        │   ├── ElText "默认管辖范围（适用于部门下所有员工）"
        │   ├── ElCheckboxGroup "楼栋: [A座] [商铺区] [公寓楼]"
        │   ├── ElCheckboxGroup "业态: [写字楼] [商铺] [公寓]"
        │   └── ElButton(type="primary") "保存范围"
        │
        └── ElCard(header="部门员工")
            └── ElTable: 姓名 | 角色 | 个人范围覆盖 → [编辑个人范围]
```

### 10.5 KPI 方案管理页

**Admin**: `KpiSchemeListView.vue` / `KpiSchemeFormView.vue`  
**路由**: `/settings/kpi/schemes` / `/settings/kpi/schemes/new`  
**Store**: `useKpiSchemeManageStore`  
**API**: `GET/POST /api/kpi/schemes`

#### 列表页：

```
KpiSchemeListView
└── div
    ├── ElButton(type="primary" icon="Plus") "新建方案"
    └── ProposTable
        ├── ElTableColumn(label="方案名称")
        ├── ElTableColumn(label="评估周期")
        ├── ElTableColumn(label="指标数")
        ├── ElTableColumn(label="绑定对象数")
        ├── ElTableColumn(label="有效期")
        └── ElTableColumn(label="操作") → ElButton(link) "编辑"
```

#### 表单页（步骤式）：

```
KpiSchemeFormView
└── div
    └── ElSteps(:active="currentStep" align-center)
        ├── ElStep(title="基本信息")
        │   ├── ElFormItem("方案名称") → ElInput
        │   ├── ElFormItem("评估周期") → ElSelect(月度/季度/年度)
        │   └── ElFormItem("有效期") → ElDatePicker(type="daterange")
        │
        ├── ElStep(title="指标配置")
        │   └── ElTable(border)
        │       ├── ElTableColumn(type="selection")
        │       ├── ElTableColumn(label="指标编号")
        │       ├── ElTableColumn(label="名称")
        │       ├── ElTableColumn(label="方向")
        │       ├── ElTableColumn(label="权重(%)") → ElInputNumber
        │       ├── ElTableColumn(label="满分标准") → ElInput
        │       └── ElTableColumn(label="及格标准") → ElInput
        │       Footer: 权重合计: {{ sum }}% (必须=100%)
        │
        └── ElStep(title="绑定对象")
            ├── ElRadioGroup: [按部门] / [按员工]
            └── ElCheckboxGroup / ElTransfer(部门/员工列表)
```

### 10.6 预警中心

**Admin**: `AlertCenterView.vue`  
**路由**: `/settings/alerts`  
**Store**: `useAlertCenterStore`  
**API**: `GET /api/alerts`

#### 组件树：

```
AlertCenterView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "类型: 全部/到期预警/逾期预警/押金提醒/填报提醒"
    │   ├── ElSelect "状态: 全部/未读/已读"
    │   ├── ElDatePicker(type="daterange")
    │   ├── ElButton "全部已读"
    │   └── ElButton "补发预警"
    │
    └── ElTable(:data="alerts" @row-click="onAlertClick")
        ├── ElTableColumn(label="")
        │   └── ElBadge(is-dot :hidden="alert.is_read")
        ├── ElTableColumn(label="类型") → ElTag(:type="alertTypeMap[type]")
        ├── ElTableColumn(label="内容")
        ├── ElTableColumn(label="关联资源")
        └── ElTableColumn(label="时间")
```

### 10.7 递增模板管理页

**Admin**: `EscalationTemplateListView.vue`  
**路由**: `/settings/escalation/templates`  
**Store**: `useEscalationTemplateStore`  
**API**: `GET /api/escalation-templates`

#### 组件树：

```
EscalationTemplateListView
└── div
    ├── ElButton(type="primary" icon="Plus") "新建模板"
    └── ProposTable
        ├── ElTableColumn(label="模板名称")
        ├── ElTableColumn(label="业态") → ElTag
        ├── ElTableColumn(label="阶段数")
        ├── ElTableColumn(label="创建时间")
        ├── ElTableColumn(label="状态") → StatusTag
        └── ElTableColumn(label="操作") [编辑] [停用] [复制]
```

### 10.8 KPI 申诉页

**Admin**: `KpiAppealView.vue`  
**路由**: `/settings/kpi/appeal`  
**Store**: `useKpiAppealStore`  
**API**: `POST /api/kpi/appeals` / `PATCH /api/kpi/appeals/:id/review`

#### 申诉提交表单（员工视角）：

```
div(v-if="role !== 'ops_manager'")
└── ElForm
    ├── ElDescriptions(border title="快照信息")
    │   └── 方案名称 | 周期 | 总分 | 冻结时间
    ├── ElFormItem("申诉指标") → ElSelect
    ├── ElFormItem("申诉理由") → ElInput(type="textarea" :rows="5")
    ├── ElFormItem("证明材料") → ElUpload
    ├── ElText(type="warning") "申诉窗口剩余: {{ days }} 天"
    └── ElButton(type="primary") "提交申诉"
```

#### 申诉审核页（管理层视角）：

```
div(v-if="role === 'ops_manager' || role === 'super_admin'")
└── ProposTable
    ├── ElTableColumn(label="员工")
    ├── ElTableColumn(label="方案")
    ├── ElTableColumn(label="周期")
    ├── ElTableColumn(label="申诉指标")
    ├── ElTableColumn(label="状态") → StatusTag
    └── ElTableColumn(label="操作")
        └── ElExpandRow → 申诉理由 + 证明材料
            ElSpace
            ├── ElButton(type="success") "批准重算"
            └── ElButton(type="danger") "驳回"
```

### 10.9 审计日志页

**Admin**: `AuditLogView.vue`  
**路由**: `/settings/audit-logs`  
**Store**: `useAuditLogStore`  
**API**: `GET /api/audit-logs`

#### 组件树：

```
AuditLogView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "操作类型: 全部/合同变更/账单核销/权限变更/二房东数据提交"
    │   ├── ElInput "操作人搜索"
    │   └── ElDatePicker(type="daterange")
    │
    └── ProposTable
        ├── ElTableColumn(label="时间")
        ├── ElTableColumn(label="操作人")
        ├── ElTableColumn(label="操作类型") → ElTag
        ├── ElTableColumn(label="资源")
        ├── ElTableColumn(label="描述")
        └── ElTableColumn(label="IP")
```

---

## 十一、响应式断点与布局策略

### 11.1 双端布局策略

由于 uni-app 和 Admin 是独立项目，响应式策略分开制定：

#### Admin（PC Web）：

| 断点 | 宽度范围 | 侧边栏 | 布局列数 |
|------|---------|--------|---------|
| **小屏** | < 768px | 折叠至 64px | 1 列 |
| **中屏** | 768~1199px | 折叠至 64px | 2 列 |
| **大屏** | ≥ 1200px | 展开 240px | 2~4 列 |

#### uni-app（移动端）：

| 平台 | 布局 | 导航 |
|------|------|------|
| iOS / Android / HarmonyOS | 全屏单列 | TabBar + 页面栈 |
| 微信小程序 | 全屏单列 | TabBar + 页面栈 |

### 11.2 Admin 组件响应策略

| 组件 | 小屏 (< 768px) | 大屏 (≥ 1200px) |
|------|----------------|-----------------|
| `MetricCard` 行 | 2列 ElRow | 4列 ElRow |
| `ElTable` | 横向滚动 | 全列展示 |
| 表单 | 单列 | 双列 ElRow |
| Tab | 可横向滚动 | 全部可见 |
| 图表 | 宽高自适应 | 固定高度 |
| 楼层图 | 全屏查看 | 左侧列表 + 右侧图 |
| 组织架构 | 单面板（切换） | 双面板（左树右详情） |

### 11.3 平台能力降级策略

| 功能 | iOS/Android/HarmonyOS | 微信小程序 | Admin PC |
|------|:---------------------:|:--------:|:--------:|
| QR 扫码报修 | ✅ `uni.scanCode` | ✅ `wx.scanCode` | ❌ → 手动填报 |
| 推送通知 | ✅ uni-push | ✅ 模板消息 | ❌ → 轮询 |
| 相机拍照 | ✅ `uni.chooseImage` | ✅ | ❌ → 文件选择 |
| 文件选取/导入 | ✅ | ⚠️ 受限 | ✅ |
| Excel 批量导入 | ❌ → Admin 操作 | ❌ → Admin 操作 | ✅ |
| SVG 热区图 | ✅ WebView | ⚠️ canvas | ✅ v-html |

---

## 十二、状态色语义映射速查

### 12.0 双端色彩体系

#### Admin（Element Plus 内置 type）：

| type | 色系 | 语义 |
|------|------|------|
| `success` | 绿色 `--el-color-success` | 已租/已核销/已通过/已完成 |
| `warning` | 黄/橙色 `--el-color-warning` | 即将到期/预警/待审核 |
| `danger` | 红色 `--el-color-danger` | 空置/逾期/错误/已拒绝 |
| `info` | 灰色 `--el-color-info` | 非可租/已作废/已停用 |
| `primary` | 蓝色 `--el-color-primary` | 执行中/处理中/草稿 |

#### uni-app（wot-design-uni type）：

| type | 色系 | 语义 |
|------|------|------|
| `success` | 绿色 | 已租/已核销/已通过/已完成 |
| `warning` | 黄/橙色 | 即将到期/预警/待审核 |
| `danger` | 红色 | 空置/逾期/错误/已拒绝 |
| `default` | 灰色 | 非可租/已作废/已停用 |
| `primary` | 蓝色 | 执行中/处理中/草稿 |

### 12.1 通用状态色

| 状态语义 | Admin ElTag type | uni-app wd-tag type | 适用场景 |
|---------|-----------------|---------------------|---------|
| 已租/已核销/已通过/已完成 | `success` | `success` | 单元已租、账单已核销、审核通过、工单完成 |
| 即将到期/预警/待审核 | `warning` | `warning` | 合同即将到期、逾期预警、待审核 |
| 空置/逾期/错误/已拒绝 | `danger` | `danger` | 单元空置、账单逾期、审核退回 |
| 非可租/已作废/已停用 | `info` | `default` | 非可租单元、作废账单、停用 |
| 执行中/处理中/草稿 | `primary` | `primary` | 合同执行中、工单处理中、草稿 |

### 12.2 合同状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `quoting` | `primary` | `primary` | 报价中 |
| `pending_sign` | `warning` | `warning` | 待签约 |
| `active` | `success` | `success` | 执行中 |
| `expiring_soon` | `warning` | `warning` | 即将到期 |
| `expired` | `info` | `default` | 已到期 |
| `renewed` | `success` | `success` | 已续签 |
| `terminated` | `danger` | `danger` | 已终止 |

### 12.3 账单状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `draft` | `primary` | `primary` | 草稿 |
| `issued` | `warning` | `warning` | 已出账 |
| `paid` | `success` | `success` | 已核销 |
| `overdue` | `danger` | `danger` | 逾期 |
| `cancelled` | `info` | `default` | 已作废 |
| `exempt` | `info` | `default` | 免租免单 |

### 12.4 工单状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `submitted` | `primary` | `primary` | 已提交 |
| `approved` | `warning` | `warning` | 已派单 |
| `in_progress` | `primary` | `primary` | 处理中 |
| `pending_inspection` | `warning` | `warning` | 待验收 |
| `completed` | `success` | `success` | 已完成 |
| `rejected` | `danger` | `danger` | 已拒绝 |
| `on_hold` | `info` | `default` | 挂起 |

### 12.5 信用评级色映射

| 评级 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| A | `success` | `success` | A 优质 |
| B | `warning` | `warning` | B 一般 |
| C | `danger` | `danger` | C 风险 |

---

## 附录 A：页面清单与模块映射

### A.1 uni-app 页面清单（16 个页面）

| 页面 | 路径 | 模块 | TabBar |
|------|------|------|:------:|
| 登录 | `pages/auth/login` | 认证 | — |
| 总览 | `pages/dashboard/index` | 概览 | ✅ Tab 1 |
| 资产总览 | `pages/assets/index` | 资产 | ✅ Tab 2 |
| 楼栋详情 | `pages/assets/building-detail` | 资产 | — |
| 楼层热区图 | `pages/assets/floor-plan` | 资产 | — |
| 房源详情 | `pages/assets/unit-detail` | 资产 | — |
| 合同管理 | `pages/contracts/index` | 租务 | ✅ Tab 3 |
| 合同详情 | `pages/contracts/detail` | 租务 | — |
| 财务总览 | `pages/finance/index` | 财务 | ✅ Tab 5 |
| 发票账单 | `pages/finance/invoices` | 财务 | — |
| KPI 考核 | `pages/finance/kpi` | KPI | — |
| 工单管理 | `pages/workorders/index` | 工单 | ✅ Tab 4 |
| 工单详情 | `pages/workorders/detail` | 工单 | — |
| 新建工单 | `pages/workorders/new` | 工单 | — |
| 二房东管理 | `pages/subleases/index` | 二房东 | — |
| 二房东详情 | `pages/subleases/detail` | 二房东 | — |

### A.2 Admin 视图清单（40+ 视图）

| 视图 | 路由 | 模块 | 优先级 |
|------|------|------|--------|
| `LoginView` | `/login` | 认证 | Must |
| `DashboardView` | `/dashboard` | 概览 | Must |
| `NoiDetailView` | `/dashboard/noi-detail` | 概览 | Must |
| `WaleDetailView` | `/dashboard/wale-detail` | 概览 | Must |
| `AssetsView` | `/assets` | 资产 | Must |
| `BuildingDetailView` | `/assets/buildings/:id` | 资产 | Must |
| `FloorPlanView` | `/assets/buildings/:bid/floors/:fid` | 资产 | Must |
| `UnitDetailView` | `/assets/units/:id` | 资产 | Must |
| `UnitImportView` | `/assets/import` | 资产 | Must |
| `ContractsView` | `/contracts` | 租务 | Must |
| `ContractFormView` | `/contracts/new` | 租务 | Must |
| `ContractDetailView` | `/contracts/:id` | 租务 | Must |
| `ContractTerminateView` | `/contracts/:id/terminate` | 租务 | Must |
| `ContractRenewView` | `/contracts/:id/renew` | 租务 | Must |
| `EscalationConfigView` | `/contracts/:id/escalation` | 租务 | Must |
| `TenantListView` | `/tenants` | 租务 | Must |
| `TenantDetailView` | `/tenants/:id` | 租务 | Must |
| `TenantFormView` | `/tenants/new` | 租务 | Must |
| `FinanceView` | `/finance` | 财务 | Must |
| `InvoicesView` | `/finance/invoices` | 财务 | Must |
| `InvoiceDetailView` | `/finance/invoices/:id` | 财务 | Must |
| `PaymentFormView` | `/finance/invoices/:id/pay` | 财务 | Must |
| `ExpenseListView` | `/finance/expenses` | 财务 | Must |
| `ExpenseFormView` | `/finance/expenses/new` | 财务 | Must |
| `MeterReadingListView` | `/finance/meter-readings` | 财务 | Must |
| `MeterReadingFormView` | `/finance/meter-readings/new` | 财务 | Must |
| `TurnoverReportListView` | `/finance/turnover-reports` | 财务 | Must |
| `TurnoverReportDetailView` | `/finance/turnover-reports/:id` | 财务 | Must |
| `KpiView` | `/finance/kpi` | KPI | Must |
| `KpiSchemeDetailView` | `/finance/kpi/scheme/:id` | KPI | Must |
| `WorkordersView` | `/workorders` | 工单 | Must |
| `WorkorderFormView` | `/workorders/new` | 工单 | Must |
| `WorkorderDetailView` | `/workorders/:id` | 工单 | Must |
| `SubleasesView` | `/subleases` | 二房东 | Must |
| `SubleaseDetailView` | `/subleases/:id` | 二房东 | Must |
| `UserManagementView` | `/settings/users` | 设置 | Must |
| `UserFormView` | `/settings/users/new` | 设置 | Must |
| `OrganizationManageView` | `/settings/org` | 设置 | Must |
| `KpiSchemeListView` | `/settings/kpi/schemes` | KPI | Must |
| `KpiSchemeFormView` | `/settings/kpi/schemes/new` | KPI | Must |
| `KpiAppealView` | `/settings/kpi/appeal` | KPI | Must |
| `EscalationTemplateListView` | `/settings/escalation/templates` | 设置 | Must |
| `AlertCenterView` | `/settings/alerts` | 设置 | Must |
| `AuditLogView` | `/settings/audit-logs` | 设置 | Must |

> **总计**: uni-app **16 个页面** + Admin **44 个视图**，覆盖 Phase 1 全部 Must 需求。

---

## 附录 B：Pinia Store 清单

### B.1 通用 Store（app/ 与 admin/ 各自实现）

| Store | 对应页面 | state 核心字段 |
|-------|---------|---------------|
| `useAuthStore` | 登录/注销/改密 | `user / token / role / loading / error` |
| `useDashboardStore` | 总览页 | `metrics / alerts / loading / error` |
| `useAssetOverviewStore` | 资产概览 | `buildings / typeStats / loading / error` |
| `useBuildingDetailStore` | 楼栋详情 | `building / floors / loading / error` |
| `useFloorMapStore` | 楼层图 | `svg / heatmap / selectedUnit / loading / error` |
| `useUnitDetailStore` | 房源详情 | `unit / renovations / loading / error` |
| `useContractListStore` | 合同列表 | `list / meta / filters / loading / error` |
| `useContractDetailStore` | 合同详情 | `contract / phases / deposits / loading / error` |
| `useFinanceOverviewStore` | 财务概览 | `summary / overdueList / loading / error` |
| `useInvoiceListStore` | 账单列表 | `list / meta / filters / loading / error` |
| `useWorkOrderListStore` | 工单列表 | `list / meta / filters / loading / error` |
| `useWorkOrderDetailStore` | 工单详情 | `order / logs / photos / loading / error` |
| `useKpiDashboardStore` | KPI 看板 | `scores / rankings / trends / loading / error` |
| `useSubleaseListStore` | 二房东列表 | `list / meta / loading / error` |

### B.2 Admin 独有 Store

| Store | 对应视图 | state 核心字段 |
|-------|---------|---------------|
| `useNoiDetailStore` | NOI 明细 | `summary / trend / breakdown / loading / error` |
| `useWaleDetailStore` | WALE 明细 | `waleData / trend / loading / error` |
| `useContractFormStore` | 合同新建/编辑 | `form / submitting / error` |
| `useContractTerminateStore` | 合同终止 | `form / deposit / submitting / error` |
| `useContractRenewStore` | 合同续签 | `parentContract / form / submitting / error` |
| `useEscalationConfigStore` | 递增配置 | `phases / forecast / loading / saving / error` |
| `useTenantListStore` | 租客列表 | `list / meta / loading / error` |
| `useTenantDetailStore` | 租客详情 | `tenant / contracts / loading / error` |
| `useTenantFormStore` | 租客新建/编辑 | `form / submitting / error` |
| `useInvoiceDetailStore` | 账单详情 | `invoice / items / payments / loading / error` |
| `usePaymentFormStore` | 收款录入 | `form / allocations / submitting / error` |
| `useMeterReadingFormStore` | 抄表录入 | `form / preview / submitting / error` |
| `useMeterReadingListStore` | 抄表列表 | `list / meta / loading / error` |
| `useTurnoverReportStore` | 营业额申报 | `list / meta / loading / error` |
| `useExpenseListStore` | 费用列表 | `list / meta / loading / error` |
| `useExpenseFormStore` | 费用录入 | `form / submitting / error` |
| `useUnitImportStore` | 批量导入 | `step / result / validating / importing / error` |
| `useWorkOrderFormStore` | 工单提报 | `form / buildings / floors / units / submitting / error` |
| `useUserManagementStore` | 用户管理 | `list / meta / loading / error` |
| `useUserFormStore` | 用户新建/编辑 | `form / departments / submitting / error` |
| `useOrganizationStore` | 组织架构 | `tree / selectedDept / scopes / loading / error` |
| `useKpiSchemeManageStore` | KPI 方案管理 | `list / meta / loading / error` |
| `useKpiSchemeDetailStore` | KPI 方案详情 | `scheme / metrics / targets / loading / error` |
| `useKpiAppealStore` | KPI 申诉 | `appeals / form / submitting / loading / error` |
| `useEscalationTemplateStore` | 递增模板 | `list / meta / loading / error` |
| `useAlertCenterStore` | 预警中心 | `list / meta / filters / loading / error` |
| `useAuditLogStore` | 审计日志 | `list / meta / filters / loading / error` |
| `useSubLandlordUnitListStore` | 二房东单元列表 | `units / progress / loading / error` |
| `useSubleaseFillingStore` | 子租赁填报 | `form / unit / submitting / error` |
| `useSubleaseImportStore` | 批量导入 | `result / importing / error` |

> 所有 Store 使用 `defineStore(id, setup)` setup 风格；state 统一包含 `loading: ref(false)` + `error: ref<string | null>(null)`；错误处理统一 `catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }`。

---

*文档结束。如有疑问或需进一步细化单个页面交互（如表单校验规则、动画时序、无障碍标注），请联系前端负责人。*
