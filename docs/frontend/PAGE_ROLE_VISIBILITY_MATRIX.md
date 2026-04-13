# PropOS 页面-角色可见性矩阵

> **版本**: v1.0  
> **日期**: 2026-04-13  
> **依据**: RBAC_MATRIX v2.0 / PAGE_SPEC v1.8 / RBAC_PROTOTYPE_PLAN v2.0  
> **用途**: 前端页面关级 RBAC 实施参考；角色切换验收基线  
> **策略**: **整区域隐藏**（无权限时隐藏整个卡片/区域/列，不显示 `***`）

---

## 一、数据分级定义

系统所有可展示数据分为 4 个敏感级别，角色可见性基于此分级控制：

| 级别 | 名称 | 内容举例 | 说明 |
|------|------|---------|------|
| **L1** | 公开信息 | 楼栋名称、楼层号、单元编号、房源状态标签、业态类型 | 所有已登录角色可见 |
| **L2** | 业务数据 | 出租率%、合同数量（份）、到期天数、工单列表、KPI 得分 | 除 MS（仅工单域）外均可见 |
| **L3** | 财务数据 | ¥ 金额（租金/押金/NOI/收款/费用）、收款率%、NOI Margin% | SA/OM/FS/LS(部分)/RV(只读聚合) 可见 |
| **L4** | 敏感信息 | 证件号、手机号、姓名+联系方式组合 | SA/OM/FS/LS(仅自管) 可见 |

---

## 二、角色-数据级别总览

| 角色 | L1 公开 | L2 业务 | L3 财务 | L4 敏感 | 写操作范围 |
|------|:-------:|:-------:|:-------:|:-------:|-----------|
| `super_admin` (SA) | ✅ | ✅ | ✅ | ✅ | 全部模块 |
| `operations_manager` (OM) | ✅ | ✅ | ✅ | ✅ | 资产/合同/工单/二房东/预警/KPI管理 |
| `finance_staff` (FS) | ✅ | ✅ | ✅ | ✅¹ | 财务核销/支出/预算/押金/营业额审批 |
| `leasing_specialist` (LS) | ✅ | ✅ | ⚠️² | ✅¹ | 合同/递增模板/二房东/导入(限合同) |
| `property_inspector` (PI) | ✅ | ✅ | ❌ | ❌ | 抄表/KPI申诉 |
| `maintenance_staff` (MS) | ✅ | ⚠️³ | ❌ | ❌ | 工单/抄表/KPI申诉 |
| `report_viewer` (RV) | ✅ | ✅ | ✅⁴ | ❌ | 无（纯只读） |

**注释**:
1. FS/LS 仅可见自身管辖范围内的 L4 数据（后端行级过滤）
2. LS 的 L3 限定为关联账单金额，不含全局 NOI 报表
3. MS 的 L2 限定为工单域（工单列表/详情/KPI 自身得分），不含资产/合同业务数据
4. RV 的 L3 为只读聚合数据（NOI/WALE/出租率/收款率），无明细级操作

---

## 三、页面级详细矩阵

### 3.0 矩阵图例

- ✅ = 可达，完整内容可见
- 📖 = 可达，部分区域隐藏（见备注）
- 🔒 = 路由守卫拦截，重定向至首页
- ❌ = Tab 不可见 + 路由守卫拦截

### 3.1 Dashboard 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **Home** | `/` | ✅ | ✅ | 📖 | 📖 | 📖 | 📖 | 📖 | 见 §4.1 |
| **Profile** | `/profile` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 无隐藏 |

**§4.1 Home 页角色适配**:

| 区域 | 所需权限 | SA/OM | FS | LS | PI | MS | RV |
|------|---------|:-----:|:--:|:--:|:--:|:--:|:--:|
| 指标卡-NOI | `finance.read` + `canAccessGlobalNOI` | ✅ NOI | ❌→收款率 | ❌→收款率 | ❌→在租合同 | ❌→空置房 | ✅ NOI |
| 指标卡-收款率 | `finance.read` | ✅ | ✅ | ✅ | ❌→WALE面积 | ❌→空置房 | ✅ |
| 三业态概览 | `assets.read` | ✅ | ✅ | ✅ | ✅ | ❌ 隐藏 | ✅ |
| 运营预警 | `alerts.read` | ✅ | ✅ | ✅ | ❌ 隐藏 | ❌ 隐藏 | ✅ |
| 快捷操作 | 各按钮独立 permission | 全部 | 部分 | 部分 | 部分 | 部分 | 部分 |
| 待办任务-合同 | `contracts.read` | ✅ | ✅ | ✅ | ✅ | ❌ 隐藏 | ✅ |
| 待办任务-工单 | `workorders.read` | ✅ | ✅ | ❌ 隐藏 | ✅ | ✅ | ❌ 隐藏 |
| 待办任务-二房东 | `sublease.read` | ✅ | ✅ | ✅ | ❌ 隐藏 | ❌ 隐藏 | ✅ |
| 待办任务-财务 | `finance.read` | ✅ | ✅ | ✅ | ❌ 隐藏 | ❌ 隐藏 | ✅ |

### 3.2 Assets 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **Assets** | `/assets` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | 📖 | 见 §4.2 |
| **BuildingFloors** | `/assets/:id` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | 📖 | 同上 |
| **FloorPlan** | `/assets/:id/:floor` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | 📖 | 见 §4.3 |
| **UnitDetail** | `/assets/:id/:floor/:unitId` | ✅ | ✅ | 📖 | 📖 | 📖 | ❌ | 📖 | 见 §4.4 |

**§4.2 Assets / BuildingFloors 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 导入按钮 | `import.execute` | 隐藏按钮 |
| 导出按钮 | `assets.read`（所有有权角色可导出） | 不隐藏 |
| 出租率百分比 | `assets.read` | 可见（L2 业务数据） |
| ¥ 金额指标（如有） | `finance.read` | 隐藏整个区域 |

**§4.3 FloorPlan SVG 图层控制**:

| 图层 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 状态图层（已租/空置/非可租） | `assets.read` | 默认可见 |
| 二房东图层 | `sublease.read` | 图层切换器禁用该选项 |
| NOI 图层 | `finance.read` | 图层切换器禁用该选项 |
| 到期图层 | `contracts.read` | 图层切换器禁用该选项（MS 不可见） |

**§4.4 UnitDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 基础信息（编号/楼栋/面积/状态） | `assets.read` | 可见 |
| 月租金 / 单价 / 市场价 | `finance.read` | 隐藏整个「租金信息」卡片 |
| 装修费用 / 改造记录 ¥ | `finance.read` | 隐藏费用数字，保留改造记录描述 |
| 关联租户名称 | `contracts.read` | 可见（L1） |
| 编辑/拆分/合并按钮 | `assets.write` | 隐藏按钮 |
| 新增改造记录 | `assets.write` | 隐藏按钮 |

### 3.3 Contracts 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **Contracts** | `/contracts` | ✅ | ✅ | 📖 | ✅ | 📖 | ❌ | 📖 | 见 §4.5 |
| **ContractDetail** | `/contracts/:id` | ✅ | ✅ | 📖 | ✅ | 📖 | ❌ | 📖 | 见 §4.6 |
| **EscalationTemplates** | `/contracts/escalation-templates` | ✅ | ✅ | 🔒 | ✅ | 🔒 | ❌ | 🔒 | 仅 contracts.write |
| **TenantDetail** | `/tenants/:id` | ✅ | ✅ | ✅ | ✅ | 📖 | ❌ | 📖 | 见 §4.7 |

**§4.5 Contracts 列表角色适配**（已有部分实现）:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 列表-月租金列 | `canViewContractAmounts(role)` | PI: 隐藏金额列 |
| 列表-单价列 | `canViewContractAmounts(role)` | PI: 隐藏单价列 |
| 新建合同按钮 | `contracts.write` | FS/PI/RV: 隐藏 |
| 模板管理入口 | `contracts.write` | FS/PI/RV: 隐藏 |
| 导入按钮 | `import.execute` + `contracts.write` | 非 SA/OM/LS: 隐藏 |

**§4.6 ContractDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 基础信息（编号/起止日期/状态） | `contracts.read` | 可见 |
| 月租金 / 押金 / 递增规则金额 | `canViewContractAmounts(role)` | PI: 隐藏整个「财务信息」卡片 |
| 递增时间线（含未来金额） | `canViewContractAmounts(role)` | PI: 隐藏整个「递增预测」区域 |
| 租户联系方式（手机/邮箱） | `canViewPII(role)` | RV: 隐藏联系方式行 |
| 租户证件号 | `canViewPII(role)` | RV: 隐藏证件号行 |
| 编辑/终止/续签按钮 | `contracts.write` | 非 SA/OM/LS: 隐藏 |

**§4.7 TenantDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 租户名称 / 类型 / 信用等级 | `contracts.read` | 可见 |
| 证件号（已后端脱敏：****1234） | `canViewPII(role)` | RV/PI: 隐藏整行 |
| 手机号（已后端脱敏：****5678） | `canViewPII(role)` | RV/PI: 隐藏整行 |
| 合同历史列表 | `contracts.read` | 可见（金额列按 §4.5 规则） |
| 工单列表 | `workorders.read` | FS/RV: 隐藏整个工单区域 |

### 3.4 Finance 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **Finance** | `/finance` | ✅ | ✅ | ✅ | ✅ | ❌ | 📖 | ✅ | 已实现 6 视图 |
| **Invoices** | `/finance/invoices` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.8 |
| **InvoiceDetail** | `/finance/invoices/:id` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.9 |
| **PaymentList** | `/finance/payments` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.10 |
| **PaymentForm** | `/finance/invoices/:id/pay` | ✅ | 🔒 | ✅ | 🔒 | ❌ | ❌ | 🔒 | 仅 finance.write |
| **MeterReadingList** | `/finance/meter-readings` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔒 | 见 §4.11 |
| **MeterReadingForm** | `/finance/meter-readings/new` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔒 | meterReading.write |
| **ExpenseList** | `/finance/expenses` | ✅ | ✅ | ✅ | 🔒 | ❌ | ❌ | 📖 | 见 §4.12 |
| **ExpenseForm** | `/finance/expenses/new` | ✅ | 🔒 | ✅ | 🔒 | ❌ | ❌ | 🔒 | 仅 finance.write |
| **TurnoverReports** | `/finance/turnover-reports` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.13 |
| **DepositLedger** | `/finance/deposits` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.14 |
| **NoiBudget** | `/finance/noi-budget` | ✅ | 🔒 | ✅ | 🔒 | ❌ | ❌ | 🔒 | 仅 finance.write |
| **CostReport** | `/work-orders/cost-report` | ✅ | ✅ | ✅ | 🔒 | ❌ | ❌ | 📖 | 见 §4.15 |
| **RevenueDetail** | `/finance/revenue-detail` | ✅ | ✅ | ✅ | 📖 | ❌ | ❌ | 📖 | 见 §4.16 |

**§4.8 Invoices 列表角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 账单金额列 | `finance.read` | 可见（已在路由守卫过滤了无权角色） |
| 作废/核销按钮 | `finance.write` | LS/RV: 隐藏操作列 |
| 导出按钮 | `finance.read` | 可见 |
| 批量催缴按钮 | `finance.write` | LS/RV: 隐藏 |

**§4.9 InvoiceDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 金额明细（含税/不含税/已付/余额） | `finance.read` | 可见 |
| 录入收款按钮 | `finance.write` | LS/RV: 隐藏 |
| 作废按钮 | `finance.write` | LS/RV: 隐藏 |
| 开票按钮 | `finance.write` | LS/RV: 隐藏 |
| 催缴记录 | `finance.read` | 可见 |

**§4.10 PaymentList 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 收款记录列表 | `finance.read` | 可见 |
| 新增收款按钮 | `finance.write` | LS/RV: 隐藏 |
| 对账标记按钮 | `finance.write` | LS/RV: 隐藏 |

**§4.11 MeterReadingList 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 抄表记录列表 | `meterReading.write` | 可见（路由已过滤） |
| 生成账单按钮 | `finance.write` | 非 SA/FS: 隐藏 |
| 新增录入按钮 | `meterReading.write` | 可见（路由已过滤） |

**§4.12 ExpenseList 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 费用列表 | `finance.read` | 可见 |
| 新增费用按钮 | `finance.write` | RV: 隐藏 |
| 费用金额 | `finance.read` | 可见 |

**§4.13 TurnoverReports 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 营业额报表列表 | `finance.read` | 可见 |
| 审批按钮（通过/驳回） | `turnoverReview.approve` | LS/RV: 隐藏 |
| 营业额金额 | `finance.read` | 可见 |

**§4.14 DepositLedger 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 押金账本列表 | `deposit.read` | 可见 |
| 退还/冲抵按钮 | `deposit.write` | LS/RV: 隐藏 |
| 押金金额 | `deposit.read` | 可见 |

**§4.15 CostReport 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 费用报表 | `finance.read` | 可见 |
| 供应商费用排名 | `finance.read` | 可见（RV 只读） |

**§4.16 RevenueDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 收入明细 | `finance.read` | 可见 |
| 按业态分拆 | `finance.read` | 可见（RV 只读） |

### 3.5 Analytics 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **NOIDashboard** | `/dashboard/noi-detail` | ✅ | ✅ | ✅ | 🔒 | ❌ | ❌ | ✅ | 见 §4.17 |
| **WALEDashboard** | `/wale` | ✅ | ✅ | 📖 | ✅ | 📖 | ❌ | 📖 | 见 §4.18 |
| **KPIDashboard** | `/finance/kpi` | ✅ | ✅ | 📖 | 📖 | 📖 | 📖 | 📖 | 见 §4.19 |
| **KPISchemes** | `/finance/kpi/schemes` | ✅ | ✅ | 🔒 | 🔒 | 🔒 | 🔒 | 🔒 | 仅 kpi.manage |
| **KPISchemeForm** | `/finance/kpi/schemes/*` | ✅ | ✅ | 🔒 | 🔒 | 🔒 | 🔒 | 🔒 | 仅 kpi.manage |

**§4.17 NOIDashboard 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| NOI 总览指标 | `canAccessGlobalNOI` | LS: 路由拦截（不可达） |
| 分业态 NOI 明细 | `finance.read` | 可见（已通过路由过滤） |
| 租户级应收明细 | `finance.read` | RV: 隐藏租户名列（仅显示聚合） |

**§4.18 WALEDashboard 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| WALE 总指标 | `contracts.read` | 可见 |
| 到期合同列表-租金列 | `canViewContractAmounts` | PI: 隐藏租金列 |
| 到期合同列表-租户名 | `contracts.read` | 可见 |
| 租约健康度 | `contracts.read` | 可见 |

**§4.19 KPIDashboard 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 个人 KPI 得分 | `kpi.view` | 可见（所有角色） |
| 全员排名列表 | `kpi.manage` | 非 SA/OM: 隐藏整个排名区域 |
| 申诉入口 | `kpi.appeal` | RV: 隐藏申诉按钮 |
| 方案管理入口 | `kpi.manage` | 非 SA/OM: 隐藏入口 |

### 3.6 WorkOrders 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **WorkOrders** | `/work-orders` | ✅ | ✅ | ❌ | 📖 | 📖 | ✅ | ❌ | 见 §4.20 |
| **WorkOrderDetail** | `/work-orders/:id` | ✅ | ✅ | ❌ | 📖 | 📖 | ✅ | ❌ | 见 §4.21 |
| **Suppliers** | `/work-orders/suppliers` | ✅ | ✅ | ❌ | 🔒 | 🔒 | 🔒 | ❌ | 仅 SA/OM |

**§4.20 WorkOrders 列表角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 工单列表 | `workorders.read` | 可见 |
| 创建工单按钮 | `workorders.write` | LS/PI: 隐藏 |
| 费用摘要 | `finance.read` | LS/PI: 隐藏费用列 |
| 指派操作 | `workorders.write` | LS/PI: 隐藏 |

**§4.21 WorkOrderDetail 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 工单基础信息 | `workorders.read` | 可见 |
| 费用分解（材料/人工/合计） | `finance.read` | LS/PI/MS: 隐藏整个费用卡片 |
| 验收/完工按钮 | `workorders.write` | LS/PI: 隐藏 |
| 状态变更操作 | `workorders.write` | LS/PI: 隐藏 |
| 检查清单 | `workorders.read` | 可见 |

### 3.7 Subleases 模块

| 页面 | 路由 | SA | OM | FS | LS | PI | MS | RV | 隐藏规则 |
|------|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---------|
| **Subleases** | `/subleases` | ✅ | ✅ | 📖 | ✅ | ❌ | ❌ | 📖 | 见 §4.22 |
| **SubleasePenetration** | `/subleases/analytics` | ✅ | ✅ | 📖 | 📖 | ❌ | ❌ | 📖 | 见 §4.23 |

**§4.22 Subleases 列表角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 子租赁列表 | `sublease.read` | 可见 |
| 审核按钮（通过/驳回） | `sublease.write` | FS/RV: 隐藏 |
| 月租金/分成比例金额 | `finance.read` | RV: 可见(只读)；FS: 可见 |
| 穿透看板入口 | `sublease.read` | 可见 |

**§4.23 SubleasePenetration 角色适配**:

| 区域 | 所需权限 | 无权限时处理 |
|------|---------|------------|
| 穿透率聚合指标 | `sublease.read` | 可见 |
| 主合同租金 / 终端租金 | `finance.read` + `sublease.read` | LS: 隐藏金额（仅看穿透率%） |
| 加价率明细 | `finance.read` | LS: 隐藏 |

---

## 四、整区域隐藏实现规则

### 4.0 统一 Helper 函数

新增于 `frontend/src/app/auth/permissions.ts`：

| Helper | 判断逻辑 | 隐藏对象 |
|--------|---------|---------|
| `canViewFinancialData(role)` | `role !== 'property_inspector' && role !== 'maintenance_staff'` | 所有 ¥ 金额区域 |
| `canViewPII(role)` | SA/OM/FS/LS 返回 true | 证件号/手机号/联系方式 |
| `canAccessGlobalNOI(role)` | SA/OM/RV 返回 true | 已有，不变 |
| `canViewContractAmounts(role)` | `role !== 'property_inspector'` | 已有，不变 |

### 4.1 隐藏策略

1. **整区域隐藏**：无权限时完全不渲染该 DOM 节点（`{condition && <Component />}`），不使用 CSS `display:none`
2. **不使用 MaskedField**：不显示 `***`，而是整块隐藏
3. **唯一例外**：TenantDetail 的证件号/手机号保留后端脱敏展示（`****1234`），因为后端已脱敏
4. **操作按钮**：统一使用 `<Can permission="xxx">` 包裹
5. **无闪烁**：Auth Context 初始化同步完成（localStorage），不会出现先渲染后隐藏

### 4.2 FloorPlan SVG 图层控制

| 图层 | 权限 | 无权限处理 |
|------|------|----------|
| 状态图层 | `assets.read` | 默认可见 |
| 二房东图层 | `sublease.read` | 图层切换器中禁用选项（灰色 + tooltip "无权限"） |
| NOI 图层 | `finance.read` | 图层切换器中禁用选项 |
| 到期图层 | `contracts.read` | MS 时禁用选项 |

---

## 五、ROUTE_RULES 补全清单

当前 `permissions.ts` 缺失以下路由规则，需补全：

| 路由 | 所需权限 | allowedRoles |
|------|---------|-------------|
| `/finance/meter-readings` | `meterReading.write` | — |
| `/finance/meter-readings/new` | `meterReading.write` | — |
| `/finance/expenses` | `finance.read` | SA, OM, FS, RV |
| `/finance/expenses/new` | `finance.write` | SA, FS |
| `/finance/turnover-reports` | `finance.read` | SA, OM, FS, LS, RV |
| `/finance/deposits` | `deposit.read` | SA, OM, FS, LS, RV |
| `/finance/payments` | `finance.read` | SA, OM, FS, LS, RV |
| `/finance/revenue-detail` | `finance.read` | SA, OM, FS, LS, RV |
| `/finance/kpi/schemes` | `kpi.manage` | SA, OM |
| `/finance/kpi/schemes/.+` | `kpi.manage` | SA, OM |
| `/dashboard/noi-detail` | `finance.read` | SA, OM, RV |
| `/subleases/analytics` | `sublease.read` | SA, OM, FS, LS, RV |
| `/tenants/.+` | `contracts.read` | SA, OM, FS, LS, PI, RV |
| `/work-orders/suppliers` | `workorders.read` | SA, OM |
| `/work-orders/cost-report` | `finance.read` | SA, OM, FS, RV |

---

## 六、验收清单

逐一切换 7 个 Mock 角色（Profile 页角色切换器），验证以下项：

### 6.1 路由守卫验证

| 验证项 | 验证方法 |
|--------|---------|
| MS 不可达 `/assets` | 直接输入 URL，应重定向至 `/` |
| MS 不可达 `/contracts` | 直接输入 URL，应重定向至 `/` |
| PI 不可达 `/finance` | 直接输入 URL，应重定向至 `/` |
| RV 不可达 `/work-orders` | 直接输入 URL，应重定向至 `/` |
| LS 不可达 `/dashboard/noi-detail` | 直接输入 URL，应重定向至 `/` |
| 非 SA/OM 不可达 `/finance/kpi/schemes` | 直接输入 URL，应重定向至 `/` |
| 非 SA/FS 不可达 `/finance/noi-budget` | 直接输入 URL，应重定向至 `/` |
| 非 SA/FS 不可达 `/finance/expenses/new` | 直接输入 URL，应重定向至 `/` |

### 6.2 Tab 可见性验证

| 角色 | 总览 | 资产 | 合同 | 工单 | 财务 |
|------|:----:|:----:|:----:|:----:|:----:|
| SA | ✅ | ✅ | ✅ | ✅ | ✅ |
| OM | ✅ | ✅ | ✅ | ✅ | ✅ |
| FS | ✅ | ✅ | ✅ | ❌ | ✅ |
| LS | ✅ | ✅ | ✅ | ✅ | ✅ |
| PI | ✅ | ✅ | ✅ | ✅ | ❌ |
| MS | ✅ | ❌ | ❌ | ✅ | ❌ |
| RV | ✅ | ✅ | ✅ | ❌ | ✅ |

### 6.3 区域隐藏验证（关键场景）

| 场景 | 角色 | 预期行为 |
|------|------|---------|
| ContractDetail 月租金 | PI | 整个「财务信息」卡片不可见 |
| ContractDetail 证件号 | RV | 证件号行不可见 |
| UnitDetail 月租金 | PI/MS | 整个「租金信息」卡片不可见 |
| FloorPlan NOI 图层 | PI/MS | 图层切换器中 NOI 选项灰色不可点 |
| NOIDashboard | LS | URL 直接访问被重定向 |
| KPIDashboard 全员排名 | LS/FS/PI/MS | 排名区域不可见，仅见个人得分 |
| WorkOrderDetail 费用分解 | PI/MS | 费用卡片不可见 |
| Invoices 核销按钮 | RV | 操作列不可见 |
| Home 运营预警 | PI/MS | AlertRadar 区域不可见 |

---

## 附录：工作量分批执行计划

| Batch | 模块 | 页面数 | 优先级 |
|-------|------|-------|--------|
| **Phase 2** | permissions.ts + ROUTE_RULES | 1 文件 | P0 前置 |
| **3A** | Dashboard (Home) | 1 页 | P0 |
| **3B** | Assets | 4 页 | P1 |
| **3C** | Contracts | 4 页 | P0 |
| **3D** | Finance | 14 页 | P1 |
| **3E** | Analytics | 5 页 | P1 |
| **3F** | WorkOrders | 2 页 | P2 |
| **3G** | Subleases | 2 页 | P2 |
| **3H** | 其他 | 2 页 | P2 |

每个 Batch 完成后切换全部 7 角色执行该模块验收，确认无回归后再进入下一 Batch。
