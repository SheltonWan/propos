# PropOS Frontend 原型设计评审报告

| 元信息 | 值 |
|--------|------|
| 版本 | v1.8 |
| 评审日期 | 2026-04-12 |
| 评审对象 | `frontend/`（React 交互原型） |
| 对照基准 | PRD v1.8 · PAGE_SPEC v1.8 · PAGE_WIREFRAMES v1.8 · ARCH v1.4 |
| 评审人 | GitHub Copilot |

---

## 一、项目性质定位

`frontend/` 是一个 **React 交互原型**（`package.json` name: `@figma/my-make-file`），使用 React 18 + React Router 7 + shadcn/ui + Tailwind v4 构建，定位为前期 UI 验证原型与设计参照物，**并非生产交付物**。

最终交付目标为：
- `flutter_app/`（Flutter + Dart + flutter_bloc + Material 3）— 移动端
- `admin/`（Vue 3 + Element Plus）— PC Admin 端

---

## 二、技术栈差异（架构层面）

| 维度 | PAGE_SPEC v1.8 规格 | frontend/ 原型实际 | 影响等级 |
|------|---------------------|-------------------|---------|
| 移动端框架 | Flutter (Dart) | React 18 | 参照可用，移植需重写 |
| 状态管理 | flutter_bloc / Cubit | React Context | 参照可用，移植需重写 |
| UI 组件库 | Material 3 / Element Plus | shadcn/ui + Radix UI | 组件无法复用 |
| 设计语言 | Material 3 ThemeData + CSS 变量 | Tailwind 硬编码类 | 移植时需逐一映射 |
| Admin PC 端 | Vue 3 + Element Plus（44 视图）| **完全缺失** | 🔴 严重缺口 |
| 状态色 | `--color-success/warning/danger` | `text-emerald-600` 等 | 移植时替换 |
| API 层 | api → store → page 单向数据流 | 全量静态 mock 数据 | 🔴 移植时全量替换 |

---

## 三、页面覆盖度（移动端 / 原型端）

### 3.1 已覆盖页面（18 个）

| 模块 | 规格页面 | 原型文件 | 质量评估 |
|------|---------|---------|---------|
| Dashboard | 总览首页 | `Home.tsx` | 指标卡 + 业态横滑卡 + 预警雷达 + 快捷入口 — **完整** |
| 资产 M1 | 资产总览 | `Assets.tsx` | 楼栋列表 + 业态分类 + 搜索 — **完整** |
| 资产 M1 | 楼层列表 | `BuildingFloors.tsx` | mini 缩略图 + 出租率条 — **完整** |
| 资产 M1 | 楼层热区图 | `FloorPlan.tsx` | SVG 覆盖层 + 4 种图层模式（状态/二房东/NOI/到期）— **超出规格，亮点** |
| 资产 M1 | 房源详情 | `UnitDetail.tsx` | 覆盖 |
| 合同 M2 | 合同列表 | `Contracts.tsx` | 12 个模板 + 多房间录入 + 递增规则配置 — **超出规格** |
| 合同 M2 | 合同详情 | `ContractDetail.tsx` | 覆盖 |
| 财务 M3 | 财务总览 | `Finance.tsx` | **角色差异化四视图**：管理层（深蓝）/ 财务专员（深绿）/ 租务专员（蓝）/ 前线员工（琥珀），各视图独立 Header、数据卡与操作入口 — **完整** |
| 财务 M3 | 账单管理 | `Invoices.tsx` | 覆盖 |
| 财务 M3 | KPI 考核 | `KPIDashboard.tsx` | 指标明细 + 排名 + 申诉期 — **完整** |
| 财务 M3 | NOI 看板 | `NOIDashboard.tsx` | 业态分拆 + 楼栋分析 + OpEx 明细 — **高质量** |
| 财务 M3 | WALE 看板 | `WALEDashboard.tsx` | 健康仪表盘 + 趋势图 + 到期瀑布 + 风险合同 — **高质量** |
| 工单 M4 | 工单列表 + 新建 | `WorkOrders.tsx` | 三类工单（报修/投诉/退租验房）+ SLA — **完整** |
| 工单 M4 | 工单详情 | `WorkOrderDetail.tsx` | 覆盖 |
| 二房东 M5 | 二房东管理 | `Subleases.tsx` | 穿透率 + 审核状态分 Tab — **完整** |
| 个人 | 租客详情 | `TenantDetail.tsx` | 覆盖 |
| 个人 | 个人信息 / 角色切换 | `Profile.tsx` | 5 种角色切换器，演示价值高 |
| 全景 | 展示模式 | `Showcase.tsx` | 5 屏并排全景模式 — **设计亮点** |

### 3.2 规格要求但原型缺失

| 缺失端/页面 | 所属 | 规格依据 | 严重度 |
|------------|------|---------|--------|
| **整个 Admin PC 端**（44 视图） | admin/ | PAGE_WIREFRAMES §1.1 | 🔴 严重 |
| 登录页 | 两端 | PAGE_WIREFRAMES §2.1/2.2 | 🔴 原型默认跳过鉴权 |
| 修改密码弹窗 | Admin | PAGE_WIREFRAMES §2.3 | 🟡 |
| 二房东详情 | 移动端 | PAGE_SPEC §九 | 🟡 |
| 外部填报 Web 门户（3 页） | 独立 Web | PAGE_SPEC §九 | 🟡 M5 二房东自报未演示 |
| 费用支出 | 移动端 | Finance.tsx（租务专员 / 管理层视图） | ✅ 已通过角色差异化重构解决，各角色视图按需展示对应功能入口 |
| 水电抄表 | 移动端 | Finance.tsx（前线员工 / 财务专员视图） | ✅ 已通过角色差异化重构解决，前线员工视图以大卡片前置水电录入 |
| 营业额申报 | 移动端 | Finance.tsx（租务专员视图） | ✅ 已通过角色差异化重构解决，租务专员视图二级入口直达 |
| 资产批量导入 | Admin | PAGE_SPEC §五 | 🟡 |
| 系统设置各子模块 | Admin | PAGE_SPEC §十 | 🟡 |
| 合同终止 / 续约表单 | Admin | PAGE_SPEC §六 | 🟡 |

---

## 四、业务逻辑问题清单（可在原型内修复）

### R3 — PDF 附件删除无确认弹窗【已修复】

**位置**: `frontend/src/app/pages/Contracts.tsx` — `PdfUploader` 组件

**描述**: 「合同附件」区域中，用户点击文件旁的 `Trash2` 图标后，文件立即被删除，无任何确认步骤。合同附件为高价值文件，误删时没有撤销机会。

**修复方案**: 引入 `confirmingDeleteId` 状态，点击删除按钮时先切换为行内确认 UI，用户需二次点击「确认删除」才真正执行删除。

**优先级**: 🟡 安全规范 — 操作不可逆需确认

---

### R4 — Finance 功能入口空路径静默失效【已修复 — 方案升级】

**位置**: `frontend/src/app/pages/Finance.tsx`

**原描述**: 「功能入口」`FunctionGrid` 组件中「费用支出」「水电抄表」「营业额申报」三个入口的 `path` 字段为 `null`，点击无响应。

**实际修复方案（已升级）**: 彻底删除 `FunctionGrid` 和 `FUNCTION_ENTRIES` 静态配置，重构为**角色差异化四视图独立渲染**。每个角色视图按职责精准展示功能入口且全部接通真实路由，不再存在空路径入口问题，同时消除了单一布局下的信息噪音。

**优先级**: ✅ 已完全解决（方案优于原 Toast 提示修复）

---

### R5 — WALE 看板无 Finance 页直达入口【已修复】

**位置**: `frontend/src/app/pages/Finance.tsx`

**描述**: `WALEDashboard`（`/wale`）之前在 Finance 页无任何入口，用户无法自主发现。

**实际修复方案**: 管理层视图（`super_admin` / `operations_manager`）中，Finance 页顶部依次展示 `NOISummaryCard`（→ `/dashboard/noi-detail`）、`WALESummaryCard`（→ `/wale`）、`RevenueSnapshotCard`，三张深色卡片连续排布，WALE 看板可达性问题完全解决。其他角色视图因职责不包含 WALE 指标，不展示此卡片。

**优先级**: ✅ 已完全解决

---

## 五、架构层面待处理项（需在 app/ + admin/ 实现阶段解决）

| 编号 | 问题 | 当前状态 | 处理阶段 |
|------|------|---------|---------|
| A1 | 全量静态 mock 数据，无 API 接口调用层 | frontend/ 原型设计 | app/ / admin/ 实现时全量替换 |
| A2 | 状态色硬编码 Tailwind 类，未走语义色体系 | frontend/ 原型设计 | 移植到 Flutter Material 3 / Element Plus 时逐一映射 |
| A3 | FloorPlan.tsx SVG 坐标静态硬编码 | 原型内建 mock | M1 交付时对接 `GET /api/floors/:id` + SVG_HOTZONE_SPEC |
| A4 | Admin PC 端（44 视图）完全缺失 | 未开工 | admin/ 建设中补齐 |
| A5 | 登录页缺失，原型默认跳过鉴权 | 原型设计范围 | app/ 已有登录页，admin/ 需补充 |
| A6 | 外部二房东填报 Web 门户（3 页）缺失 | 未开工 | M5 建设阶段实现 |

---

## 六、实施计划与完成状态

| 序号 | 问题 | 文件 | 优先级 | 状态 |
|------|------|------|--------|------|
| 1 | R3：PDF 删除确认 | `Contracts.tsx` | P1 | ✅ 已修复 |
| 2 | R4：空路径入口问题 | `Finance.tsx`（角色差异化四视图重构） | P1 | ✅ 已修复（方案升级为四视图，彻底消除空路径） |
| 3 | R5：WALE 看板导航入口 | `Finance.tsx`（管理层视图 `WALESummaryCard`） | P1 | ✅ 已修复 |
| 4 | A1-A6：架构层问题 | app/ + admin/ | P2 | ⏳ 待 app/admin 建设阶段处理 |

---

## 七、亮点功能（建议保留设计语言迁移至 app/）

1. **FloorPlan 4 层模式**：状态 / 二房东穿透 / NOI 热力 / 到期预警四层切换，交互设计超出线框图描述，建议直接作为 `app/` 楼层热区图的 UI 蓝图
2. **合同模板选择器**：12 个业态模板 × 租金递增类型配置，字段结构与 `rent_escalation_engine` 6 种递增类型对齐，移植时作为创建表单的 UI 参照
3. **Showcase 全景模式**：5 屏并排，适合演示汇报场景，建议保留为独立演示构建目标
4. **RBAC 角色切换器**：`Profile.tsx` 5 种角色实时切换 + 权限差异可视化，`permissions.ts` 矩阵与 `RBAC_MATRIX.md` 一致
