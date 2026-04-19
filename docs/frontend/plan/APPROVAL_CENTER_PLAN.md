# 我的审批聚合页 — 设计与实现方案

> **文档版本**: v1.0
> **创建日期**: 2026-04-13
> **所属模块**: frontend（Flutter 移动端 / React 移动端原型）
> **Phase**: Phase 1

---

## 一、背景与动机

Phase 1 包含 5 类审批流（工单派单、子租赁审核、营业额审核、KPI 申诉、押金退还），各审批操作分散在对应业务模块页面中。Dashboard 首页已展示"待办审批"数字卡片，用户的自然预期是点击后看到聚合待办列表。

**核心价值**：物业经理/财务人员打开 app，30 秒内扫完全部待办，比逐个业务页巡查效率高一个数量级。

**设计原则**：审批聚合页为**导航中转型**，仅展示待办列表+跳转，不在页面内重复实现各业务审批逻辑。

---

## 二、审批场景与权限矩阵

### 2.1 Phase 1 审批场景清单

| # | 审批类型 | 待办判定条件 | 发起方 | 审批方 | 关联权限 | 点击跳转 |
|---|---------|-------------|--------|--------|---------|---------|
| 1 | 工单审核/派单 | `work_orders.status = 'submitted'` | maintenance_staff / OM | SA, OM | `workorders.write` | `/work-orders/:id` |
| 2 | 子租赁数据审核 | `subleases.review_status = 'pending'` | sub_landlord / LS | SA, OM, LS | `sublease.write` | `/subleases/:id` |
| 3 | 商铺营业额审核 | `turnover_reports.approval_status = 'pending'` | finance_staff | SA, OM, FS | `turnoverReview.approve` | `/finance/turnover/:id` |
| 4 | KPI 申诉审核 | `kpi_appeals.status = 'pending'` | 所有内部员工 | SA, OM | `kpi.manage` | `/finance/kpi/appeals/:id` |
| 5 | 押金退还确认 | `deposits.status = 'frozen'` | 合同终止触发 | SA, OM, FS | `deposit.write` | `/finance/deposits/:id` |

> **收款核销**为直接操作型（无 pending→approved 状态机），不纳入审批聚合页。

### 2.2 角色可见审批类型

| 角色 | 可见审批类型 |
|------|------------|
| `super_admin` | 全部 5 类 |
| `operations_manager` | 全部 5 类 |
| `leasing_specialist` | 仅子租赁审核 |
| `finance_staff` | 营业额审核 + 押金退还 |
| `maintenance_staff` | 无入口（仅为审批发起方） |
| `property_inspector` | 无入口 |
| `report_viewer` | 无入口 |

---

## 三、页面设计

### 3.1 页面结构

```
┌─────────────────────────────────┐
│ ← 我的审批                     │  ← sticky 白底 Header
├─────────────────────────────────┤
│ ┌─────┬─────┬─────┬─────┬─────┐│
│ │ 全部 │工单 │子租赁│营业额│ ... ││  ← 统计卡（按权限动态）
│ │  12  │  3  │  5  │  2  │     ││
│ └─────┴─────┴─────┴─────┴─────┘│
├─────────────────────────────────┤
│ [全部] [工单派单] [子租赁] ...  │  ← pill tab 筛选（按权限过滤）
├─────────────────────────────────┤
│ ┌───────────────────────────────┐│
│ │ 🔧 工单派单                   ││
│ │ A栋302空调漏水报修            ││  ← 待办卡片（按时间倒序）
│ │ 发起人: 刘维修  今天 10:30    ││
│ │                         紧急 → ││
│ └───────────────────────────────┘│
│ ┌───────────────────────────────┐│
│ │ 🏢 子租赁审核                  ││
│ │ 创客空间B区 填报数据审核       ││
│ │ 发起人: 孙二房  今天 14:00    ││
│ └───────────────────────────────┘│
│ ...                              │
│                                  │
│ 📭 暂无待办审批（空状态）         │
└─────────────────────────────────┘
```

### 3.2 类型色彩映射

| 类型 | 主色 | Icon | Badge 颜色 |
|------|------|------|-----------|
| 工单派单 | blue | Wrench | `bg-blue-50 text-blue-600 border-blue-200` |
| 子租赁审核 | violet | Building2 | `bg-violet-50 text-violet-600 border-violet-200` |
| 营业额审核 | emerald | TrendingUp | `bg-emerald-50 text-emerald-600 border-emerald-200` |
| KPI 申诉 | amber | Target | `bg-amber-50 text-amber-600 border-amber-200` |
| 押金退还 | orange | Wallet | `bg-orange-50 text-orange-600 border-orange-200` |

### 3.3 交互规则

1. **权限过滤**：页面加载时根据 `can(permission)` 动态过滤可见审批类型
2. **Tab 筛选**：点击 pill tab 过滤对应类型待办，"全部"显示所有可见类型
3. **卡片点击**：跳转到对应业务详情页，由详情页内联完成审批操作
4. **统计卡**：顶部卡片展示各类型待办计数 + 总计数，点击等同于切换 tab
5. **空状态**：无待办时展示"暂无待办审批"文案

---

## 四、入口设计

### 4.1 Profile 页入口

在"系统设置"分组上方添加"工作台"分组，包含"我的审批"菜单项：
- 展示条件：`can("workorders.write") || can("sublease.write") || can("turnoverReview.approve") || can("kpi.manage") || can("deposit.write")`
- 含待办计数 badge（红色圆点 + 数字）
- 点击导航到 `/approvals`

### 4.2 Home 页入口

待办任务区标题旁添加"查看全部 →"链接：
- 展示条件：同 Profile 入口
- 点击导航到 `/approvals`

---

## 五、技术实现

### 5.1 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `src/app/pages/Approvals.tsx` | 新建 | 审批聚合页主体 (~250 行) |
| `src/app/pages/Profile.tsx` | 修改 | 恢复"我的审批"菜单入口 |
| `src/app/pages/Home.tsx` | 修改 | 待办区"查看全部"链接 |
| `src/app/routes.tsx` | 修改 | 添加 `/approvals` 路由 |
| `src/app/auth/permissions.ts` | 修改 | 添加 `ROUTE_RULES` 条目 |
| `src/app/Layout.tsx` | 修改 | `HIDE_TAB_PATTERNS` 添加规则 |

### 5.2 路由与权限

```typescript
// permissions.ts — ROUTE_RULES 新增
{ path: "/approvals", allowedRoles: ["super_admin", "operations_manager", "leasing_specialist", "finance_staff"] }

// routes.tsx — 新增路由
{ path: "approvals", Component: Approvals }

// Layout.tsx — 隐藏 TabBar
HIDE_TAB_PATTERNS: /^\/approvals/
```

### 5.3 权限关联逻辑

```typescript
const APPROVAL_TYPES = [
  { key: "work_order",  label: "工单派单",   permission: "workorders.write",       ... },
  { key: "sublease",    label: "子租赁审核", permission: "sublease.write",         ... },
  { key: "turnover",    label: "营业额审核", permission: "turnoverReview.approve", ... },
  { key: "kpi_appeal",  label: "KPI申诉",   permission: "kpi.manage",             ... },
  { key: "deposit",     label: "押金退还",   permission: "deposit.write",          ... },
];

// 动态过滤
const visibleTypes = APPROVAL_TYPES.filter(t => can(t.permission));
```

---

## 六、验证清单

| 验证项 | 预期结果 |
|--------|---------|
| SA 角色访问 `/approvals` | 看到全部 5 类待办 |
| OM 角色访问 `/approvals` | 看到全部 5 类待办 |
| LS 角色访问 `/approvals` | 仅看到子租赁审核 |
| FS 角色访问 `/approvals` | 看到营业额审核 + 押金退还 |
| MS / PI / RV 角色 | Profile 页不显示"我的审批"入口；直接访问 `/approvals` 被路由守卫拦截 |
| Tab 过滤 | 点击各 pill tab 正确过滤列表 |
| 卡片点击 | 跳转到正确的业务详情页路由 |
| `pnpm build` | 零错误 |

---

## 七、Phase 2 扩展方向

- 聚合页内嵌快捷审批操作（通过/驳回按钮，无需跳转）
- 审批统计图表（审批时效、通过率）
- 审批超时自动提醒（结合预警引擎）
- 更多审批类型接入（外包物业完工审批、电子签章等）

---

## 八、通用审批 API 对接（v1.8 新增）

> API_CONTRACT v1.7 §8B 已新增通用审批队列端点，可替代各业务模块分散的 pending 查询逻辑。

### 8.1 后端审批 API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/approvals | 待审批列表（支持 `status`、`type` 过滤） |
| PATCH | /api/approvals/:id | 审批操作（`approve` / `reject`，附审批意见） |

### 8.2 审批类型枚举（`approval_type`）

| 值 | 对应业务 | 点击跳转 |
|----|---------|---------|
| `contract_termination` | 合同提前终止审批 | `/contracts/:id` |
| `deposit_refund` | 押金退还确认 | `/finance/deposits/:id` |
| `invoice_adjustment` | 账单调整审批 | `/finance/invoices/:id` |
| `sublease_submission` | 子租赁数据提交审核 | `/subleases/:id` |

### 8.3 迁移建议

Phase 1 审批聚合页仍可使用各业务模块 pending 查询（§5.3 中 `APPROVAL_TYPES` 对应各自 API），但建议逐步迁移到通用审批 API：

1. **Store 层**：新增 `useApprovalStore`，调用 `GET /api/approvals` 替代 5 个独立 pending 查询
2. **审批操作**：卡片内嵌审批按钮时可直接调用 `PATCH /api/approvals/:id`，无需跳转
3. **错误处理**：新增 3 个错误码 — `APPROVAL_NOT_FOUND`、`APPROVAL_ALREADY_PROCESSED`、`APPROVAL_SELF_REVIEW`
4. **权限动态校验**：审批操作权限由后端根据 `approval_type` 动态检查，前端仅需传 `action` + `comment`
