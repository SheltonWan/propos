# PropOS 前端页面规格说明书

| 元信息 | 值 |
|--------|------|
| 版本 | v1.8 |
| 日期 | 2026-04-12 |
| 依据 | PRD v1.8 · ARCH v1.5 · API_CONTRACT v1.7 |
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
10. [通知与审批模块页面](#十通知与审批模块页面)（v1.8 新增）
11. [催收管理页面](#十一催收管理页面)（v1.8 新增）
12. [系统设置模块页面](#十二系统设置模块页面)
13. [响应式断点与布局策略](#十三响应式断点与布局策略)
14. [状态色语义映射速查](#十四状态色语义映射速查)
15. [附录 A：页面清单与模块映射](#附录-a页面清单与模块映射)
16. [附录 B：Pinia Store 清单](#附录-bpinia-store-清单)

---

## 一、全局导航与路由结构

### 1.1 双端架构概览

PropOS 前端分为两个独立项目，共享后端 API 但各自维护路由与 UI 体系：

| 端 | 项目目录 | 技术栈 | 导航形式 | 目标用户 |
|----|---------|--------|---------|---------|
| **uni-app 移动端** | `app/` | Vue 3 + TS + Pinia + wot-design-uni | TabBar 5 Tab + `uni.navigateTo` | 管理层 / 专员（移动查看 + 现场轻中操作）|
| **Admin PC 端** | `admin/` | Vue 3 + TS + Pinia + Element Plus | ElMenu 侧边栏 + Vue Router 4 | 管理层 / 专员（完整分析工作台 + 复杂操作）|

> **双端产品原则**：核心业务与经营数据的查看权双端同权。只要某角色在 Admin 可查看某类核心业务对象或经营分析结果，uni-app 也应提供对应的移动查看入口；双端差异不由“信息价值高低”决定，而由操作复杂度、批量处理需求和风险等级决定。

#### 双端职责分层

1. **结果同权层**：双端都展示核心指标、趋势、关键异常、Top 列表和必要的明细跳转入口。
2. **移动分析层**：uni-app 提供高频查看、有限维度切换、有限下钻和单对象详情链，作为现场移动工作台。
3. **PC 工作台层**：Admin 提供宽表、多筛选联动、并排比较、导出、批量判断等完整分析工作台能力。
4. **执行治理层**：批量审批、批量导出、复杂录入、参数维护、导入修正、审计治理等高风险动作由 Admin 主承载。

### 1.2 uni-app 导航结构

**底部 TabBar**（5 个主 Tab）：

| Tab 序号 | 路径 | 文字 | 图标 |
|---------|------|------|------|
| 1 | `pages/dashboard/index` | 首页 | dashboard |
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
| `pages/dashboard/noi-detail` | NOI 移动分析 |
| `pages/dashboard/wale-detail` | WALE 移动分析 |
| `pages/finance/invoices` | 发票账单 |
| `pages/finance/kpi` | KPI 考核 |
| `pages/finance/dunning` | 催收记录 |
| `pages/workorders/detail` | 工单详情 |
| `pages/workorders/new` | 新建工单 |
| `pages/subleases/index` | 二房东管理 |
| `pages/subleases/detail` | 二房东详情 |
| `pages/notifications/index` | 通知中心（v1.8 新增）|
| `pages/approvals/index` | 审批队列 |

**路由守卫**：`uni.addInterceptor('navigateTo')` 在跳转前检查 `uni.getStorageSync('access_token')`，未登录重定向到 `/pages/auth/login`。

### 1.3 Admin 导航结构

**根布局**：`AppLayout.vue`（侧边栏 + 顶部栏 + 主内容区）

**侧边栏菜单**（ElMenu）：

```
AppLayout
├── ElAside(width: 240px, 可折叠至 64px)
│   └── ElMenu(mode: vertical, router: true)
│       ├── ElMenuItem(index: /dashboard) → "首页" 📊
│       ├── ElSubMenu(index: /assets) → "资产管理"
│       │   ├── ElMenuItem(index: /assets) → "资产总览"
│       │   └── ElMenuItem(index: /assets/import) → "批量导入"
│       ├── ElSubMenu(index: /contracts) → "租务管理"
│       │   ├── ElMenuItem(index: /contracts) → "合同列表"
│       │   └── ElMenuItem(index: /tenants) → "租客管理"
│       ├── ElSubMenu(index: /finance) → "财务管理"
│       │   ├── ElMenuItem(index: /finance) → "财务总览"
│       │   ├── ElMenuItem(index: /finance/invoices) → "账单管理"
│       │   ├── ElMenuItem(index: /finance/deposits) → "押金管理"
│       │   ├── ElMenuItem(index: /finance/expenses) → "费用支出"
│       │   ├── ElMenuItem(index: /finance/meter-readings) → "水电抄表"
│       │   ├── ElMenuItem(index: /finance/turnover-reports) → "营业额申报"
│       │   ├── ElMenuItem(index: /finance/dunning) → "催收管理"（v1.8 新增）
│       │   └── ElMenuItem(index: /finance/noi-budget) → "NOI 预算"
│       ├── ElMenuItem(index: /workorders) → "工单管理" 🔧
│       ├── ElMenuItem(index: /subleases) → "二房东管理" 🏘️
│       ├── ElMenuItem(index: /notifications) → "通知中心" 🔔（v1.8 新增）
│       ├── ElMenuItem(index: /approvals) → "审批队列" ✅（v1.8 新增，SA/OM 可见）
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
│       ├── 通知铃铛 ElBadge(:value="unreadCount" :hidden="unreadCount===0"）（60s 轮询 GET /api/notifications/unread-count）（v1.8 新增，点击 → /notifications）
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
      { path: 'finance/deposits', name: 'deposits', component: DepositListView },
      { path: 'finance/turnover-reports', name: 'turnover-reports', component: TurnoverReportListView },
      { path: 'finance/turnover-reports/:id', name: 'turnover-detail', component: TurnoverReportDetailView },
      { path: 'finance/noi-budget', name: 'noi-budget', component: NoiBudgetView },
      { path: 'finance/kpi', name: 'kpi', component: KpiView },
      { path: 'finance/kpi/scheme/:schemeId', name: 'kpi-scheme-detail', component: KpiSchemeDetailView },
      { path: 'workorders', name: 'workorders', component: WorkordersView },
      { path: 'workorders/new', name: 'workorder-new', component: WorkorderFormView },
      { path: 'workorders/:id', name: 'workorder-detail', component: WorkorderDetailView },
      { path: 'subleases', name: 'subleases', component: SubleasesView },
      { path: 'subleases/:id', name: 'sublease-detail', component: SubleaseDetailView },
      // v1.8 新增 ↓
      { path: 'notifications', name: 'notifications', component: NotificationCenterView },
      { path: 'approvals', name: 'approvals', component: ApprovalQueueView, meta: { roles: ['super_admin', 'operations_manager'] } },
      { path: 'finance/dunning', name: 'dunning', component: DunningListView },
      // v1.8 新增 ↑
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

| 角色 | uni-app 可访问主 Tab / 关键子页 | Admin 可访问路由 |
|------|------------------|----------------|
| `super_admin` / `operations_manager` | 全部 5 Tab + 通知 + NOI 明细 + WALE 明细 + 审批 + 催收查看 | 全部路由（含 /approvals） |
| `leasing_specialist` | 资产 / 合同 / 工单 / 通知 + WALE 明细 | assets / contracts / workorders / notifications |
| `finance_staff` | 财务 / 合同（只读）/ 通知 + NOI 明细 + WALE 明细 + 催收查看 | finance（含 dunning）/ contracts（只读）/ notifications |
| `maintenance_staff` | 首页 / 工单 / 通知 | workorders / notifications |
| `property_inspector` | 首页 / 资产（只读）/ 合同（只读、金额脱敏）/ 工单（只读）/ 通知 | assets / contracts（只读）/ workorders（只读）/ notifications |
| `report_viewer` | 首页 / 资产（只读）/ 合同（只读、PII脱敏）/ 财务（只读）/ 通知 + NOI 明细 + WALE 明细 + 催收查看（只读） | assets / contracts / finance（全只读）/ notifications |
| `sub_landlord` | 不开放 uni-app；通过独立外部门户 `/portal/login` 进入 | 不开放 Admin |

> 角色在登录后从 JWT Claims 解析写入 Pinia `useAuthStore`；uni-app 守卫读取 store 中的 `role` 字段动态控制 TabBar 可见性；Admin `router.beforeEach` 读取 `localStorage.access_token`，完整角色鉴权委托给后端 RBAC 中间件。`sub_landlord` 使用外部门户独立登录态，不参与 uni-app / Admin 主导航守卫。

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

> **NOI 分析分层架构说明**（对应 PRD M3.2）
>
> | 层级 | 页面 | 章节 | 内容定位 |
> |------|------|------|---------|
> | **L1 概览** | Dashboard 首页（4.1） | 首页 NOI 卡片 | 当月 NOI + 环比 + NOI Margin + 出租率 + 收款率，点击跳转 L2 |
> | **L2 移动分析** | NOI 移动分析页（4.2 uni-app） | 移动视图 | 核心结论、时间切换、楼栋切换、趋势、业态分拆、Top 异常、单对象跳转 |
> | **L2 工作台** | NOI 明细页（4.2 Admin）| 完整工作台 | M3.2 全部看板组件：业态分拆、支出类目、趋势图、楼栋下钻、预算对比、宽表联动 |
> | **L3 深钻** | NOI 明细页内下钻 | 4.2 Collapse / Dialog | 逐笔支出清单、未缴款租户列表、空置单元详情 |
>
> uni-app 移动端承载 L1 概览 + L2 移动分析视图；Admin PC 端承载完整 L2 工作台 + L3 深钻明细。

### 4.1 首页

**Admin**: `DashboardView.vue`  
**路由**: `/dashboard`  
**uni-app**: `pages/dashboard/index.vue`（TabBar 首页）  
**Store**: `useDashboardStore`  
**API**: `GET /api/assets/overview` + `GET /api/noi/summary` + `GET /api/contracts/wale` + `GET /api/alerts/unread` + `GET /api/notifications/unread-count`（v1.8 新增，用于顶部铃铛角标）+ `GET /api/dashboard/overview`（v1.8 新增，聚合看板数据）

#### Admin 组件树：

```
DashboardView
└── div.dashboard-container
    ├── ── 第一行：核心指标卡片（L1 NOI 概览层）──
    │   ElRow(:gutter="24")
    │   ├── ElCol(:span="6") → MetricCard(label: "总出租率", value: "87.5%")
    │   ├── ElCol(:span="6") → MetricCard(label: "当月 NOI", value: "¥1,234,567", subtitle: "Margin 67.2%", trend: "+2.1%", @click → /dashboard/noi-detail)
    │   ├── ElCol(:span="6") → MetricCard(label: "WALE(收入)", value: "2.35 年")
    │   └── ElCol(:span="6") → MetricCard(label: "收款率", value: "94.8%")
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
            ├── ElButton("新建合同" → /contracts/new)           [contracts.write]
            ├── ElButton("提交报修" → /workorders/new)          [workorders.write]
            ├── ElButton("录入收款" → /finance/invoices)        [finance.write]
            ├── ElButton("查看账单" → /finance/invoices)        [finance.read]
            ├── ElButton("资产查询" → /assets)                  [assets.read]
            └── ElButton("KPI 考核" → /finance/kpi)            [kpi.view]
```

#### uni-app 组件树：

```
dashboard/index.vue
└── scroll-view(scroll-y)
    ├── ── Header（问候语 + 日期 + 铃铛 + 头像）──
    │   view.header
    │   ├── text "你好，{user.name}"
    │   ├── text "{M月D日 ddd}"
    │   ├── wd-icon(name="notification") + badge(红点)
    │   └── avatar(@click → /profile)
    │
    ├── ── 核心指标（2×2 网格，L1 概览层，RBAC 自适应）──
    │   view.metric-grid
    │   ├── MetricCard("综合出租率", "89.2%", trend: "↑2.1%")           ← 全角色可见
    │   ├── MetricCard("当月 NOI / 收款率 / 在租合同")                   ← SA/OM/RV=NOI, LS/FS=收款率, MS=在租合同, PI=在租合同
    │   ├── MetricCard("WALE(收入)", "3.2 年")                          ← 全角色可见
    │   └── MetricCard("收款率 / WALE(面积) / 空置房源")                 ← SA/OM/RV=收款率, LS/FS=WALE(面积), MS/PI=空置数
    │   注: 每角色始终显示 4 个卡片，通过 RBAC 规则自适应填充
    │   注: 具备对应数据权限的角色可点击 NOI / WALE 卡片进入移动分析页；无权限角色只显示摘要不显示跳转 affordance
    │
    ├── ── 三业态概览（垂直紧凑面板行，同屏全显）──
    │   div.rounded-2xl.border(divide-y)
    │   ├── PropertyTypePanelRow("写字楼", 441套, 已租400, 空置41, 90.7%, barColor=#3B82F6)
    │   ├── PropertyTypePanelRow("商铺", 25套, 已租23, 空置2, 92.0%, barColor=#F59E0B)
    │   └── PropertyTypePanelRow("公寓", 173套, 已租147, 空置26, 85.0%, barColor=#8B5CF6)
    │   注: 不横向滚动，3行同屏，便于管理层并列对比
    │
    ├── ── 运营预警（3 条，移除空置项）── [alerts.read]
    │   wd-card(title="运营预警")
    │   ├── wd-cell("合同即将到期", 5份, severity=danger)
    │   ├── wd-cell("逾期账单", 3笔 ¥66,500, severity=danger)
    │   └── wd-cell("工单超时未处理", 2单, severity=warning)
    │
    ├── ── 快捷操作（6 项，3列网格，按权限过滤）──
    │   view.action-grid(cols=3)
    │   ├── ActionCard("新建合同" → /pages/contracts/detail?mode=new)  [contracts.write]
    │   ├── ActionCard("提交报修" → /pages/workorders/new)             [workorders.write]
    │   ├── ActionCard("录入收款" → /pages/finance/invoices)           [finance.write]
    │   ├── ActionCard("查看账单" → /pages/finance/invoices)           [finance.read]
    │   ├── ActionCard("资产查询" → /pages/assets/index)               [assets.read]
    │   └── ActionCard("KPI 考核" → /pages/finance/kpi)               [kpi.view]
    │
    └── ── 待办任务（5 条，按权限过滤）──
        wd-card(title="待办任务")
        ├── TaskItem(v-for="task in tasks")
        └── wd-button(type="text") "查看全部"
```

### 4.2 NOI 分析页 `NoiDetailView`（uni-app 移动分析视图 + Admin 工作台）

**Admin**: `admin/src/views/dashboard/NoiDetailView.vue`  
**路由**: `/dashboard/noi-detail`  
**uni-app**: `pages/dashboard/noi-detail.vue`（从首页 NOI 卡片或财务页经营看板进入）  
**Store**: `useNoiDetailStore`（Admin） / `useMobileNoiDetailStore`（uni-app）  
**API**: `GET /api/noi/summary` + `GET /api/noi/trend` + `GET /api/noi/breakdown` + `GET /api/noi/vacancy-loss` + `GET /api/noi/budget`

> **双端分层**：uni-app 提供“结果同权 + 有限下钻”的移动分析视图；Admin 提供完整 NOI 工作台，承载多维联动、宽表、预算比对与深钻明细。

#### Admin 组件树：

```
NoiDetailView
└── div
    ├── ── 视角切换 + 楼栋筛选 ──
    │   ElRow(:gutter="16" justify="space-between")
    │   ├── ElRadioGroup(v-model="perspective")
    │   │   ├── ElRadioButton("应收视角")
    │   │   └── ElRadioButton("实收视角")
    │   └── ElSelect(v-model="buildingId" placeholder="全部楼栋")
    │       ├── ElOption("全部")
    │       ├── ElOption("A座")
    │       ├── ElOption("商铺区")
    │       └── ElOption("公寓楼")
    │
    ├── ── L2 汇总卡片行（瀑布结构：PGI → EGI → NOI）──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("PGI 潜在总收入", "¥xxx")
    │   ├── MetricCard("空置损失", "-¥xxx", type="danger")
    │   ├── MetricCard("EGI 有效总收入", "¥xxx")
    │   ├── MetricCard("OpEx 运营支出", "-¥xxx", type="warning")
    │   └── MetricCard("NOI 净营运收入", "¥xxx", type="primary")
    │
    ├── ── L2 效率指标 + 预算对比 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("NOI Margin", "67.2%", trend: "+2.1%")
    │   ├── MetricCard("OpEx Ratio", "32.8%", trend: "-1.5%")
    │   └── MetricCard("NOI 达成率", "103.2%", subtitle: "预算 ¥xxx", type="success")
    │
    ├── ── L2 业态 NOI 分拆表格 ──
    │   ElTable(:data="breakdown")
    │   ├── ElTableColumn(label="业态")
    │   ├── ElTableColumn(label="收入")
    │   ├── ElTableColumn(label="支出")
    │   ├── ElTableColumn(label="NOI")
    │   ├── ElTableColumn(label="NOI Margin")
    │   └── ElTableColumn(label="出租率")
    │
    ├── ── L2 近12月 NOI 趋势折线图 ──
    │   ECharts(type: line, series: [实际NOI, 预算NOI], data: monthlyNoi)
    │
    ├── ── L2 运营支出构成饼图 ──
    │   ECharts(type: pie, data: expenseCategories)
    │   // 类目：物管费/水电公摊/维修费(OpEx)/保险/税金/专业服务费
    │
    ├── ── L3 运营支出逐笔明细 ── (Should)
    │   ElCollapse
    │   └── ElCollapseItem(title="支出明细清单")
    │       └── ElTable: 日期 | 类目 | 摘要 | 金额 | 费用性质(OpEx/CapEx) | 来源(工单/手录)
    │
    ├── ── L3 空置损失测算列表 ── (Should)
    │   ElCollapse
    │   └── ElCollapseItem(title="空置损失明细")
    │       └── ElTable: 单元编号 | 楼栋 | 业态 | 面积 | 参考市场租金 | 月损失额 | 空置天数
    │
    └── ── L3 未缴款租户列表 ── (Should)
        ElCollapse
        └── ElCollapseItem(title="未缴款租户明细")
            └── ElTable: 租户 | 单元 | 费项 | 应收金额 | 逾期天数
                └── @row-click → /finance/invoices/:invoiceId
```

  #### uni-app 组件树：

  ```
  pages/dashboard/noi-detail
  └── scroll-view(scroll-y)
    ├── ── 顶部筛选条 ──
    │   view.filter-bar
    │   ├── wd-segmented("应收视角" / "实收视角")
    │   ├── wd-drop-menu-item(title="时间", :options="periodOptions")
    │   └── wd-drop-menu-item(title="楼栋", :options="buildingOptions")
    │
    ├── ── 核心指标卡 ──
    │   view.metric-grid
    │   ├── MetricCard("NOI", "¥xxx")
    │   ├── MetricCard("EGI", "¥xxx")
    │   ├── MetricCard("OpEx", "¥xxx")
    │   └── MetricCard("预算达成率", "103.2%")
    │
    ├── ── 趋势图 ──
    │   wd-card(title="近12月 NOI 趋势")
    │   └── ECharts(line)
    │
    ├── ── 业态分拆 ──
    │   wd-card(title="业态分拆")
    │   └── wd-cell-group
    │       └── wd-cell(v-for="item in breakdown")
    │           title: "{{ item.property_type }}"
    │           label: "NOI Margin {{ item.margin }}%"
    │           value: "¥{{ item.noi }}"
    │
    ├── ── Top 异常清单 ──
    │   wd-card(title="重点异常")
    │   ├── wd-cell(title="空置损失 Top 5" is-link @click="expandVacancyTop")
    │   └── wd-cell(title="未缴款租户 Top 5" is-link @click="expandOverdueTop")
    │
    └── ── 关联资源入口 ──
      wd-button(type="info" plain) "查看关联账单"
      wd-button(type="info" plain) "查看关联合同"
  ```

  ### 4.3 WALE 分析页 `WaleDetailView`（uni-app 移动分析视图 + Admin 工作台）

**Admin**: `admin/src/views/dashboard/WaleDetailView.vue`  
**路由**: `/dashboard/wale-detail`  
  **uni-app**: `pages/dashboard/wale-detail.vue`（从首页 WALE 卡片或财务页经营看板进入）  
  **Store**: `useWaleDetailStore`（Admin） / `useMobileWaleDetailStore`（uni-app）  
**API**: `GET /api/contracts/wale` + `GET /api/contracts/wale/trend`(Should) + `GET /api/contracts/wale/waterfall`(Should)

  > **双端分层**：uni-app 提供 WALE 关键结果、趋势和到期风险的移动分析视图；Admin 保留完整 WALE 工作台，包括分维度宽表、趋势、水位/瀑布图与导出。

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

  #### uni-app 组件树：

  ```
  pages/dashboard/wale-detail
  └── scroll-view(scroll-y)
    ├── ── 汇总卡片 ──
    │   view.metric-grid
    │   ├── MetricCard("收入加权 WALE", "2.35 年")
    │   └── MetricCard("面积加权 WALE", "2.18 年")
    │
    ├── ── 维度切换 ──
    │   wd-tabs(v-model="groupBy")
    │   ├── wd-tab(title="按楼栋")
    │   └── wd-tab(title="按业态")
    │
    ├── ── 分维度列表 ──
    │   wd-card(title="WALE 分布")
    │   └── wd-cell(v-for="item in waleData" @click="toContracts(item.dimension)")
    │       title: "{{ item.dimension }}"
    │       label: "在租合同 {{ item.contract_count }} 份"
    │       value: "{{ item.revenueWale }} / {{ item.areaWale }} 年"
    │
    ├── ── 趋势图 ──
    │   wd-card(title="WALE 趋势")
    │   └── ECharts(line)
    │
    └── ── 即将到期合同 Top 列表 ──
      wd-card(title="即将到期合同")
      └── wd-cell(v-for="item in expiringContracts" is-link @click="toContract(item.id)")
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
        ├── ElStep(title="确认导入")
        │   ├── ElText "确认将 635 条数据写入数据库？"
        │   ├── ElText "导入批次号: BATCH-2026-04-08-001"
        │   ├── ElButton(type="primary" :loading="importing") "确认导入"
        │   └── ElProgress(:percentage="importProgress")
        │
        └── ElStep(title="治理与回滚")
          ├── ElCard(header="导入批次管理")
          │   ├── ElTable(:data="batches")
          │   │   ├── ElTableColumn(label="批次号")
          │   │   ├── ElTableColumn(label="数据类型")
          │   │   ├── ElTableColumn(label="导入时间")
          │   │   ├── ElTableColumn(label="导入人")
          │   │   ├── ElTableColumn(label="状态")
          │   │   └── ElTableColumn(label="操作") [下载错误报告] [按批次回滚]
          │   └── ElAlert(type="warning") "范围回滚按批次执行，仅对支持批次回滚的数据生效"
          │
          └── ElCard(header="批量修正")
            ├── ElUpload(:auto-upload="false" accept=".xlsx,.xls" :limit="1")
            ├── ElText "使用修正模板更新已有记录，不新增重复数据"
            └── ElButton(type="primary" :loading="correcting") "执行批量修正"
```

  │   ├── ElSelect(v-model="creditRating") "信用评级: 全部/A/B/C/D"

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

  ### 6.5.1 租金预测页（Should: S-01）

  **Admin**: `RentForecastView.vue`  
  **路由**: `/contracts/:contractId/rent-forecast`  
  **Store**: `useRentForecastStore`  
  **API**: `GET /api/contracts/:id/rent-forecast`

  #### Admin 组件树：

  ```
  RentForecastView
  └── div
    ├── ElDescriptions(border title="合同摘要")
    │   ├── 合同编号 | 租户 | 起租日 | 到期日
    │   └── 当前月租金 | 递增模板 | 预测口径
    │
    ├── ElCard(header="全生命周期租金预测")
    │   └── ElTable(:data="forecastRows")
    │       ├── ElTableColumn(label="期间")
    │       ├── ElTableColumn(label="月租金")
    │       ├── ElTableColumn(label="年化租金")
    │       └── ElTableColumn(label="较上期涨幅")
    │
    └── ElSpace
      ├── ElButton(icon="Download") "导出 Excel"
      └── ElButton(type="primary" plain) "返回递增配置"
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
    │   ├── ElDescriptionsItem(label="最近付款日") "2026-04-01"
    │   └── ElDescriptionsItem(label="信用评级") → StatusTag
    │
    ├── ── 缴费信用 ──
    │   ElCard(header="缴费信用")
    │   ├── ElDescriptions: 当前评级 | 评级日期 | 最近付款日
    │   ├── ElText "过去12个月逾期 0 次"
    │   └── ElCollapse
    │       └── ElCollapseItem(title="评级历史趋势（Should: S-06）")
    │           └── ECharts(type: line, 评级历史趋势)
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
    ├── ── NOI 汇总卡片（L1 概览级，点击跳转 L2）──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("本月应收", "¥2,345,678")
    │   ├── MetricCard("本月实收", "¥2,100,000")
    │   ├── MetricCard("收款率", "89.5%")
    │   ├── MetricCard("NOI", "¥1,234,567", subtitle: "Margin 67.2%", @click → /dashboard/noi-detail)
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

#### uni-app 组件树（角色差异化四视图）：

> 财务页根据登录用户角色渲染完全独立的视图，各视图共用 `Header` 结构但 Header 背景色、内容卡片、功能入口均不同。**参照原型实现：`frontend/src/app/pages/Finance.tsx`，详见 `FINANCE_ROLE_ADAPTIVE_DESIGN.md`**。

```
finance/index.vue
└── scroll-view(scroll-y)
    └── [v-if 角色分支]

    ── 管理层视图（super_admin / operations_manager）──
    │   ├── Header（深蓝渐变 #0f2645→#1a3a5c，标题"财务概览·经营看板"）
    │   ├── NOISummaryCard（→ /pages/dashboard/noi-detail）
    │   ├── WALESummaryCard（→ /pages/dashboard/wale-detail）
    │   ├── RevenueSnapshotCard
    │   ├── SectionLabel "核心待办"
    │   ├── wd-grid(col-num="2")
    │   │   ├── FeaturedCard（KPI 申诉 🔴 角标）
    │   │   └── FeaturedCard（待审批 🔴 角标 → /pages/approvals/index）
    │   ├── SecondaryIconRow（费用/水电/押金/营业额/催收 5 入口）
    │   └── OverdueSection（逾期账单 Top 5）
    │
    ── 财务专员视图（finance_staff）──
    │   ├── Header（深绿渐变 #064e3b→#065f46，标题"今日待处理"，右上角 🔴 圆钮）
    │   ├── SectionLabel "今日任务"
    │   ├── wd-grid(col-num="2")
    │   │   ├── FeaturedCard（账单核销 🔴×5 → /finance/invoices）
    │   │   └── FeaturedCard（水电审核 🟡×2 → /finance/meter-readings）
    │   ├── SecondaryIconRow（费用/押金/营业额/NOI预算/催收 5 入口）
    │   └── OverdueSection（逾期账单 Top 5）
    │
    ── 租务专员视图（leasing_specialist）──
    │   ├── Header（蓝色渐变 #1a3a5c→#2a5298，标题"租务财务"）
    │   ├── SectionLabel "我的事项"
    │   ├── wd-grid(col-num="2")
    │   │   ├── FeaturedCard（押金管理 → /finance/deposits）
    │   │   └── FeaturedCard（营业额申报 → /finance/turnover-reports）
    │   ├── SecondaryIconRow（水电/账单/KPI 3 入口）
    │   └── CompactCollectionWidget（收款进度条 + 已收/应收统计）
    │
    ── 维修技工视图（maintenance_staff）──
        ├── Header（深琥珀渐变 #78350f→#92400e，标题"水电录入"，右上角 🟡 圆钮）
        ├── SectionLabel "待录入"
        ├── FeaturedCard — 全宽（水电录入 🟡×2 → /finance/meter-readings/new）
        └── SecondaryIconRow（账单查看/KPI 2 入口）
    ── 楼管巡检视图（property_inspector）──
        ├── Header（深青渐变 #134e4a→#065f46，标题"巡检管理"）
        ├── MiniAssetCard（分业态出租率 3 卡）
        ├── FeaturedCard — 全宽（水电抄表 → /finance/meter-readings/new）
        ├── SecondaryIconRow（工单查看/租客信息/KPI 3 入口）
        └── WorkOrderReadOnlyList（最近 5 条工单，只读）
    ── 只读观察视图（report_viewer）──
        ├── Header（深紫渐变 #3b0764→#581c87，标题"财务概览"）
        ├── NOISummaryCard（只读）
        ├── WALESummaryCard（只读）
        ├── RevenueSnapshotCard（只读）
        ├── KPIOverviewCard（只读）
        └── 注: 零操作按钮
```

**共用子组件清单**：

| 组件 | 说明 |
|------|------|
| `SectionLabel` | 彩色竖条 + 区块标题 |
| `FeaturedCard` | 图标 + 角标 + 2 行摘要 + CTA 链接 |
| `SecondaryIconRow` | 小图标横排，含可选 🔴/🟡 角标 |
| `CompactCollectionWidget` | 进度条 + 已收/应收（仅租务专员视图）|
| `NOISummaryCard` | 深色 NOI 摘要卡（仅管理层视图）|
| `WALESummaryCard` | 深色 WALE 摘要卡（仅管理层视图）|
| `RevenueSnapshotCard` | 收入快报卡（仅管理层视图）|
| `OverdueSection` | 逾期账单 Top 5 列表（管理层 / 财务专员 / 只读观察视图）|
| `MiniAssetCard` | 分业态出租率迷你卡（楼管巡检视图）|
| `WorkOrderReadOnlyList` | 最近工单只读列表（楼管巡检视图）|
| `KPIOverviewCard` | KPI 总分概览卡（只读观察视图）|

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

#### uni-app 组件树：

```
finance/invoices.vue
└── view
    ├── ── 筛选栏 ──
    │   scroll-view(scroll-x)
    │   └── wd-tag(v-for="status in statusOptions"
    │           :type="activeStatus === status.value ? 'primary' : 'default'"
    │           @click="filterByStatus(status.value)")
    │       // 全部 / 已出账 / 逾期 / 已核销
    │
    └── ── 账单列表 ──
        wd-list(loading-text="加载中" finished-text="没有更多了")
        └── wd-cell(v-for="invoice in list" is-link
                @click="toDetail(invoice.id)")
            ├── title: invoice.invoice_number
            ├── label: "{{ invoice.tenant_name }} · {{ invoice.billing_period }}"
            ├── icon-slot: StatusTag(:status="invoice.status")
            └── value: "¥{{ invoice.total_amount }}"
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
    ├── ── 催收记录 ──
    │   ElCard(header="催收记录")
    │   └── ElTable(:data="dunningLogs")
    │       ├── ElTableColumn(label="催收时间") → dayjs 格式化
    │       ├── ElTableColumn(label="催收节点") "第 1/7/15 天"
    │       ├── ElTableColumn(label="渠道") "短信/邮件"
    │       ├── ElTableColumn(label="接收方") invoice.tenant_name
    │       └── ElTableColumn(label="送达状态") → ElTag(delivered/failed)
    │           // 数据来源: GET /api/invoices/:id/dunning-logs
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

> 支持两种录入模式：**租户独立分表**（一个单元一条记录）和**公区总表分摊**（公共区域总用量按面积比例摊至各租户，系统自动生成多条分摊记录）。

#### Admin 组件树：

```
MeterReadingFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
    ├── ── 录入模式切换 ──
    │   ElRadioGroup(v-model="form.mode")
    │   ├── ElRadioButton(label="unit") "租户独立表"
    │   └── ElRadioButton(label="common") "公区总表分摊"
    │
    ├── ── 模式A：租户独立表 (v-if="form.mode === 'unit'") ──
    │   ├── ElFormItem(label="单元") → ElSelect(filterable remote :remote-method="searchUnits")
    │   ├── ElFormItem(label="表计类型") → ElSelect(水表/电表/燃气表)
    │   ├── ElFormItem(label="抄表周期") → ElDatePicker(type="month")
    │   ├── ElRow(:gutter="24")
    │   │   ├── ElCol(:span="12") → ElFormItem("上期读数") → ElInput(disabled, 自动填充)
    │   │   └── ElCol(:span="12") → ElFormItem("本期读数") → ElInputNumber
    │   │
    │   └── ── 费用预览 ──
    │       ElCard(header="费用预览")
    │       ├── ElText "用量: {{ current - previous }} 度"
    │       ├── ElText "单价: ¥{{ tier1Price }}/度"
    │       ├── ElText "阶梯部分: {{ excess }} 度 × ¥{{ tier2Price }}"
    │       └── ElStatistic(title="合计费用" :value="total" prefix="¥")
    │
    ├── ── 模式B：公区总表分摊 (v-if="form.mode === 'common'") ──
    │   ├── ElFormItem(label="公区名称") → ElInput "如：A座公区/B座走廊"
    │   ├── ElFormItem(label="表计类型") → ElSelect(水表/电表)
    │   ├── ElFormItem(label="抄表周期") → ElDatePicker(type="month")
    │   ├── ElRow(:gutter="24")
    │   │   ├── ElCol(:span="12") → ElFormItem("上期读数") → ElInput(disabled)
    │   │   └── ElCol(:span="12") → ElFormItem("本期读数") → ElInputNumber
    │   │
    │   └── ── 分摊预览 ──
    │       ElCard(header="分摊预览（按计费面积比例）")
    │       ├── ElText "公区总用量: {{ total }} 度  单价: ¥{{ price }}/度"
    │       └── ElTable(:data="allocationPreview")
    │           ├── ElTableColumn(label="单元")
    │           ├── ElTableColumn(label="计费面积 m²")
    │           ├── ElTableColumn(label="分摊比例")
    │           └── ElTableColumn(label="应分摊金额")
    │           // API: GET /api/meter-readings/common-allocation-preview
    │           // 自动生成各租户分摊账单
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

### 7.10 押金台账页

**Admin**: `DepositListView.vue`  
**路由**: `/finance/deposits`  
**Store**: `useDepositListStore`  
**API**: `GET /api/deposits`

#### Admin 组件树：

```
DepositListView
└── div
    ├── ── 汇总卡片 ──
    │   ElRow(:gutter="24")
    │   ├── MetricCard("押金总额", "¥xxx", subtitle: "所有在租合同")
    │   ├── MetricCard("冻结中", "¥xxx", type="warning")
    │   └── MetricCard("本月应退", "¥xxx", subtitle: "合同终止前7天", type="danger")
    │
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElSelect "状态: 全部/已收取/冻结中/部分冲抵/已退还"
    │   ├── ElInput "租户/合同搜索"
    │   └── ElDatePicker(type="daterange") "收取日期范围"
    │
    └── ProposTable
        ├── ElTableColumn(label="合同编号")
        ├── ElTableColumn(label="租户")
        ├── ElTableColumn(label="押金金额")
        ├── ElTableColumn(label="当前余额")
        ├── ElTableColumn(label="状态") → StatusTag
        ├── ElTableColumn(label="收取日期")
        └── ElTableColumn(label="操作")
            └── ElButton(link) "查看流水" → ElDrawer 侧滑展示流水
                // 流水表格: 时间 | 类型(收取/冻结/冲抵/退还) | 金额 | 余额 | 操作人 | 原因
```

### 7.11 NOI 预算管理页

**Admin**: `NoiBudgetView.vue`  
**路由**: `/finance/noi-budget`  
**Store**: `useNoiBudgetStore`  
**API**: `GET /api/noi/budget` + `POST /api/noi/budget` + `POST /api/noi/budget/import`

> 录入年度 NOI 预算值，作为 KPI 指标 K07（NOI 达成率）和 NOI 明细页预算对比线的数据基准。

#### Admin 组件树：

```
NoiBudgetView
└── div
    ├── ── 年份选择 + 操作 ──
    │   ElRow(justify="space-between")
    │   ├── ElDatePicker(v-model="year" type="year" format="YYYY年")
    │   └── ElSpace
    │       ├── ElButton(icon="Upload") "Excel 导入"
    │           → ElUpload(accept=".xlsx,.xls" action="/api/noi/budget/import")
    │       └── ElButton(type="primary" icon="Check") "保存"
    │
    ├── ── 预算录入表格（按楼栋×业态）──
    │   ElText(type="info") "单位：元 / 月；系统自动汇总全年"
    │   ElTable(:data="budgetRows" border)
    │   ├── ElTableColumn(label="楼栋/业态" fixed)
    │   ├── ElTableColumn(label="1月") → ElInputNumber(v-model inline-edit)
    │   ├── ElTableColumn(label="2月") → ElInputNumber inline
    │   ├── ... (3月~12月)
    │   └── ElTableColumn(label="全年合计", :formatter 自动求和 disabled)
    │   // 行：A座-写字楼 / 商铺区-商铺 / 公寓楼-公寓 / 合计
    │
    └── ── 历年预算对比 ── (只读)
        ElCard(header="历年预算 vs 实际 NOI")
        └── ECharts(type: bar, xAxis: 年份, series: [预算NOI, 实际NOI])
```

---

## 八、工单模块页面

> Phase 1 支持三种工单类型：`repair`（报修）、`complaint`（投诉）、`inspection`（退租验房），共享列表/详情页面，通过 Tab/筛选器区分。

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
    │   ├── ElRadioGroup(v-model="filters.work_order_type" size="small")
    │   │   ├── ElRadioButton "全部"
    │   │   ├── ElRadioButton "报修" (value="repair")
    │   │   ├── ElRadioButton "投诉" (value="complaint")
    │   │   └── ElRadioButton "退租验房" (value="inspection")
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
        ├── ElTableColumn(label="工单类型") → ElTag(:type="typeTagType")
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
    ├── ── 工单类型切换 ──
    │   view.type-tabs
    │   └── wd-tabs(v-model="activeType")
    │       ├── wd-tab(title="全部" name="")
    │       ├── wd-tab(title="报修" name="repair")
    │       ├── wd-tab(title="投诉" name="complaint")
    │       └── wd-tab(title="验房" name="inspection")
    │
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
  // 弹出选择工单类型：[扫码报修] / [手动报修] / [提交投诉] / [退租验房]
  uni.showActionSheet({
    itemList: ['扫码报修', '手动报修', '提交投诉', '退租验房'],
    success(res) {
      switch (res.tapIndex) {
        case 0:
          uni.scanCode({ success(res) { /* 解析 unit_id → 带参数跳转 */ } })
          break
        case 1:
          uni.navigateTo({ url: '/pages/workorders/new?type=repair' })
          break
        case 2:
          uni.navigateTo({ url: '/pages/workorders/new?type=complaint' })
          break
        case 3:
          uni.navigateTo({ url: '/pages/workorders/new?type=inspection' })
          break
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
    ├── ── 工单类型 ──
    │   ElFormItem(label="工单类型") → ElRadioGroup(v-model="form.work_order_type")
    │     ├── ElRadioButton(label="repair") "报修"
    │     ├── ElRadioButton(label="complaint") "投诉"
    │     └── ElRadioButton(label="inspection") "退租验房"
    │
    ├── ── 位置选择（级联）──
    │   ElFormItem(label="楼栋") → ElSelect(v-model="form.building_id")
    │   ElFormItem(label="楼层") → ElSelect(v-model="form.floor_id" :disabled="!form.building_id")
    │   ElFormItem(label="单元") → ElSelect(v-model="form.unit_id" :disabled="!form.floor_id")
    │
    ├── ── 关联合同（仅 inspection 类型显示）──
    │   ElFormItem(v-if="form.work_order_type === 'inspection'" label="关联合同")
    │   → ElSelect(v-model="form.contract_id" filterable)
    │
    ├── ElFormItem(label="问题描述") → ElInput(type="textarea" :rows="5")
    ├── ElFormItem(label="问题类型") → ElSelect(:options="issueTypeOptions") // 选项根据 work_order_type 动态切换
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
        ├── ── 工单类型（从路由参数读取或手动选择）──
        │   wd-radio-group(label="工单类型" v-model="form.work_order_type" :disabled="typeFromRoute")
        │     // repair=报修, complaint=投诉, inspection=退租验房
        │
        ├── ── 位置选择 ──
        │   wd-picker(label="楼栋" :columns="buildings" v-model="form.building_id")
        │   wd-picker(label="楼层" :columns="floors" v-model="form.floor_id")
        │   wd-picker(label="单元" :columns="units" v-model="form.unit_id")
        │   // 扫码场景: 以上三项已预填，只读显示
        │
        ├── ── 关联合同（仅 inspection 类型显示）──
        │   wd-picker(v-if="form.work_order_type === 'inspection'" label="关联合同" :columns="contracts" v-model="form.contract_id")
        │
        ├── wd-textarea(label="问题描述" v-model="form.description" :maxlength="500")
        ├── wd-picker(label="问题类型" :columns="issueTypeOptions" v-model="form.category") // 选项根据 work_order_type 动态切换
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

> 二房东模块分为两个交付面：内部管理视角（Admin / uni-app 辅助查看）与外部门户视角（独立 Web）。外部门户不挂载到 Admin 主导航骨架，使用独立登录入口、独立会话超时和独立改密流程。

### 9.1 二房东管理列表（内部管理视角）

**Admin**: `SubleasesView.vue`  
**路由**: `/subleases`  
**uni-app**: `pages/subleases/index.vue`（内部员工辅助查看，不对 `sub_landlord` 开放）  
**Store**: `useSubleaseListStore`  
**API**: `GET /api/subleases`

#### Admin 组件树：

```
SubleasesView
└── div
  ├── div.header-actions
  │   ├── ElButton(type="primary" icon="Plus") "新建子租赁" → /subleases/new
  │   └── ElButton(icon="Upload") "批量导入" → /subleases/import
  │
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
      ├── ElButton(link) "查看"
      ├── ElButton(link type="primary") "编辑"
      ├── ElButton(link type="success") "通过"
      └── ElButton(link type="danger") "退回"
```

### 9.2 子租赁详情页（内部管理视角）

**Admin**: `SubleaseDetailView.vue`  
**路由**: `/subleases/:id`  
**Store**: `useSubleaseDetailStore`  
**API**: `GET /api/subleases/:id`

#### 组件树：

```
SubleaseDetailView
└── div
  ├── ElDescriptions(border title="基本信息")
  │   ├── 主合同 | 单元 | 终端租客 | 入住状态 | 审核状态
  │   └── 联系人 | 联系电话 | 证件号(脱敏)
  │
  ├── ElCard(header="租赁信息")
  │   └── ElDescriptions(border)
  │       ├── 起租日 | 到期日 | 月租金
  │       ├── 租金单价 | 入住人数 | 备注
  │
  ├── ElCard(header="版本与变更记录")
  │   └── ElTimeline
  │       └── ElTimelineItem(v-for="log in logs" :timestamp="log.time")
  │           {{ log.description }}
  │
  └── ElSpace
    ├── ElButton(type="primary") "编辑" → /subleases/:id/edit
    ├── ElButton(type="success") "审核通过"
    └── ElButton(type="danger") "退回"
```

### 9.3 子租赁录入页（内部管理视角）

**Admin**: `SubleaseFormView.vue`  
**路由**: `/subleases/new` 或 `/subleases/:id/edit`  
**Store**: `useSubleaseFormStore`  
**API**: `POST /api/subleases` / `PATCH /api/subleases/:id`

#### 组件树：

```
SubleaseFormView
└── ElForm(:model="form" :rules="rules" label-width="120px")
  ├── ElDivider "主合同与单元"
  │   ├── ElFormItem("主合同") → ElSelect(filterable remote)
  │   ├── ElFormItem("单元") → ElSelect(:disabled="!form.masterContractId")
  │   └── ElAlert(type="info") "同一单元同一时间仅允许 1 条在租记录"
  │
  ├── ElDivider "终端租客信息"
  │   ├── ElFormItem("名称") → ElInput
  │   ├── ElFormItem("类型") → ElSelect(企业/个人)
  │   ├── ElFormItem("联系人") → ElInput
  │   ├── ElFormItem("联系电话") → ElInput
  │   └── ElFormItem("证件号") → ElInput
  │
  ├── ElDivider "租赁信息"
  │   ├── ElFormItem("入住状态") → ElSelect(已入住/已签约未入住/已退租/空置)
  │   ├── ElFormItem("起租日") → ElDatePicker
  │   ├── ElFormItem("到期日") → ElDatePicker(:disabled-date="afterMainContractEnd")
  │   ├── ElFormItem("月租金(¥)") → ElInputNumber
  │   ├── ElText(type="info") "自动计算单价: ¥{{ rent / area }}/m²/月"
  │   └── ElFormItem("入住人数") // v-if 公寓
  │
  ├── ElFormItem("备注") → ElInput(type="textarea")
  │
  └── ElSpace
    ├── ElButton "保存草稿"
    ├── ElButton(type="primary") "提交审核"
    └── v-if="canApproveDirectly": ElButton(type="success") "保存并生效"
```

### 9.4 二房东登录页（外部门户）

**Portal**: `PortalLoginView.vue`  
**独立路由**: `/portal/login`  
**Store**: `usePortalAuthStore`  
**API**: `POST /api/sublease-portal/auth/login`

#### 组件树：

```
PortalLoginView
└── div.portal-login
  ├── div.brand-panel
  │   ├── Logo
  │   ├── ElText(tag="h1") "PropOS 二房东平台"
  │   └── ElText(type="info") "仅可访问自身主合同范围内数据"
  │
  └── ElCard
    └── ElForm(:model="form" :rules="rules")
      ├── ElFormItem("账号") → ElInput
      ├── ElFormItem("密码") → ElInput(type="password" show-password)
      ├── ElText(type="warning") "首次登录需修改密码；连续 5 次失败将锁定 30 分钟"
      ├── ElAlert(v-if="error" type="error" :title="error")
      └── ElButton(type="primary" :loading="submitting") "登录"
```

**交互说明**：
- 登录成功 → 跳转 `/portal/subleases`
- `must_change_password == true` → 跳转 `/portal/change-password`（复用 3.2 修改密码表单结构）
- 连续 5 次失败 → 显示锁定提示与解锁时间
- 主合同到期或账号冻结 → 禁止登录，仅展示联系管理员指引

### 9.5 单元填报列表页（二房东视角）

**Portal**: `SubLandlordPortalListView.vue`  
**独立路由**: `/portal/subleases`  
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
  ├── ── 顶部操作 ──
  │   ElSpace
  │   └── ElButton(type="primary" plain) "批量导入" → /portal/subleases/import
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

### 9.6 子租赁填报页（二房东视角）

**Portal**: `SubleaseFillingView.vue`  
**独立路由**: `/portal/subleases/:id/edit`  
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
  ├── ElCheckbox(v-model="form.declarationAccepted") "我确认填报内容真实、准确并承担责任"
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

### 9.7 批量导入页

**Admin**: `SubleaseImportView.vue`  
**Admin 路由**: `/subleases/import`  
**Portal 路由**: `/portal/subleases/import`  
**Store**: `useSubleaseImportStore`  
**API**: `POST /api/subleases/import`（内部） / `POST /api/sublease-portal/subleases/import`（外部）

#### 组件树：

```
SubleaseImportView
└── div
  ├── v-if="isInternal": ElSelect "主合同"
  ├── ElButton(icon="Download") "下载导入模板"
  ├── ElUpload(:auto-upload="false" accept=".xlsx" :limit="1")
  ├── ElText(type="info") "内部导入支持按二房东范围批量修正；外部门户仅可导入自身范围"
  ├── ElButton(type="primary" :loading="importing") "开始导入"
  └── ElCard(v-if="result" header="导入结果")
    ├── ElAlert(:type="result.errors.length ? 'warning' : 'success'")
    │   "成功: {{ result.success }} 条 | 失败: {{ result.errors.length }} 条"
    ├── ElButton(v-if="result.errors.length") "下载错误报告 Excel"
    └── ElTable(v-if="result.errors.length" :data="result.errors")
      ├── ElTableColumn(label="行号")
      ├── ElTableColumn(label="字段")
      └── ElTableColumn(label="原因")
```

---

## 十、通知与审批模块页面（v1.8 新增）

> 通知中心双端均提供；审批队列双端提供，其中 uni-app 聚焦待办查看与单条审批，Admin 提供完整审批工作台。

### 10.1 通知中心

**Admin**: `admin/src/views/notifications/NotificationCenterView.vue`  
**路由**: `/notifications`  
**uni-app**: `app/src/pages/notifications/index.vue`（非 TabBar，从首页铃铛图标 `uni.navigateTo` 进入）  
**Store**: `useNotificationStore`  
**API**: `GET /api/notifications` + `PATCH /api/notifications/:id/read` + `GET /api/notifications/unread-count` + `PATCH /api/notifications/read-all`  
**权限**: `notifications.read`（所有角色）

#### Admin 组件树：

```
NotificationCenterView
└── div
    ├── ── 顶部工具栏 ──
    │   ElRow(justify="space-between" align="middle")
    │   ├── ElSpace
    │   │   ├── ElSelect(v-model="filters.type" placeholder="全部类型" clearable)
    │   │   │   └── ElOption(v-for="t in notificationTypes" :label="t.label" :value="t.value")
    │   │   ├── ElSelect(v-model="filters.severity" placeholder="全部级别" clearable)
    │   │   │   └── ElOption: info / warning / critical
    │   │   └── ElSelect(v-model="filters.is_read" placeholder="全部状态" clearable)
    │   │       ├── ElOption(label="未读" :value="false")
    │   │       └── ElOption(label="已读" :value="true")
    │   └── ElButton(@click="markAllRead" :disabled="unreadCount === 0") "全部已读"
    │
    └── ── 通知列表 ──
        ElTable(:data="list" @row-click="onNotificationClick" :row-class-name="rowClassName")
        ├── ElTableColumn(width="40")
        │   └── ElBadge(is-dot :hidden="row.is_read")
        ├── ElTableColumn(label="级别" width="80")
        │   └── ElTag(:type="severityTypeMap[row.severity]") {{ row.severity }}
        ├── ElTableColumn(label="类型" width="120")
        │   └── ElTag {{ notificationTypeLabel(row.type) }}
        ├── ElTableColumn(label="标题" prop="title" min-width="200")
        ├── ElTableColumn(label="时间" width="180")
        │   └── span {{ dayjs(row.created_at).format('YYYY-MM-DD HH:mm') }}
        └── ElTableColumn(label="操作" width="120")
            ├── ElButton(link @click.stop="markRead(row.id)" v-if="!row.is_read") "标为已读"
            └── ElButton(link @click.stop="goToResource(row)") "查看详情"
        ElPagination(:current-page="meta.page" :page-size="meta.pageSize" :total="meta.total")
```

**交互说明**：
- 点击通知行：如 `resource_type + resource_id` 存在，跳转到关联资源页（合同详情 / 账单详情 / 工单详情等）
- 未读行加 `highlight-row` 背景色
- `severity` 色映射：`info → info`、`warning → warning`、`critical → danger`

#### uni-app 组件树：

```
pages/notifications/index
└── view.notifications-page
    ├── ── 顶部筛选 ──
    │   wd-tabs(v-model="activeTab")
    │   ├── wd-tab(title="全部")
    │   ├── wd-tab(title="未读" :badge="unreadCount")
    │   └── wd-tab(title="重要" info="critical")
    │
    ├── ── 通知列表 ──
    │   scroll-view(scroll-y @scrolltolower="loadMore")
    │   └── wd-cell-group
    │       └── wd-cell(v-for="item in list" :key="item.id" @click="onTap(item)"
    │                    :title="item.title" :label="dayjs(item.created_at).fromNow()"
    │                    is-link)
    │           template(#icon)
    │           └── wd-badge(:is-dot="!item.is_read")
    │               wd-icon(:name="notificationIcon(item.type)")
    │
    └── ── 空状态 ──
        wd-status-tip(v-if="!loading && list.length === 0" image="content" tip="暂无通知")
```

### 10.2 审批队列

**Admin**: `admin/src/views/approvals/ApprovalQueueView.vue`  
**路由**: `/approvals`  
**uni-app**: `pages/approvals/index.vue`（从首页待办卡片、财务页待审入口或通知跳转进入）  
**Store**: `useApprovalStore`（Admin） / `useApprovalMobileStore`（uni-app）  
**API**: `GET /api/approvals` + `PATCH /api/approvals/:id`  
**权限**: `approvals.manage`（仅 SA / OM）

> **双端分层**：uni-app 提供待审批事项查看、摘要查看、关联资源跳转与单条审批；Admin 提供统计卡片、复杂筛选、批量审核、拒绝理由录入与审计留痕。

#### Admin 组件树：

```
ApprovalQueueView
└── div
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElSelect(v-model="filters.type" placeholder="审批类型" clearable)
    │   │   └── ElOption: contract_terminate / contract_renew / expense_large / sublease_approve
    │   ├── ElSelect(v-model="filters.status" placeholder="状态" clearable)
    │   │   └── ElOption: pending / approved / rejected
    │   └── ElDatePicker(v-model="filters.dateRange" type="daterange")
    │
    ├── ── 待审批统计卡片 ──
    │   ElRow(:gutter="16")
    │   ├── MetricCard("待审批", pendingCount, type="warning")
    │   ├── MetricCard("本周已审", weekApprovedCount, type="success")
    │   └── MetricCard("本周已拒", weekRejectedCount, type="danger")
    │
    └── ── 审批列表 ──
        ElTable(:data="list" :row-class-name="row => row.status === 'pending' ? 'pending-row' : ''")
        ├── ElTableColumn(label="审批类型" width="120")
        │   └── ElTag {{ approvalTypeLabel(row.approval_type) }}
        ├── ElTableColumn(label="申请人" prop="requester_name" width="100")
        ├── ElTableColumn(label="摘要" prop="summary" min-width="200")
        ├── ElTableColumn(label="申请时间" width="180")
        │   └── span {{ dayjs(row.created_at).format('YYYY-MM-DD HH:mm') }}
        ├── ElTableColumn(label="状态" width="100")
        │   └── StatusTag(:status="row.status")
        └── ElTableColumn(label="操作" width="200" fixed="right")
            ElSpace(v-if="row.status === 'pending'")
            ├── ElButton(type="success" size="small" @click="approve(row.id)") "通过"
            ├── ElButton(type="danger" size="small" @click="openRejectDialog(row)") "拒绝"
            └── ElButton(link @click="goToResource(row)") "查看详情"
        ElPagination(:current-page="meta.page" :page-size="meta.pageSize" :total="meta.total")
```

**交互说明**：
- "查看详情" 根据 `approval_type` + `resource_id` 路由到对应业务页面（合同详情 / 费用详情 / 二房东详情）
- 拒绝操作弹出 `ElDialog` 要求填写拒绝理由（`remark` 字段必填）
- 审批通过/拒绝后列表自动刷新，行切换为已审状态
- 禁止审批自己提交的申请（`APPROVAL_SELF_REVIEW` 错误码）

#### uni-app 组件树：

```
pages/approvals/index
└── scroll-view(scroll-y)
  ├── ── 顶部状态筛选 ──
  │   wd-tabs(v-model="activeTab")
  │   ├── wd-tab(title="待审批" :badge="pendingCount")
  │   ├── wd-tab(title="已通过")
  │   └── wd-tab(title="已退回")
  │
  ├── ── 审批卡片列表 ──
  │   wd-card(v-for="item in list" :key="item.id")
  │   ├── view.card-header
  │   │   ├── text {{ approvalTypeLabel(item.approval_type) }}
  │   │   └── StatusTag(:status="item.status")
  │   ├── text.summary {{ item.summary }}
  │   ├── wd-cell(title="申请人" :value="item.requester_name")
  │   ├── wd-cell(title="申请时间" :value="dayjs(item.created_at).format('MM-DD HH:mm')")
  │   └── view.action-row
  │       ├── wd-button(size="small" plain @click="goToResource(item)") "查看详情"
  │       ├── wd-button(v-if="item.status === 'pending'" size="small" type="success" @click="approve(item.id)") "通过"
  │       └── wd-button(v-if="item.status === 'pending'" size="small" type="danger" @click="openRejectSheet(item)") "拒绝"
  │
  └── ── 拒绝说明底部弹层 ──
    wd-popup(v-model="rejectSheetVisible" position="bottom")
    ├── wd-textarea(v-model="remark" placeholder="请输入拒绝理由")
    └── wd-button(type="primary" block) "确认提交"
```

---

## 十一、催收管理页面（v1.8 新增）

> 催收管理双端提供，其中 uni-app 提供催收查看层和待跟进入口，Admin 提供催收登记、编辑、复杂筛选和治理工作台。

### 11.1 催收记录列表

**Admin**: `admin/src/views/finance/DunningListView.vue`  
**路由**: `/finance/dunning`  
**uni-app**: `pages/finance/dunning.vue`（从财务页催收入口、逾期账单列表或账单详情中的催收记录进入）  
**Store**: `useDunningStore`（Admin） / `useDunningMobileStore`（uni-app）  
**API**: `GET /api/dunning-logs` + `POST /api/dunning-logs`  
**权限**: `finance.read` / `finance.write`

> **双端分层**：uni-app 负责催收记录查看、待跟进项查看、逾期账单关联和下次跟进提醒；Admin 保留新建催收、编辑催收、复杂筛选、分页宽表和完整日志治理。

#### Admin 组件树：

```
DunningListView
└── div
    ├── ── 筛选栏 ──
    │   ElForm(inline)
    │   ├── ElInput(v-model="filters.tenant_name" placeholder="租客名称" clearable)
    │   ├── ElSelect(v-model="filters.method" placeholder="催收方式" clearable)
    │   │   └── ElOption: phone / sms / email / letter / visit
    │   ├── ElDatePicker(v-model="filters.dateRange" type="daterange" range-separator="至")
    │   └── ElButton(type="primary" icon="Plus" @click="openNewDunningDialog") "新建催收"
    │
    └── ── 催收记录表 ──
        ProposTable(:data="list" :loading="loading")
        ├── ElTableColumn(label="催收日期" width="120")
        │   └── span {{ dayjs(row.dunning_date).format('YYYY-MM-DD') }}
        ├── ElTableColumn(label="租客" prop="tenant_name" width="120")
        ├── ElTableColumn(label="关联账单" width="140")
        │   └── ElButton(link @click="goToInvoice(row.invoice_id)") {{ row.invoice_no }}
        ├── ElTableColumn(label="催收方式" width="100")
        │   └── ElTag {{ dunningMethodLabel(row.method) }}
        ├── ElTableColumn(label="催收金额" width="120" align="right")
        │   └── span ¥{{ row.amount?.toLocaleString() }}
        ├── ElTableColumn(label="备注" prop="remark" min-width="200" show-overflow-tooltip)
        ├── ElTableColumn(label="操作人" prop="operator_name" width="100")
        └── ElTableColumn(label="下次跟进" width="120")
            └── span(:class="{ 'text-danger': isOverdue(row.next_follow_up) }")
                {{ row.next_follow_up ? dayjs(row.next_follow_up).format('MM-DD') : '—' }}
        ElPagination(:current-page="meta.page" :page-size="meta.pageSize" :total="meta.total")
```

#### 新建催收对话框：

```
ElDialog(v-model="showNewDialog" title="新建催收记录" width="560px")
└── ElForm(ref="formRef" :model="form" :rules="rules" label-width="100px")
    ├── ElFormItem(label="关联账单" prop="invoice_id")
    │   └── ElSelect(v-model="form.invoice_id" filterable remote placeholder="搜索逾期账单")
    ├── ElFormItem(label="催收方式" prop="method")
    │   └── ElRadioGroup(v-model="form.method")
    │       ├── ElRadio(value="phone") "电话"
    │       ├── ElRadio(value="sms") "短信"
    │       ├── ElRadio(value="email") "邮件"
    │       ├── ElRadio(value="letter") "函件"
    │       └── ElRadio(value="visit") "上门"
    ├── ElFormItem(label="催收日期" prop="dunning_date")
    │   └── ElDatePicker(v-model="form.dunning_date" type="date")
    ├── ElFormItem(label="备注" prop="remark")
    │   └── ElInput(v-model="form.remark" type="textarea" :rows="3")
    ├── ElFormItem(label="下次跟进")
    │   └── ElDatePicker(v-model="form.next_follow_up" type="date")
    └── template(#footer)
        ElButton(@click="showNewDialog = false") "取消"
        ElButton(type="primary" :loading="submitting" @click="submitDunning") "确认提交"
```

  #### uni-app 组件树：

  ```
  pages/finance/dunning
  └── scroll-view(scroll-y)
    ├── ── 顶部摘要卡 ──
    │   view.metric-grid
    │   ├── MetricCard("待跟进", pendingCount)
    │   ├── MetricCard("本周催收", weekCount)
    │   └── MetricCard("逾期金额", overdueAmount)
    │
    ├── ── 筛选条 ──
    │   wd-tabs(v-model="activeTab")
    │   ├── wd-tab(title="全部")
    │   ├── wd-tab(title="待跟进")
    │   └── wd-tab(title="已完成")
    │
    ├── ── 催收记录列表 ──
    │   wd-card(v-for="item in list" :key="item.id")
    │   ├── view.card-header
    │   │   ├── text {{ item.tenant_name }}
    │   │   └── wd-tag {{ dunningMethodLabel(item.method) }}
    │   ├── wd-cell(title="关联账单" :value="item.invoice_no")
    │   ├── wd-cell(title="催收日期" :value="dayjs(item.dunning_date).format('YYYY-MM-DD')")
    │   ├── wd-cell(title="下次跟进" :value="followUpText(item.next_follow_up)")
    │   └── view.action-row
    │       ├── wd-button(size="small" plain @click="goToInvoice(item.invoice_id)") "查看账单"
    │       └── wd-button(size="small" plain @click="showRemark(item)") "查看备注"
    │
    └── ── 跟进备注弹层 ──
      wd-popup(v-model="remarkVisible" position="bottom")
      └── text {{ activeRemark }}
  ```

---

## 十二、系统设置模块页面

> 系统设置仅 Admin 端提供，uni-app 端不包含设置页面。

### 12.1 设置侧边栏

设置页面通过侧边栏 ElMenu 的 "系统设置" 子菜单进入，无独立设置首页。

### 12.2 用户管理页

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

### 12.3 用户新建/编辑页

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
    │   options: super_admin / operations_manager / leasing_specialist / finance_staff / maintenance_staff / property_inspector / report_viewer / sub_landlord
    ├── ElFormItem(label="所属部门") → ElTreeSelect(:data="departments")
    │
    ├── ElDivider "初始密码" (v-if="!isEdit")
    ├── ElFormItem(label="初始密码") → ElInput(type="password" show-password)
    ├── ElCheckbox(disabled modelValue) "首次登录强制修改密码"
    │
    └── ElButton(type="primary" :loading="submitting") {{ isEdit ? '保存' : '创建用户' }}
```

### 12.4 组织架构管理页

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

### 12.5 KPI 方案管理页

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

### 12.6 预警中心

**Admin**: `AlertCenterView.vue`  
**路由**: `/settings/alerts`  
**Store**: `useAlertCenterStore`  
**API**: `GET /api/alerts` + `GET /api/alerts/failed-tasks` + `POST /api/alerts/resend`

#### 组件树：

```
AlertCenterView
└── div
  ├── ElTabs(v-model="activeTab")
  │   ├── ElTabPane(label="预警记录" name="records")
  │   │   ├── ElForm(inline)
  │   │   │   ├── ElSelect "类型: 全部/到期预警/逾期预警/押金提醒/填报提醒"
  │   │   │   ├── ElSelect "状态: 全部/未读/已读"
  │   │   │   ├── ElDatePicker(type="daterange")
  │   │   │   ├── ElButton "全部已读"
  │   │   │   └── ElButton "补发预警"
  │   │   │
  │   │   └── ElTable(:data="alerts" @row-click="onAlertClick")
  │   │       ├── ElTableColumn(label="")
  │   │       │   └── ElBadge(is-dot :hidden="alert.is_read")
  │   │       ├── ElTableColumn(label="类型") → ElTag(:type="alertTypeMap[type]")
  │   │       ├── ElTableColumn(label="内容")
  │   │       ├── ElTableColumn(label="关联资源")
  │   │       └── ElTableColumn(label="时间")
  │   │
  │   └── ElTabPane(label="失败任务" name="failed")
  │       ├── ElForm(inline)
  │       │   ├── ElSelect "任务类型: 全部/到期预警/逾期预警/押金提醒/填报提醒"
  │       │   ├── ElSelect "状态: 全部/待重试/已放弃"
  │       │   └── ElDatePicker(type="daterange")
  │       │
  │       └── ElTable(:data="failedTasks")
  │           ├── ElTableColumn(label="任务类型")
  │           ├── ElTableColumn(label="关联合同/资源")
  │           ├── ElTableColumn(label="失败原因")
  │           ├── ElTableColumn(label="重试次数")
  │           ├── ElTableColumn(label="最后失败时间")
  │           └── ElTableColumn(label="操作") [立即重试] [查看详情]
  │
  └── ElDialog(title="补发预警" v-model="showResendDialog" width="560px")
    └── ElForm(:model="resendForm" label-width="100px")
      ├── ElFormItem("补发范围") → ElRadioGroup(按合同/按日期区间)
      ├── ElFormItem("合同") → ElSelect(filterable remote)
      ├── ElFormItem("日期区间") → ElDatePicker(type="daterange")
      ├── ElFormItem("预警类型") → ElSelect
      └── ElButton(type="primary") "确认补发"
```

### 12.7 递增模板管理页

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

### 12.8 KPI 申诉页

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

### 12.9 审计日志页

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

## 十三、响应式断点与布局策略

### 13.1 双端布局策略

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

### 13.2 Admin 组件响应策略

| 组件 | 小屏 (< 768px) | 大屏 (≥ 1200px) |
|------|----------------|-----------------|
| `MetricCard` 行 | 2列 ElRow | 4列 ElRow |
| `ElTable` | 横向滚动 | 全列展示 |
| 表单 | 单列 | 双列 ElRow |
| Tab | 可横向滚动 | 全部可见 |
| 图表 | 宽高自适应 | 固定高度 |
| 楼层图 | 全屏查看 | 左侧列表 + 右侧图 |
| 组织架构 | 单面板（切换） | 双面板（左树右详情） |

### 13.3 平台能力降级策略

| 功能 | iOS/Android/HarmonyOS | 微信小程序 | Admin PC |
|------|:---------------------:|:--------:|:--------:|
| QR 扫码报修 | ✅ `uni.scanCode` | ✅ `wx.scanCode` | ❌ → 手动填报 |
| 推送通知 | ✅ uni-push | ✅ 模板消息 | ❌ → 轮询 |
| 相机拍照 | ✅ `uni.chooseImage` | ✅ | ❌ → 文件选择 |
| 文件选取/导入 | ✅ | ⚠️ 受限 | ✅ |
| Excel 批量导入 | ❌ → Admin 操作 | ❌ → Admin 操作 | ✅ |
| SVG 热区图 | ✅ WebView | ⚠️ canvas | ✅ v-html |

---

## 十四、状态色语义映射速查

### 14.0 双端色彩体系

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

### 14.1 通用状态色

| 状态语义 | Admin ElTag type | uni-app wd-tag type | 适用场景 |
|---------|-----------------|---------------------|---------|
| 已租/已核销/已通过/已完成 | `success` | `success` | 单元已租、账单已核销、审核通过、工单完成 |
| 即将到期/预警/待审核 | `warning` | `warning` | 合同即将到期、逾期预警、待审核 |
| 空置/逾期/错误/已拒绝 | `danger` | `danger` | 单元空置、账单逾期、审核退回 |
| 非可租/已作废/已停用 | `info` | `default` | 非可租单元、作废账单、停用 |
| 执行中/处理中/草稿 | `primary` | `primary` | 合同执行中、工单处理中、草稿 |

### 14.2 合同状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `quoting` | `primary` | `primary` | 报价中 |
| `pending_sign` | `warning` | `warning` | 待签约 |
| `active` | `success` | `success` | 执行中 |
| `expiring_soon` | `warning` | `warning` | 即将到期 |
| `expired` | `info` | `default` | 已到期 |
| `renewed` | `success` | `success` | 已续签 |
| `terminated` | `danger` | `danger` | 已终止 |

### 14.3 账单状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `draft` | `primary` | `primary` | 草稿 |
| `issued` | `warning` | `warning` | 已出账 |
| `paid` | `success` | `success` | 已核销 |
| `overdue` | `danger` | `danger` | 逾期 |
| `cancelled` | `info` | `default` | 已作废 |
| `exempt` | `info` | `default` | 免租免单 |

### 14.4 工单状态色映射

| 状态 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| `submitted` | `primary` | `primary` | 已提交 |
| `approved` | `warning` | `warning` | 已派单 |
| `in_progress` | `primary` | `primary` | 处理中 |
| `pending_inspection` | `warning` | `warning` | 待验收 |
| `completed` | `success` | `success` | 已完成 |
| `rejected` | `danger` | `danger` | 已拒绝 |
| `on_hold` | `info` | `default` | 挂起 |

### 14.5 信用评级色映射

| 评级 | Admin type | uni-app type | 标签文案 |
|------|-----------|-------------|---------|
| A | `success` | `success` | A 优质 |
| B | `warning` | `warning` | B 一般 |
| C | `danger` | `danger` | C 风险 |
| D | `danger` | `danger` | D 严重违约 |

---

## 附录 A：页面清单与模块映射

### A.1 uni-app 页面清单（21 个页面）

| 页面 | 路径 | 模块 | TabBar |
|------|------|------|:------:|
| 登录 | `pages/auth/login` | 认证 | — |
| 首页 | `pages/dashboard/index` | 概览 | ✅ Tab 1 |
| NOI 移动分析 | `pages/dashboard/noi-detail` | 概览 | — |
| WALE 移动分析 | `pages/dashboard/wale-detail` | 概览 | — |
| 资产总览 | `pages/assets/index` | 资产 | ✅ Tab 2 |
| 楼栋详情 | `pages/assets/building-detail` | 资产 | — |
| 楼层热区图 | `pages/assets/floor-plan` | 资产 | — |
| 房源详情 | `pages/assets/unit-detail` | 资产 | — |
| 合同管理 | `pages/contracts/index` | 租务 | ✅ Tab 3 |
| 合同详情 | `pages/contracts/detail` | 租务 | — |
| 财务总览 | `pages/finance/index` | 财务 | ✅ Tab 5 |
| 发票账单 | `pages/finance/invoices` | 财务 | — |
| KPI 考核 | `pages/finance/kpi` | KPI | — |
| 催收记录 | `pages/finance/dunning` | 财务 | — |
| 工单管理 | `pages/workorders/index` | 工单 | ✅ Tab 4 |
| 工单详情 | `pages/workorders/detail` | 工单 | — |
| 新建工单 | `pages/workorders/new` | 工单 | — |
| 二房东管理（内部） | `pages/subleases/index` | 二房东 | — |
| 二房东详情（内部） | `pages/subleases/detail` | 二房东 | — |
| 通知中心 | `pages/notifications/index` | 通知 | —（v1.8 新增）|
| 审批队列 | `pages/approvals/index` | 审批 | — |

### A.2 Admin 视图清单（49 视图）

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
| `RentForecastView` | `/contracts/:id/rent-forecast` | 租务 | Should |
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
| `SubleaseFormView` | `/subleases/new` | 二房东 | Must |
| `SubleaseImportView` | `/subleases/import` | 二房东 | Must |
| `UserManagementView` | `/settings/users` | 设置 | Must |
| `UserFormView` | `/settings/users/new` | 设置 | Must |
| `OrganizationManageView` | `/settings/org` | 设置 | Must |
| `KpiSchemeListView` | `/settings/kpi/schemes` | KPI | Must |
| `KpiSchemeFormView` | `/settings/kpi/schemes/new` | KPI | Must |
| `KpiAppealView` | `/settings/kpi/appeal` | KPI | Must |
| `EscalationTemplateListView` | `/settings/escalation/templates` | 设置 | Must |
| `AlertCenterView` | `/settings/alerts` | 设置 | Must |
| `AuditLogView` | `/settings/audit-logs` | 设置 | Must |
| `NotificationCenterView` | `/notifications` | 通知 | Must（v1.8 新增）|
| `ApprovalQueueView` | `/approvals` | 审批 | Must（v1.8 新增）|
| `DunningListView` | `/finance/dunning` | 财务 | Must（v1.8 新增）|

### A.3 二房东外部门户视图清单（5 个视图）

| 视图 | 路由 | 模块 | 优先级 |
|------|------|------|--------|
| `PortalLoginView` | `/portal/login` | 二房东门户 | Must |
| `PortalChangePasswordView` | `/portal/change-password` | 二房东门户 | Must |
| `SubLandlordPortalListView` | `/portal/subleases` | 二房东门户 | Must |
| `SubleaseFillingView` | `/portal/subleases/:id/edit` | 二房东门户 | Must |
| `SubleaseImportView` | `/portal/subleases/import` | 二房东门户 | Must |

> **总计**: uni-app **21 个页面** + Admin **49 个视图** + 外部门户 **5 个视图**，覆盖 Phase 1 全部 Must 需求。

---

## 附录 B：Pinia Store 清单

### B.1 通用 Store（app/ 与 admin/ 各自实现）

| Store | 对应页面 | state 核心字段 |
|-------|---------|---------------|
| `useAuthStore` | 登录/注销/改密 | `user / token / role / loading / error` |
| `useDashboardStore` | 首页 | `metrics / alerts / unreadNotifications / loading / error`（v1.8: 新增 unreadNotifications）|
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
| `useNotificationStore` | 通知中心 | `list / meta / unreadCount / filters / loading / error`（v1.8 新增）|

### B.2 管理端 / 门户端专用 Store

| Store | 对应视图 | state 核心字段 |
|-------|---------|---------------|
| `useNoiDetailStore` | NOI 明细 | `summary / trend / breakdown / loading / error` |
| `useWaleDetailStore` | WALE 明细 | `waleData / trend / loading / error` |
| `useContractFormStore` | 合同新建/编辑 | `form / submitting / error` |
| `useContractTerminateStore` | 合同终止 | `form / deposit / submitting / error` |
| `useContractRenewStore` | 合同续签 | `parentContract / form / submitting / error` |
| `useEscalationConfigStore` | 递增配置 | `phases / forecast / loading / saving / error` |
| `useRentForecastStore` | 租金预测 | `summary / forecastRows / loading / error` |
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
| `useUnitImportStore` | 批量导入 | `step / result / batches / validating / importing / correcting / rollingBack / error` |
| `useWorkOrderFormStore` | 工单提报 | `form / buildings / floors / units / submitting / error` |
| `useSubleaseDetailStore` | 子租赁详情 | `item / logs / loading / error` |
| `useSubleaseFormStore` | 子租赁录入/编辑 | `form / submitting / approving / error` |
| `useUserManagementStore` | 用户管理 | `list / meta / loading / error` |
| `useUserFormStore` | 用户新建/编辑 | `form / departments / submitting / error` |
| `useOrganizationStore` | 组织架构 | `tree / selectedDept / scopes / loading / error` |
| `useKpiSchemeManageStore` | KPI 方案管理 | `list / meta / loading / error` |
| `useKpiSchemeDetailStore` | KPI 方案详情 | `scheme / metrics / targets / loading / error` |
| `useKpiAppealStore` | KPI 申诉 | `appeals / form / submitting / loading / error` |
| `useEscalationTemplateStore` | 递增模板 | `list / meta / loading / error` |
| `useAlertCenterStore` | 预警中心 | `list / failedTasks / meta / filters / resendForm / showResendDialog / loading / error` |
| `useAuditLogStore` | 审计日志 | `list / meta / filters / loading / error` |
| `useSubLandlordUnitListStore` | 二房东门户单元列表 | `units / progress / filters / loading / error` |
| `useSubleaseFillingStore` | 二房东门户子租赁填报 | `form / unit / submitting / error` |
| `useSubleaseImportStore` | 二房东批量导入 | `mode / result / importing / error` |
| `usePortalAuthStore` | 二房东门户登录/改密 | `user / token / mustChangePassword / loading / error` |
| `useApprovalStore` | 审批队列 | `list / meta / pendingCount / filters / loading / error`（v1.8 新增）|
| `useDunningStore` | 催收管理 | `list / meta / form / showNewDialog / submitting / loading / error`（v1.8 新增）|

> 所有 Store 使用 `defineStore(id, setup)` setup 风格；state 统一包含 `loading: ref(false)` + `error: ref<string | null>(null)`；错误处理统一 `catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }`。

---

### v1.8 变更摘要

| 变更项 | 说明 |
|--------|------|
| §五 Excel 批量导入 | 补齐批量修正、按批次回滚与导入批次管理入口 |
| §九 二房东门户 | 补齐内部录入页、外部门户登录页、共享导入路由与内部/外部双视角说明 |
| §十二 预警中心 | 增加失败任务列表与手工补发弹窗 |
| §十四 信用评级映射 | 补齐 D 等级与租客详情缴费信用展示 |
| §十 通知与审批模块 | 通知中心保持双端；审批队列调整为双端分层规格（移动查看/单条审批 + Admin 工作台） |
| §十一 催收管理 | 调整为双端分层规格：移动查看层 + Admin 执行治理层 |
| §四 Dashboard 首页 | 新增双端分析分层原则；API 补充 `GET /api/notifications/unread-count`、`GET /api/dashboard/overview` |
| 全局导航 §1.3 | 侧边栏新增"通知中心"、"审批队列"、"催收管理"菜单项；顶部栏新增通知铃铛 |
| 路由表 §1.3 | 新增 3 条路由：`/notifications`、`/approvals`、`/finance/dunning` |
| uni-app 导航 §1.2 | 新增 `pages/dashboard/noi-detail`、`pages/dashboard/wale-detail`、`pages/finance/dunning`、`pages/approvals/index` 子页面 |
| 附录 A | uni-app 页面 17→21；Admin 49 视图保持不变；Portal 保持 5 视图 |
| 附录 B | 通用 Store +1（useNotificationStore）；管理端 / 门户端专用 Store 补齐二房东与预警中心状态设计 |
| 章节编号 | 原§十~§十二 → §十二~§十四（为新增模块腾位） |

---

*文档结束。如有疑问或需进一步细化单个页面交互（如表单校验规则、动画时序、无障碍标注），请联系前端负责人。*
