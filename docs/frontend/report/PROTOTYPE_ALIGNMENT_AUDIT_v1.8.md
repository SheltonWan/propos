# PropOS 原型项目与 PAGE_WIREFRAMES v1.8 对齐审计报告

| 元信息 | 值 |
|--------|------|
| 文档版本 | v1.8 |
| 审计日期 | 2026-04-15 |
| 对齐基线 | PAGE_WIREFRAMES v1.8 正文 + 附录 A |
| 裁决文档 | PAGE_SPEC v1.8 |
| 审计对象 | frontend/ React 原型项目 |

---

## 一、审计范围与判定规则

### 1.1 审计范围

本次审计只回答三个问题：

1. 原型项目哪些页面**需要修改**才能与 [PAGE_WIREFRAMES_v1.8.md](docs/frontend/PAGE_WIREFRAMES_v1.8.md) 对齐。
2. 线框正文中的哪些正式页面在原型项目中**遗漏了**。
3. 原型项目中哪些页面已经超出当前正式范围，属于**多余页 / 旧方案残留 / 演示页**。

### 1.2 事实来源

- 正式页面基线： [PAGE_WIREFRAMES_v1.8.md](docs/frontend/PAGE_WIREFRAMES_v1.8.md) 正文与附录 A
- 争议裁决： [PAGE_SPEC_v1.8.md](docs/frontend/PAGE_SPEC_v1.8.md)
- 原型实际路由： [frontend/src/app/routes.tsx](frontend/src/app/routes.tsx)
- 原型实际壳层： [frontend/src/app/Layout.tsx](frontend/src/app/Layout.tsx)
- 原型主导航： [frontend/src/app/components/BottomTabBar.tsx](frontend/src/app/components/BottomTabBar.tsx)
- 演示残留页： [frontend/src/app/pages/Showcase.tsx](frontend/src/app/pages/Showcase.tsx)

### 1.3 判定规则

- **遗漏**：线框正文中的正式独立页面 / 路由，在原型中没有对应可达路由或页面文件。
- **需修改**：原型中存在对应页面，但端别、路由、入口位置、模块归属或容器形态与线框不一致。
- **多余**：原型中存在页面，但在线框正文无对应，且经 PAGE_SPEC 复核后仍属于 Legacy、过期方案或演示残留。
- **可复用**：页面主体内容与正式范围基本一致，后续以路由、容器或信息架构微调为主。

### 1.4 本次不计入遗漏统计的内容

- 附录 B Legacy 页面：收款记录、收入详情、供应商管理、维修成本报表
- 仅用于展示弹窗态的 Showcase wrapper
- 线框中的 Dialog / Drawer，如果原型已以内嵌视图或局部状态方式实现，不单独计为“缺页”

---

## 二、总体结论

| 指标 | 结果 |
|------|------|
| 线框正式范围 | Admin 49 + Flutter 21 + Portal 5 = **75 个正式视图/页面** |
| 原型页面文件 | **48** 个 |
| 原型已注册路由 | **47** 条 |
| 未注册页面文件 | **1** 个：Showcase |
| 正式范围缺失页 | **7 组** |
| 正式范围外多余页 | **8 项** |
| 关键需修改页面 / 路由组 | **12 组** |

### 2.1 结论摘要

原型项目并不是“完全没做”，相反，它已经覆盖了大量正式功能页面；真正的问题在于：

1. **壳层架构错位**：原型把几乎所有页面都放进了手机壳布局中，和线框中的 Admin PC 主框架不一致。
2. **三端边界混用**：Admin、Flutter、Portal 没有在原型中拆开，多个页面被压成了同一套路由或同一套布局。
3. **仍保留旧方案页面**：Legacy 页和个人中心、穿透分析等旧内容仍在原型中作为正式路由存在。
4. **Portal 与少数新增正式页未补齐**：二房东外部门户、预警中心、催收双端页、子租赁录入/导入等正式页面仍未落到原型路由层。
5. **新增移动分析/待办页尚未收口**：NOI、WALE、审批已具备可复用内容，但仍沿用旧的单端单壳表达，未按 v1.8 新口径拆成“移动查看页 + PC 工作台”。

### 2.2 可以直接下的判断

- 如果目标是“让原型设计项目与 PAGE_WIREFRAMES v1.8 正式口径一致”，**不能只补缺页**，必须同时做一次信息架构收敛。
- 当前更接近“单端原型集合”，而不是“Admin PC + Flutter + Portal 三端正式原型”。

---

## 三、跨页面结构级问题

这些问题不是单个页面造成的，会波及一整批页面。

### 3.1 所有受保护路由都被包在手机壳中

[Layout.tsx](frontend/src/app/Layout.tsx) 中的 `AuthLayout` 对所有登录后页面统一套用了固定宽度手机壳容器，导致：

- Admin 页面没有侧边栏 + 顶部栏 + 面包屑的 PC 布局
- 系统设置、审批、审计、资产后台、财务后台全部被渲染为移动设备样式
- 线框 1.1 的 Admin PC 主框架在原型中没有真正落地

**影响页面**：几乎全部 Admin 页面。

### 3.2 底部 TabBar 被用作全局主导航

[BottomTabBar.tsx](frontend/src/app/components/BottomTabBar.tsx) 只定义了 5 个移动端 Tab：首页、资产、合同、工单、财务。它适合 Flutter 移动端首页壳，但不适合 Admin 端。

**影响**：

- Admin 顶层导航层级被抹平
- 系统设置、通知、审批、二房东门户缺少正式导航归属
- 线框中“通知中心、审批队列、系统设置、二房东外部门户”都没有独立的 PC 导航定位

### 3.3 首页入口仍沿用旧方案

[Home.tsx](frontend/src/app/pages/Home.tsx) 当前保留：

- 单一通知铃铛入口
- 个人中心入口 `/profile`
- 若干混合型快捷入口

而线框 v1.8 正式口径要求：

- Admin 顶部应区分“预警铃铛”与“通知铃铛”
- 不再以“个人中心”作为正式主入口页面
- Admin 首页和 Flutter 移动端首页应分端表达，而不是复用同一视觉容器

### 3.4 双端分析与待办页还没真正拆层

PAGE_SPEC v1.8 现已把 4 个新增移动页纳入正式范围：

- `pages/dashboard/noi-detail`
- `pages/dashboard/wale-detail`
- `pages/approvals/index`
- `pages/finance/dunning`

但原型当前只有“单页复用”或“尚未实现”的状态：

- `NOIDashboard`、`WALEDashboard` 还没有显式区分移动分析视图与 Admin 工作台。
- `Approvals` 还没有形成移动待办页的信息密度与交互层级。
- `Dunning` 双端页仍缺失。

---

## 四、关键页面映射矩阵

下表只覆盖对本次结论最关键的正式页面，足以支撑“需修改 / 遗漏 / 多余”的判定。

| 线框正式页 | 正式路由/路径 | 原型对应 | 判定 |
|------|------|------|------|
| 登录页 — Admin | `/login` | `Login` | 需修改：存在，但仍为手机壳登录态，未体现 Admin PC 视觉口径 |
| 登录页 — Flutter | `pages/auth/login` | `Login` | 需修改：与 Admin 登录共用一页，未区分端别 |
| 首页 — Admin | `/dashboard` | `Home` at `/` | 需修改：路由不一致，且首页仍为移动壳布局 |
| 首页 — Flutter | `pages/dashboard/index` | `Home` at `/` | 需修改：与 Admin 首页复用同一路由 |
| NOI 分析/明细页（Flutter + Admin） | `pages/dashboard/noi-detail` / `/dashboard/noi-detail` | `NOIDashboard` | 需修改：内容可复用，但尚未拆成移动分析视图与 Admin 工作台两种表达 |
| WALE 分析/明细页（Flutter + Admin） | `pages/dashboard/wale-detail` / `/dashboard/wale-detail` | `WALEDashboard` at `/wale` | 需修改：路由不一致，且尚未拆成移动分析视图与 Admin 工作台 |
| KPI 考核看板 | `/finance/kpi` / `pages/finance/kpi` | `KPIDashboard` | 需修改：内容可复用，但 Admin/uni 未拆开 |
| 资产概览页 | `/assets` / `pages/assets/index` | `Assets` | 需修改：同页承担双端角色 |
| 楼栋详情页 | `/assets/buildings/:id` | `BuildingFloors` at `/assets/:buildingId` | 需修改：路由命名不一致 |
| 楼层热区图 | `/assets/buildings/:bid/floors/:fid` / `pages/assets/floor-plan` | `FloorPlan` at `/assets/:buildingId/:floor` | 需修改：路由与端别表达不一致 |
| 房源详情页 | `/assets/units/:id` | `UnitDetail` at `/assets/:buildingId/:floor/:unitId` | 需修改：正式口径是单元页，原型仍挂在楼层路径下 |
| Excel 批量导入页 | `/assets/import` | `UnitImport` | 基本对齐 |
| 合同列表页 | `/contracts` / `pages/contracts/index` | `Contracts` | 基本对齐 |
| 合同详情页 | `/contracts/:id` / `pages/contracts/detail` | `ContractDetail` | 基本对齐 |
| 租客列表页 | `/tenants` | `TenantList` | 基本对齐 |
| 租客详情页 | `/tenants/:id` | `TenantDetail` | 基本对齐 |
| 财务概览页 | `/finance` / `pages/finance/index` | `Finance` | 需修改：双端合页表达，且仍在手机壳内 |
| 账单列表页 | `/finance/invoices` / `pages/finance/invoices` | `Invoices` | 基本对齐 |
| 账单详情页 | `/finance/invoices/:id` | `InvoiceDetail` | 基本对齐 |
| 收款录入页 | `/finance/invoices/:id/pay` | `PaymentForm` | 基本对齐 |
| 水电抄表录入页 | `/finance/meter-readings/new` | `MeterReadingForm` | 基本对齐 |
| 营业额申报管理页 | `/finance/turnover-reports` | `TurnoverReports` | 基本对齐 |
| 费用列表页 | `/finance/expenses` | `ExpenseList` | 基本对齐 |
| 费用录入页 | `/finance/expenses/new` | `ExpenseForm` | 基本对齐 |
| 水电抄表列表页 | `/finance/meter-readings` | `MeterReadingList` | 基本对齐 |
| 押金台账页 | `/finance/deposits` | `DepositLedger` | 基本对齐 |
| NOI 预算管理页 | `/finance/noi-budget` | `NoiBudget` | 基本对齐 |
| 工单列表页 | `/workorders` / `pages/workorders/index` | `WorkOrders` at `/work-orders` | 需修改：命名空间不一致 |
| 工单提报页 | `/workorders/new` / `pages/workorders/new` | `WorkOrderForm` at `/work-orders/new` | 需修改：命名空间不一致 |
| 工单详情页 | `/workorders/:id` | `WorkOrderDetail` at `/work-orders/:orderId` | 需修改：命名空间与参数语义不一致 |
| 二房东管理列表 | `/subleases` | `Subleases` | 需修改：当前页面混入穿透率卡片和分析入口，不符合正式 8.1 |
| 子租赁详情页 | `/subleases/:id` | `SubleasDetail` | 需修改：参数命名偏旧，且与录入页未分开 |
| 子租赁录入页 | `/subleases/new` / `/subleases/:id/edit` | 无 | 缺失 |
| 二房东登录页 | `/portal/login` | 无 | 缺失 |
| 二房东外部门户列表 | `/portal/subleases` | 无 | 缺失 |
| 二房东外部门户填报页 | `/portal/subleases/:id/edit` | 无 | 缺失 |
| 子租赁导入页 | `/subleases/import` / `/portal/subleases/import` | 无 | 缺失 |
| 用户管理页 | `/settings/users` | `UserManagement` | 需修改：内容可复用，但要迁回 PC Admin 壳层 |
| 组织架构管理页 | `/settings/org` | `OrgManagement` | 需修改：内容可复用，但要迁回 PC Admin 壳层 |
| KPI 方案管理页 | `/settings/kpi/schemes` | `KPISchemes` at `/finance/kpi/schemes` | 需修改：模块归属不对 |
| KPI 方案新建页 | `设置模块步骤页` | `KPISchemeForm` at `/finance/kpi/schemes/new` | 需修改：模块归属不对 |
| KPI 申诉页 | `/settings/kpi/appeal` | `KPIAppeal` at `/finance/kpi/appeal` | 需修改：模块归属不对 |
| 通知中心 | `/notifications` / `pages/notifications` | `Notifications` | 需修改：应明确 Admin + uni 双入口，但当前仅单端单壳表达 |
| 递增模板管理 | `/settings/escalation/templates` | `EscalationTemplates` at `/contracts/escalation-templates` | 需修改：模块归属不对 |
| 审计日志 | `/settings/audit-logs` | `AuditLog` | 需修改：内容可复用，但需回归 PC Admin 壳层 |
| 预警中心 | `/settings/alerts` | 无 | 缺失 |
| 审批队列（Admin + Flutter） | `/approvals` / `pages/approvals/index` | `Approvals` | 需修改：内容可复用，但应拆成移动待办页与 Admin 工作台两种正式表达 |
| 催收管理（Admin + Flutter） | `/finance/dunning` / `pages/finance/dunning` | 无 | 缺失：正式双端页均未落地 |

---

## 五、需要修改的页面 / 路由组

以下页面不是“没有做”，而是“做了但和正式口径不一致”。

### 5.1 登录与首页组

| 原型页面 | 当前路由 | 对齐目标 | 问题 |
|------|------|------|------|
| Login | `/login` | Admin 登录 + Flutter 登录 | 共用一套手机壳登录页，未区分两端 |
| Home | `/` | `/dashboard` + `pages/dashboard/index` | Admin 与 Flutter 首页混页；顶部仍是单铃铛 + 个人中心入口 |

### 5.2 Dashboard 与双端分析路由组

| 原型页面 | 当前路由 | 正式口径 | 问题 |
|------|------|------|------|
| NOIDashboard | `/dashboard/noi-detail` | `pages/dashboard/noi-detail` + `/dashboard/noi-detail` | 已有内容素材，但未拆为移动分析页与 Admin 工作台 |
| WALEDashboard | `/wale` | `pages/dashboard/wale-detail` + `/dashboard/wale-detail` | 路由错误，且未拆为移动分析页与 Admin 工作台 |

### 5.3 资产路由组

| 原型页面 | 当前路由 | 正式口径 | 问题 |
|------|------|------|------|
| BuildingFloors | `/assets/:buildingId` | `/assets/buildings/:id` | 路径结构偏旧 |
| FloorPlan | `/assets/:buildingId/:floor` | `/assets/buildings/:bid/floors/:fid` | 路径结构偏旧 |
| UnitDetail | `/assets/:buildingId/:floor/:unitId` | `/assets/units/:id` | 单元详情仍挂在楼层层级下 |

### 5.4 工单命名空间组

| 原型页面 | 当前路由 | 正式口径 | 问题 |
|------|------|------|------|
| WorkOrders | `/work-orders` | `/workorders` | 命名空间不一致 |
| WorkOrderForm | `/work-orders/new` | `/workorders/new` | 命名空间不一致 |
| WorkOrderDetail | `/work-orders/:orderId` | `/workorders/:id` | 命名空间和参数语义不一致 |

### 5.5 设置模块归位组

| 原型页面 | 当前路由 | 应归位到 | 问题 |
|------|------|------|------|
| EscalationTemplates | `/contracts/escalation-templates` | `/settings/escalation/templates` | 错放在合同模块下 |
| KPISchemes | `/finance/kpi/schemes` | `/settings/kpi/schemes` | 错放在财务模块下 |
| KPISchemeForm | `/finance/kpi/schemes/new` | 设置模块步骤页 | 错放在财务模块下 |
| KPIAppeal | `/finance/kpi/appeal` | `/settings/kpi/appeal` | 错放在财务模块下 |

### 5.6 二房东内部页组

| 原型页面 | 当前路由 | 正式口径 | 问题 |
|------|------|------|------|
| Subleases | `/subleases` | 内部管理列表 | 当前页面混入“穿透率 / 填报完成率 / 穿透分析入口” |
| SubleasDetail | `/subleases/:sublandlordId` | 子租赁详情 `/subleases/:id` | 参数含义沿用旧命名，且未与录入页拆开 |

### 5.7 系统页壳层组

以下页面内容大体可用，但必须从手机壳迁回 Admin PC 主框架：

- `UserManagement`
- `OrgManagement`
- `AuditLog`
- `Approvals`
- `Notifications`
- `NOIDashboard`
- `Finance`

另有一组新增双端页面需要在现有内容基础上补出移动表达：

- `Approvals`：补 `pages/approvals/index` 移动待办层级
- `Notifications`：维持双端入口但分别落到各自壳层

### 5.8 不应继续保留为独立正式页面的路由

| 原型页面 | 当前路由 | 正式口径 | 结论 |
|------|------|------|------|
| ChangePassword | `/profile/change-password` | Admin 修改密码为弹窗 | 应回收为局部流程，不应保留为正式独立页 |

---

## 六、遗漏的正式页面

这些页面已经进入 [PAGE_WIREFRAMES_v1.8.md](docs/frontend/PAGE_WIREFRAMES_v1.8.md) 正文，但原型项目目前没有对应可达路由。

| 缺失页面 | 正式路由 | 说明 |
|------|------|------|
| 子租赁录入页（内部） | `/subleases/new`、`/subleases/:id/edit` | 正式 8.3，当前只有列表和详情 |
| 二房东登录页（外部门户） | `/portal/login` | 正式 8.4 |
| 二房东外部门户列表页 | `/portal/subleases` | 正式 8.5 |
| 二房东外部门户填报页 | `/portal/subleases/:id/edit` | 正式 8.6 |
| 子租赁批量导入页 | `/subleases/import`、`/portal/subleases/import` | 正式 8.7，当前内部和门户入口都未落地 |
| 预警中心 | `/settings/alerts` | 正式 9.9 |
| 催收管理（Admin + Flutter） | `/finance/dunning`、`pages/finance/dunning` | 正式 9.12 / 9.13，当前双端都未落地 |

### 6.1 缺失页优先级

- **P0**：Portal 登录、Portal 列表、Portal 填报、子租赁录入、子租赁导入
- **P1**：预警中心、催收管理双端页

---

## 七、多余页面 / 旧方案残留

这些页面不属于当前正式交付范围，继续保留会干扰页面口径。

| 原型页面 | 路由/位置 | 类型 | 判定依据 |
|------|------|------|------|
| Profile | `/profile` | 旧方案页面 | 线框正文已无个人中心正式页 |
| ChangePassword | `/profile/change-password` | 旧方案页面 | 正式口径是修改密码弹窗，不是独立页 |
| PaymentList | `/finance/payments` | Legacy 页面 | 对应附录 B.1 收款记录列表 |
| RevenueDetail | `/finance/revenue-detail` | Legacy 页面 | 对应附录 B.2 收入详情页 |
| Suppliers | `/work-orders/suppliers` | Legacy 页面 | 对应附录 B.3 供应商管理 |
| CostReport | `/work-orders/cost-report` | Legacy 页面 | 对应附录 B.4 维修成本报表 |
| SubleasePenetration | `/subleases/analytics` | 已清退页面 | 当前正式正文已不再保留穿透分析独立页 |
| Showcase | 页面文件存在但未注册 | 演示残留 | 仅供演示和弹窗态展示，不属于正式信息架构 |

### 7.1 需要同步清理的多余入口

- [Home.tsx](frontend/src/app/pages/Home.tsx) 中的 `/profile` 头像入口
- [Subleases.tsx](frontend/src/app/pages/Subleases.tsx) 中的“穿透分析”按钮
- [WorkOrders.tsx](frontend/src/app/pages/WorkOrders.tsx) 中通向 Suppliers / CostReport 的入口
- [Showcase.tsx](frontend/src/app/pages/Showcase.tsx) 中对 Legacy 页和旧方案页的集中展示

---

## 八、内容层可复用页面

以下页面虽然仍要迁移路由或壳层，但主体内容不建议推倒重做，可以直接作为正式原型的基础：

| 原型页面 | 对应正式页 | 复用建议 |
|------|------|------|
| Invoices | 账单列表页 | 保留主体结构，补 PC 壳层与导出/筛选定位 |
| InvoiceDetail | 账单详情页 | 保留主体结构 |
| PaymentForm | 收款录入页 | 保留主体结构 |
| MeterReadingList | 水电抄表列表页 | 保留主体结构 |
| MeterReadingForm | 水电抄表录入页 | 保留主体结构 |
| ExpenseList | 费用列表页 | 保留主体结构 |
| ExpenseForm | 费用录入页 | 保留主体结构 |
| TurnoverReports | 营业额申报管理页 | 保留主体结构 |
| DepositLedger | 押金台账页 | 保留主体结构 |
| NoiBudget | NOI 预算管理页 | 保留主体结构 |
| TenantList | 租客列表页 | 保留主体结构 |
| TenantDetail | 租客详情页 | 保留主体结构 |
| UnitImport | Excel 批量导入页 | 保留主体结构 |
| UserManagement | 用户管理页 | 保留内容，迁回 PC 壳层 |
| OrgManagement | 组织架构管理页 | 保留内容，迁回 PC 壳层 |
| AuditLog | 审计日志 | 保留内容，迁回 PC 壳层 |
| Approvals | 审批队列 | 保留内容，迁回 PC 壳层 |
| Notifications | 通知中心 | 保留内容，补双端入口说明 |

---

## 九、现有 coverage 文档的使用边界

原型项目已有：

- [frontend/docs/phase1-coverage.json](frontend/docs/phase1-coverage.json)
- [frontend/docs/coverage-report.md](frontend/docs/coverage-report.md)
- [frontend/scripts/check-coverage.js](frontend/scripts/check-coverage.js)

这些文件**只能作为 PRD 覆盖参考**，不能直接替代本次结论，原因有两点：

1. 它们按 PRD 需求项做映射，不按 PAGE_WIREFRAMES 正式页面做映射。
2. 它们只检查页面文件和字符串路由是否存在，无法识别“页面虽然存在但模块归属错了 / 仍在旧信息架构里”。

本次审计中，像 `OrgManagement`、`AuditLog` 这类页面，以 [routes.tsx](frontend/src/app/routes.tsx) 的实际注册情况为准，而不是以 coverage 报告中的旧判断为准。

---

## 十、建议实施顺序

### P0：先解决正式范围缺页与三端架构问题

1. 拆出 Admin PC 壳层，不再让全部页面共用手机壳布局
2. 新增 Portal 4 页：登录、列表、填报、导入
3. 新增内部子租赁录入页与导入页
4. 删除或下线 Profile、SubleasePenetration、Legacy 4 页的正式路由入口

### P1：再做路由与模块归位

1. 把 `WALEDashboard` 改到 `/dashboard/wale-detail`
2. 把工单命名空间从 `/work-orders` 统一为 `/workorders`
3. 把递增模板迁到设置模块
4. 把 KPI 方案 / 申诉迁到设置模块
5. 新增预警中心与催收管理双端页

### P2：最后做页面清理与交互收口

1. 收回 ChangePassword 独立页，改为弹窗 / 局部流程
2. 清理 Showcase 中不再属于正式范围的演示项
3. 给通知中心、首页补上双铃铛与正式入口说明

---

## 十一、最终判断

如果以 [PAGE_WIREFRAMES_v1.8.md](docs/frontend/PAGE_WIREFRAMES_v1.8.md) 作为正式页面基线，那么当前原型项目的状态可以概括为：

- **功能素材不少，可复用面较大**
- **但正式信息架构还没有收口**
- **缺的主要是 Portal、催收双端页、子租赁录入/导入和若干路由归位**
- **多的主要是 Legacy 页面、个人中心旧方案和演示页**

换句话说，下一步不是“整体重做原型”，而是：

1. 先拆三端壳层
2. 再补 7 组缺失正式页
3. 然后下线 8 项过期 / 多余页面
4. 最后把现有可复用页面迁到正确的路由和模块里，并补出新增移动分析/待办层

完成这一步后，原型项目才算真正与 v1.8 正式线框口径对齐。
