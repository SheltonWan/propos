# PropOS 前端原型完善工作计划

| 元信息 | 值 |
|--------|------|
| 版本 | v1.0 |
| 日期 | 2026-04-11 |
| 依据 | PROTOTYPE_GAP_ANALYSIS v1.0 · PRD v1.8 · PAGE_SPEC v1.8 · PAGE_WIREFRAMES v1.8 |
| 目标对象 | `frontend/` React 高保真原型（设计验证用，非生产代码） |
| 技术栈 | React 19 + TypeScript + TailwindCSS + react-router v7 + recharts + lucide-react |

---

## 一、总体目标

根据 PROTOTYPE_GAP_ANALYSIS.md 分析结果，分 **4 个阶段、15 个步骤**完善 `frontend/` 原型设计。核心改动：

1. **结构性修正**：TabBar 第 5 位从「我的」改为「财务」，补齐 M3 财务模块一级入口
2. **新增关键页面**：合同详情、账单列表、工单详情、单元详情、KPI 考核、二房东管理、租客画像等 8 个新页面
3. **优化现有页面**：Assets 三业态卡片、Contracts 楼栋筛选与导航、WorkOrders SLA 标签、FloorPlan 穿透图层
4. **补齐导航链路**：所有列表页→详情页的点击跳转、详情页返回导航

### 约束条件

- 所有数据使用内联 Mock，不连接后端 API
- 不引入新的 npm 依赖，复用现有 lucide-react + recharts
- Admin PC 端专有功能（批量导入/续签/终止/审计日志）不在移动端原型中实现
- 所有新页面严格遵循现有代码模式和视觉规范

---

## 二、文件变更清单

### 需修改的现有文件（9 个）

| 文件路径 | 涉及步骤 | 变更说明 |
|---------|---------|---------|
| `frontend/src/app/components/BottomTabBar.tsx` | Step 1 | Tab 5 改为「财务」+ Coins 图标；Tab 1 改为「总览」 |
| `frontend/src/app/routes.tsx` | Steps 1,4-7,9-11 | 新增全部新页面路由 |
| `frontend/src/app/Layout.tsx` | Step 1 | 更新 `HIDE_TAB_PATTERNS` 隐藏规则 |
| `frontend/src/app/pages/Home.tsx` | Steps 3,8 | 增加头像入口、收款率指标卡、逾期账单预警类型、"查看账单"快捷入口 |
| `frontend/src/app/pages/Profile.tsx` | Step 3 | 增加返回导航栏（不再作为 Tab 页） |
| `frontend/src/app/pages/Assets.tsx` | Step 12 | 顶部增加三业态并列对比卡片 |
| `frontend/src/app/pages/Contracts.tsx` | Step 14 | 楼栋筛选、列表卡片导航、月租金合计 |
| `frontend/src/app/pages/WorkOrders.tsx` | Step 13 | SLA 标签、OpEx/CapEx 选择器、导航到详情 |
| `frontend/src/app/pages/FloorPlan.tsx` | Step 15 | 穿透图层模式、导航到单元详情 |

### 需新建的文件（8 个）

| 文件路径 | 涉及步骤 | 页面说明 | 路由 |
|---------|---------|---------|------|
| `frontend/src/app/pages/Finance.tsx` | Step 2 | 财务一级页面 | `/finance` |
| `frontend/src/app/pages/ContractDetail.tsx` | Step 4 | 合同详情页 | `/contracts/:contractId` |
| `frontend/src/app/pages/Invoices.tsx` | Step 5 | 账单列表页 | `/finance/invoices` |
| `frontend/src/app/pages/WorkOrderDetail.tsx` | Step 6 | 工单详情页 | `/work-orders/:orderId` |
| `frontend/src/app/pages/UnitDetail.tsx` | Step 7 | 单元详情页 | `/assets/:buildingId/:floor/:unitId` |
| `frontend/src/app/pages/KPIDashboard.tsx` | Step 9 | KPI 考核页 | `/finance/kpi` |
| `frontend/src/app/pages/Subleases.tsx` | Step 10 | 二房东管理页 | `/subleases` |
| `frontend/src/app/pages/TenantDetail.tsx` | Step 11 | 租客画像页 | `/tenants/:tenantId` |

---

## 三、分阶段执行计划

### Phase 1 — P0 结构性修正

#### Step 1: 改造 TabBar 与路由结构

**BottomTabBar.tsx** 改动：

```diff
- { name: "首页", path: "/", icon: Home },
+ { name: "总览", path: "/", icon: Home },

- { name: "我的", path: "/profile", icon: User },
+ { name: "财务", path: "/finance", icon: Coins },
```

**routes.tsx** 改动：
- 新增 `/finance` → `Finance` 路由
- 新增 `/profile` → `Profile` 路由（非 Tab 子页面）
- 后续步骤中持续新增其他路由

**Layout.tsx** 改动：
- `HIDE_TAB_PATTERNS` 增加：`/finance/.*`、`/profile`、`/contracts/.*`、`/work-orders/.*`、`/tenants/.*`、`/subleases`

#### Step 2: 新增财务一级页面 Finance.tsx【已完成 — 角色差异化四视图】

> **实际实现升级**：Finance.tsx 已基于角色差异化需求，从原计划的单一布局升级为**四视图独立渲染**架构，详见 `FINANCE_ROLE_ADAPTIVE_DESIGN.md`。

**四视图结构**：

1. **管理层视图**（`super_admin` / `operations_manager`，深蓝 Header）
   - `NOISummaryCard` → `/dashboard/noi-detail`
   - `WALESummaryCard` → `/wale`
   - `RevenueSnapshotCard`
   - 2 大功能卡（KPI 🔴申诉提醒 / 账单 🔴逾期提醒）+ 4 二级图标入口
   - `OverdueSection` 逾期账单 Top 5

2. **财务专员视图**（`finance_staff`，深绿 Header，今日待处理 🔴7）
   - 2 任务卡（账单核销 🔴5 / 水电审核 🟡2）+ 4 二级图标入口
   - `OverdueSection` 逾期账单 Top 5

3. **租务专员视图**（`leasing_specialist`，蓝色 Header）
   - 2 功能卡（押金管理 / 营业额申报）+ 3 二级图标入口
   - `CompactCollectionWidget`（收款进度）

4. **维修技工视图**（`maintenance_staff`，深琥珀 Header，水电待录入 🟡2）
   - 1 全宽水电录入大卡 + 2 二级图标入口（工单查看 / KPI）

5. **楼管巡检员视图**（`property_inspector`，靛蓝 Header）
   - 2 快捷入口（资产查看 / 合同查看）+ 工单列表 + 水电录入/KPI 入口

6. **只读观察员视图**（`report_viewer`，深紫 Header）
   - 4 只读指标卡（NOI / WALE / 出租率 / 逾期额）+ 2 快捷入口（资产总览 / 合同列表）

#### Step 3: Profile 降级为 L2

- Home.tsx 右上角增加头像按钮 → `/profile`
- Profile.tsx 增加 `← 返回` 导航栏（ChevronLeft 模式）

---

### Phase 2 — P1 高优先级新增页面

#### Step 4: 合同详情页 ContractDetail.tsx

路由：`/contracts/:contractId`

页面结构：
- **导航栏**：← 返回 | 合同详情
- **状态徽章行**：🟢执行中 🏢写字楼 含税
- **基本信息卡片**：合同编号 / 租户 / 起止日 / 月租金 / 付款周期
- **关联单元列表**：单元编号 / 楼层 / 计费面积 / 单价
- **递增规则概览**：阶段 Timeline + 每阶段月租预测
- **押金信息**：押金总额 / 当前余额 / 状态
- **续签链**：Timeline 形式展示合同链

同时更新 Contracts.tsx 列表卡片增加 `onClick → navigate`

#### Step 5: 账单列表页 Invoices.tsx

路由：`/finance/invoices`

页面结构：
- **导航栏**：← 返回 | 账单管理
- **搜索栏**：搜索租户 / 账单号
- **状态 Tab**：全部 / 已出账 / 已核销 / 逾期 / 已作废
- **账单卡片列表**：账单号 / 租户 / 费项 / 金额 / 状态 / 到期日

#### Step 6: 工单详情页 WorkOrderDetail.tsx

路由：`/work-orders/:orderId`

页面结构：
- **导航栏**：← 返回 | 工单详情
- **状态徽章**：处理中 + 优先级标签
- **基本信息卡片**：工单编号 / 位置 / 类型 / 提报人 / 处理人
- **SLA 状态**：剩余时间倒计时
- **问题描述 + 现场照片**
- **操作 Timeline**
- **维修费用**：材料费 / 人工费 / OpEx/CapEx 标记

同时更新 WorkOrders.tsx 列表卡片增加 `onClick → navigate`

#### Step 7: 单元详情页 UnitDetail.tsx

路由：`/assets/:buildingId/:floor/:unitId`

页面结构：
- **导航栏**：← 返回 | 房源详情
- **状态徽章**：已租 / 写字楼
- **基本信息**：单元编号 / 面积（GFA/NIA）/ 朝向 / 层高 / 装修状态
- **业态扩展字段**：工位数 / 分隔间数（写字楼）| 门面宽度 / 层高（商铺）| 户型 / 梯户比（公寓）
- **当前租赁信息**：租户 / 合同编号 / 月租金 / 到期日
- **改造记录列表**：类型 / 日期 / 造价

同时更新 FloorPlan.tsx 房间点击导航到此页

#### Step 8: 优化 Home.tsx 总览页

- 增加收款率指标卡（与 NOI 并列）
- 顶部增加头像入口按钮 → `/profile`
- 预警列表增加逾期账单预警类型
- Quick Action 增加"查看账单"入口 → `/finance/invoices`

---

### Phase 3 — P2 中优先级页面

#### Step 9: KPI 考核页 KPIDashboard.tsx

路由：`/finance/kpi`

页面结构：
- **深色 Hero 卡片**：总分 87.5 + 排名 #3
- **指标明细列表**：指标名 / 实际值 / 得分 / 权重 / 加权分（可折叠）
- **排名榜卡片**：排名 / 姓名 / 总分 / 较上期变动
- **申诉入口**：快照状态 + 剩余天数 + 提交按钮

#### Step 10: 二房东管理页 Subleases.tsx

路由：`/subleases`

页面结构：
- **导航栏**：← 返回 | 二房东管理
- **统计概览卡片**：穿透率 / 填报完成率 / 待审核数
- **审核状态 Tab**：全部 / 待审核 / 已通过 / 已退回 + 搜索
- **穿透卡片列表**：单元 / 二房东 / 终端租客 / 月租金 / 入住状态 / 审核状态

#### Step 11: 租客画像页 TenantDetail.tsx

路由：`/tenants/:tenantId`

页面结构：
- **导航栏**：← 返回 | 租客详情
- **基本信息卡片**：名称 / 类型 / 证件号（脱敏）/ 联系电话（脱敏）
- **信用评级面板**：当前评级 A/B/C/D + 评级趋势线 + 逾期次数
- **租赁历史列表**：合同编号 / 单元 / 起止日期 / 状态
- **报修工单列表**：工单编号 / 描述 / 状态 / 日期

---

### Phase 4 — P3 低优先级优化

#### Step 12: 优化 Assets.tsx

- 顶部增加三业态并列对比卡片（写字楼/商铺/公寓各自的面积、房源数、空置率）

#### Step 13: 优化 WorkOrders.tsx

- 列表卡片增加 SLA 剩余时间标签
- 费用录入区增加 OpEx/CapEx 选择器
- 列表卡片增加点击导航到工单详情

#### Step 14: 优化 Contracts.tsx

- 筛选区增加楼栋选择器
- 列表卡片增加点击导航到合同详情
- 列表底部增加月租金合计汇总行

#### Step 15: FloorPlan.tsx 增加穿透图层

- layerMode 增加 `sublease` 选项（显示子租赁状态色块）
- 房间点击增加导航到 UnitDetail 页

---

## 四、验证清单

| # | 验证项 | 预期结果 |
|---|-------|---------|
| 1 | `pnpm dev` 启动 | 无编译错误 |
| 2 | 浏览器 5 个 Tab | 文案为「总览/资产/合同/工单/财务」 |
| 3 | 点击「财务」Tab | 4 指标卡 + 功能入口格 + 逾期列表正确渲染 |
| 4 | 财务 → 账单 | Invoices 页面正确展示 + Tab 隐藏 |
| 5 | 财务 → KPI | KPIDashboard 页面正确展示 + Tab 隐藏 |
| 6 | 合同列表点击卡片 | ContractDetail 页正确 + Tab 隐藏 |
| 7 | 工单列表点击卡片 | WorkOrderDetail 页正确 + Tab 隐藏 |
| 8 | 热区图点击房间 | UnitDetail 页正确展示 |
| 9 | `/subleases` | 二房东管理卡片列表正确渲染 |
| 10 | `/tenants/:id` | 租客画像正确渲染 |
| 11 | `/profile` | 有返回按钮 + Tab 隐藏 |
| 12 | `pnpm build` | 无类型错误 |

---

## 五、设计规范速查

所有新页面必须遵循以下从现有代码提取的视觉规范：

- **页面背景**：`bg-[#f5f5f7]`
- **卡片**：`bg-white rounded-[1.25rem] shadow-sm border border-gray-100 p-5`
- **主色**：`#1677ff`（按钮、激活态、重要数据）
- **状态色**：Emerald（成功/已付）→ Amber/Orange（警告/进行中）→ Red（危险/逾期）→ Violet（中性/装修中）
- **深色 Hero**：`bg-[#0f2645]` 白色文字 + 大数字
- **Tab 切换**：圆角胶囊 `px-4 py-1.5 rounded-full text-xs`，激活态 `bg-[#1677ff] text-white`
- **字号**：Hero `2.8rem` / 标题 `17px` / 正文 `13px` / 标签 `11px` / 徽章 `10px`
- **图标**：lucide-react，Tab 栏 22px，按钮 16-18px，内联 10-14px
- **按钮**：`bg-[#1677ff] text-white rounded-full` + `active:scale-95`
- **搜索框**：`bg-gray-50 border border-gray-100 rounded-xl` + 左侧 Search 图标
- **返回导航**：ChevronLeft 24px + navigate(-1)
