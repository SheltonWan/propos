# 前端原型点击交互修复任务规划

## 问题概述

前端原型项目 (`frontend/`) 中约 25+ 处二级、三级点击交互无响应。表现为：
- 卡片/按钮渲染了 `cursor-pointer` 样式，但缺少 `onClick` handler
- 按钮仅做 stub 实现（动画 / toast，无实际状态变更或导航）
- 缺少详情路由与对应页面

## 修复任务列表

### Phase A — 新页面 + 路由

| # | 文件 | 操作 | 说明 |
|---|------|------|------|
| A1 | `pages/SubleasDetail.tsx` | 新建 | 二房东详情页（含审核通过/驳回功能，依据 PRD 5.4） |
| A2 | `routes.tsx` | 修改 | 注册 `subleases/:sublandlordId` → `SubleasDetail` |

### Phase B — 列表页 onClick 修复

| # | 文件 | 修复点 | 动作 |
|---|------|--------|------|
| B1 | `Subleases.tsx` | 卡片 div 无 onClick | `navigate(/subleases/${item.id})` |
| B2 | `Home.tsx` — TaskItem | 待办卡片无 onClick prop | 添加 onClick prop，按 type 导航到对应详情页 |
| B3 | `Home.tsx` — PropertyTypePanelRow | 三业态行全部导航到 `/assets` | 改为 `navigate(/assets?type=${typeKey})` |
| B4 | `Finance.tsx` — OverdueSection | "查看全部" 无 onClick | `navigate("/finance/invoices")` |
| B5 | `Assets.tsx` — 类型对比卡片 | 3 张业态卡无 onClick | 点击自动切换 Tab 到对应业态 |
| B6 | `Assets.tsx` — 回滚按钮 | 无确认对话框 | 添加 `confirm()` + `toast.success` |

### Phase C — 详情页 / 抽屉按钮修复

| # | 文件 | 修复点 | 动作 |
|---|------|--------|------|
| C1 | `FloorPlan.tsx` — RoomDrawer | "查看合同" 无 onClick | `onNavigate(/contracts/${contractId})` |
| C2 | `FloorPlan.tsx` — RoomDrawer | "联系租户" 无 onClick | `toast("已复制联系方式…")` |
| C3 | `FloorPlan.tsx` — RoomDrawer | "发布招租" 无 onClick | `onNavigate("/contracts")` |
| C4 | `FloorPlan.tsx` — RoomDrawer | "查看记录" 无 onClick | `onNavigate(/assets/${buildingId})` |
| C5 | `WorkOrders.tsx` — 列表 | "立即派单" 无 onClick | `toast.success + stopPropagation` |
| C6 | `WorkOrders.tsx` — 列表 | "确认完成"(to-verify) 无 onClick | `toast.success + stopPropagation` |
| C7 | `WorkOrders.tsx` — 列表 | "已验收" 无 onClick | 无需动作，已为视觉指示 |
| C8 | `WorkOrderDetail.tsx` | "提交验房报告" 无 onClick | `toast.success + navigate(-1)` |
| C9 | `KPIDashboard.tsx` — AppealCard | "提交申诉" 无 onClick | `toast.success("申诉已提交")` |

### Phase D — 导航优化

| # | 文件 | 修复点 | 动作 |
|---|------|--------|------|
| D1 | `Contracts.tsx` | "模板库" 按钮 | 改为 `navigate("/contracts/escalation-templates")` |

## 涉及文件汇总（共 10 文件）

| 文件 | 操作类型 |
|------|----------|
| `pages/SubleasDetail.tsx` | **新建** |
| `routes.tsx` | 修改 |
| `pages/Subleases.tsx` | 修改 |
| `pages/Home.tsx` | 修改 |
| `pages/Finance.tsx` | 修改 |
| `pages/Assets.tsx` | 修改 |
| `pages/FloorPlan.tsx` | 修改 |
| `pages/WorkOrders.tsx` | 修改 |
| `pages/WorkOrderDetail.tsx` | 修改 |
| `pages/KPIDashboard.tsx` | 修改 |
| `pages/Contracts.tsx` | 修改 |

## 验收标准

- 所有 `cursor-pointer` 元素均有对应 onClick handler
- 点击后产生可见反馈（页面导航 / toast / 状态变更）
- 无 console 报错
- 路由回退（← 按钮）均正常工作
