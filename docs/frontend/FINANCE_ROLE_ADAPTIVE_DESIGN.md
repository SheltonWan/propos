# 财务页角色差异化体验方案

**文档编号**：FE-DESIGN-003  
**日期**：2026-04-12  
**作者**：PropOS Copilot  
**适用范围**：`frontend/src/app/pages/Finance.tsx`

---

## 1. 设计背景与目标

PropOS 系统现有 5 个角色，其核心诉求完全正交：

| 角色 | 核心诉求 | 原页面痛点 |
|------|----------|-----------|
| 超级管理员 / 运营经理 | 决策支撑：看 NOI 趋势、KPI 排名、预算达成 | 功能入口与数据看板割裂，需多次点击才能看到关键数字 |
| 财务专员 | 操作驱动：今天有几笔逾期要处理，有几笔水电账单待核 | 原入口静态无数据，必须进入二级页才能看到待办数量 |
| 租务专员 | 职责收敛：只关注押金台账和营业额核对 | 看到 NOI、预算等无权操作的内容，产生信息噪音 |
| 前线员工 | 单任务：录入水电读数 | 看到所有财务功能入口，权限不匹配且界面复杂 |

**设计目标**：每个角色打开财务页，所见所得与其职责 100% 匹配，零信息噪音，关键待办数量前置可见。

---

## 2. 选型决策

**方案对比**：

| 方案 | 实现方式 | 优点 | 缺点 |
|------|---------|------|------|
| A：单布局局部 `if` | 同一 JSX 树，分支条件显隐 | 代码量少 | 4 套角色逻辑交织，维护时易误改 |
| **B：整页四视图**（选定） | 4 条 `if/return` 分支，各返回专属 JSX | 每个角色布局独立可维护，视角设计无妥协 | 代码行数多 |
| C：配置驱动渲染 | ROLE_CONFIG 对象 + 单一渲染引擎 | 扩展性强 | 过度设计，4 个角色用 config 对象 ROI 低 |

**选定方案 B**：整页四视图独立渲染。理由：4 个角色的页面结构差异已大到 header 颜色、组件类型、数据源完全不同，强行共用模板会使每个角色的体验都不精准。

---

## 3. 四视图规格

### 3.1 管理层视图（super_admin / operations_manager）

**设计理念**：数据密度最高，以宏观指标为主体，功能入口辅助

```
Header: 深海蓝渐变 #0f2645→#1a3a5c
页眉:   财务概览 / 2026年4月 · 经营看板
```

**页面结构**（从上到下）：

1. **NOI 汇总卡** — 深蓝暗色大卡，NOI 205万 + MoM + Margin + 收款率 + 预算达成 + NOI/OpEx 进度条，点击跳转完整看板
2. **WALE 汇总卡** — 蓝色渐变大卡，3.2年 + 到期90天/30天预警，点击跳转 WALE 看板
3. **收入快报卡** — 白色大卡，本月应收 + 收款进度条 + 收入构成比
4. **功能入口区**：
   - 2列大卡：KPI考核🔴（申诉数）+ 账单管理🔴（逾期数），携带实时摘要数据
   - 小图标行：NOI预算 / 押金管理 / 费用支出 / 营业额申报
5. **逾期账单 Top5** — 监控性质，供巡检用

### 3.2 财务专员视图（finance_staff）

**设计理念**：任务优先，待办数前置，操作路径最短

```
Header: 深forest绿渐变 #064e3b→#065f46
页眉:   今日待处理 + 右上角红色圆形任务总数角标
```

**页面结构**：

1. **待办任务区**：
   - 2列大卡：账单管理🔴（逾期N笔 + 金额）+ 水电抄表🟡（待生成N笔 + 上次录入日期）
   - CTA 分别为"去处理"/"立即处理"，点击直达操作页
   - 小图标行：费用支出 / 营业额审批 / 押金管理 / KPI考核
2. **逾期账单 Top5** — 与管理层相同，此处为操作清单用途

**关键差异**：无 NOI、无 WALE，减少决策数据减少干扰，专注操作

### 3.3 租务专员视图（leasing_specialist）

**设计理念**：职责收敛，只展示本岗位相关财务职能

```
Header: 蓝色渐变 #1a3a5c→#2a5298
页眉:   租务财务 / 押金 · 营业额 · 收款查看
```

**页面结构**：

1. **我的任务区**：
   - 2列大卡：押金管理（在管143份 + 本季到期5笔）+ 营业额申报（本月待核4份 + 截止日）
   - 小图标行：水电抄表 / 账单查看🔴 / KPI考核（只读）
2. **紧凑收款进度条** — 轻量版，显示本月收款率，供参考

**关键差异**：无 NOI/WALE/逾期处理权，收款数据只读不运营

### 3.4 前线员工视图（frontline_staff）

**设计理念**：极简单任务，无噪音

```
Header: 深琥珀渐变 #78350f→#92400e
页眉:   水电录入 + 右上角🟡圆形待录数角标
```

**页面结构**：

1. **全宽水电抄表卡** — 单任务卡，显示待生成账单数 + 上次录入
2. **小图标行**：账单查看（只读） / KPI考核（只读）

**关键差异**：无任何财务数字，无操作型功能入口，界面极简

---

## 4. 组件架构

```
Finance.tsx
├── 共享组件（4个）
│   ├── SectionLabel({ color, title })
│   ├── FeaturedCard({ entry: FeaturedEntry })
│   ├── SecondaryIconRow({ entries: SecondaryEntry[] })
│   └── CompactCollectionWidget()
├── 管理层专用组件（保留原有）
│   ├── NOISummaryCard()
│   ├── WALESummaryCard()
│   └── RevenueSnapshotCard()
├── 通用组件（保留原有）
│   └── OverdueSection()
└── Finance() 主出口
    ├── if super_admin || operations_manager → 管理层视图
    ├── if finance_staff → 财务专员视图
    ├── if leasing_specialist → 租务专员视图
    └── default (frontline_staff) → 前线视图
```

**FeaturedEntry 接口**：

```typescript
interface FeaturedEntry {
  Icon: React.ElementType;
  iconBg: string;
  label: string;
  badge?: { count: number; type: "danger" | "warning" };
  line1: string;
  line2?: string;
  cta: string;
  ctaColor: string;
  path: string;
}
```

---

## 5. 数据源映射

| 徽标数据 | 来源常量 | 当前值 |
|---------|---------|-------|
| 逾期账单数 | `OVERDUE_LIST.length` | 5 |
| 逾期总金额 | `OVERDUE_LIST.reduce(sum)` | ¥106,100 |
| 待生成账单数 | `METER_READINGS_MOCK.filter(pending).length` | 2 |
| 待审申诉数 | `KPI_APPEAL_PENDING_MOCK.length` | 2 |
| 今日总任务（财务专员） | `OVERDUE_COUNT + PENDING_METER` | 7 |

---

## 6. 视觉设计规范

| 视图 | Header 渐变 | 主题色 |
|------|------------|-------|
| 管理层 | `#0f2645 → #1a3a5c` | 深蓝（决策） |
| 财务专员 | `#064e3b → #065f46` | 深绿（操作） |
| 租务专员 | `#1a3a5c → #2a5298` | 蓝（协作） |
| 前线员工 | `#78350f → #92400e` | 深琥珀（工具） |

徽标色语义（沿用全局规范）：
- 🔴 `bg-red-500` / `border-red-200`：逾期/申诉（需立即处理）
- 🟡 `bg-amber-500` / `border-amber-200`：待处理（非紧急）

---

## 7. 验证清单

| 测试用例 | 切换用户 | 预期结果 |
|---------|---------|---------|
| 管理层视图 | u1 张总（super_admin） | 深蓝 Header + NOI/WALE/收入快报 + 2大卡功能入口 |
| 财务专员视图 | u4 赵会计（finance_staff） | 深绿 Header + 右上角红色"7"圆钮 + 2大待办卡 |
| 租务专员视图 | u3 王专员（leasing_specialist） | 蓝色 Header + 押金+营业额大卡 + 紧凑收款条 |
| 前线员工视图 | u5 陈师傅（frontline_staff） | 琥珀 Header + 右上角🟡"2"圆钮 + 极简单卡布局 |
| TS 编译 | — | `pnpm run build` 0 错误 |

---

## 8. 变更文件清单

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `frontend/src/app/pages/Finance.tsx` | 重构 | 删除 FunctionGrid，新增 4 共享组件，重写 Finance() 为四视图 |
| `frontend/src/app/data/mockFinanceData.ts` | 只读引用 | 新增使用 METER_READINGS_MOCK / KPI_APPEAL_PENDING_MOCK |
