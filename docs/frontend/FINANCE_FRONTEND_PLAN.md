# 财务模块前端补缺实施计划

**日期**: 2026-04-12  
**范围**: `frontend/src/app/` — React 移动端原型  
**规格参考**: `PAGE_SPEC_v1.8.md §7.*` + `PAGE_WIREFRAMES_v1.8.md §6.*` + `PRD.md §3.*`

---

## 一、Gap 分析汇总

### 1.1 缺失页面（9 个）

| # | 路由 | 组件文件 | 规格节 |
|---|------|---------|--------|
| 1 | `/finance/invoices/:invoiceId` | `InvoiceDetail.tsx` | §7.3 含催收记录 |
| 2 | `/finance/invoices/:invoiceId/pay` | `PaymentForm.tsx` | §7.4 核销分配 |
| 3 | `/finance/meter-readings` | `MeterReadingList.tsx` | §7.9 / §6.10 |
| 4 | `/finance/meter-readings/new` | `MeterReadingForm.tsx` | §7.5 双模式 |
| 5 | `/finance/expenses` | `ExpenseList.tsx` | §7.7 / §6.8 |
| 6 | `/finance/expenses/new` | `ExpenseForm.tsx` | §7.8 / §6.9 |
| 7 | `/finance/turnover-reports` | `TurnoverReports.tsx` | §7.6 列表+详情 |
| 8 | `/finance/deposits` | `DepositLedger.tsx` | §7.10 押金流水 |
| 9 | `/finance/noi-budget` | `NoiBudget.tsx` | §7.11 年度预算 |

### 1.2 存量文件 Bug（5 处）

| 文件 | 问题 | 修复 |
|------|------|------|
| `routes.tsx` | 路由 `noi` → 规范为 `dashboard/noi-detail` | 路径对齐 |
| `routes.tsx` | 缺少 9 条新路由 | 注册全部 |
| `Layout.tsx` | HIDE_TAB_PATTERNS: `/^\/noi/` 需改 `/^\/dashboard/` | 正则更新 |
| `Finance.tsx` | `NOISummaryCard` navigate 到 `/noi` | ✅ 已修复：改 `/dashboard/noi-detail` |
| `Finance.tsx` | `FUNCTION_ENTRIES` 中费用/抄表/营业额 path 为 null | ✅ 已修复（方案升级）：删除 `FUNCTION_ENTRIES` 静态配置，重构为角色差异化四视图，各视图功能入口均已接通真实路由 |
| `Invoices.tsx` | 账单卡片 onClick 未实现（无跳转） | 跳转 `/finance/invoices/:id` |

---

## 二、实施方案

### Phase 1 — 基础路由与导航修复

**受影响文件**: `routes.tsx`、`Layout.tsx`、`Finance.tsx`、`Invoices.tsx`

```
routes.tsx:
  - path "noi" → "dashboard/noi-detail"
  - 注册 10 条新路由（含 :invoiceId/pay 和 turnover-reports/:reportId）

Layout.tsx:
  - HIDE_TAB_PATTERNS: /^\/noi/ → /^\/dashboard/

Finance.tsx:
  - NOISummaryCard: navigate('/noi') → navigate('/dashboard/noi-detail') ✅
  - FUNCTION_ENTRIES 整体方案升级：删除静态功能网格，重构为角色差异化四视图独立渲染 ✅
    详见 `docs/frontend/FINANCE_ROLE_ADAPTIVE_DESIGN.md`

Invoices.tsx:
  - 每张账单卡片 onClick → navigate('/finance/invoices/' + inv.id)
```

### Phase 2 — Mock 数据扩充

**文件**: `data/mockFinanceData.ts`

新增 8 个导出：
- `INVOICE_DETAIL_MOCK` — 账单详情 + 费项明细
- `DUNNING_LOGS_MOCK` — 催收日志
- `PAYMENT_HISTORY_MOCK` — 收款核销记录
- `METER_READINGS_MOCK` — 抄表记录列表
- `EXPENSES_MOCK` — 费用列表
- `TURNOVER_REPORTS_MOCK` — 营业额申报列表
- `DEPOSITS_MOCK` — 押金台账
- `NOI_BUDGET_MOCK` — NOI 年度预算网格 + 历年对比

### Phase 3 — 账单流程页面

- **`InvoiceDetail.tsx`**: 账单信息 + 费项明细 + 收款核销记录 + 催收记录 + 操作按钮
- **`PaymentForm.tsx`**: 金额/方式/流水号/备注 + 核销分配列表

### Phase 4 — 水电抄表 & 费用管理

- **`MeterReadingList.tsx`**: 筛选 + 抄表记录列表（日期/单元/表型/读数/用量/费用/状态）
- **`MeterReadingForm.tsx`**: 双模式切换（租户独立表 / 公区总表分摊）
- **`ExpenseList.tsx`**: 三汇总卡 + 筛选 + 费用列表
- **`ExpenseForm.tsx`**: 费用类型/金额/日期/楼栋/供应商/摘要/附件

### Phase 5 — 营业额申报

- **`TurnoverReports.tsx`**: 列表视图（状态筛选 + 申报行）+ 详情视图（申报信息 + 审核操作）

### Phase 6 — 押金台账 & NOI 预算

- **`DepositLedger.tsx`**: 汇总卡 + 押金列表 + 底部 Sheet 流水明细
- **`NoiBudget.tsx`**: 年份选择 + 月度预算可编辑网格（含全年合计自动求和）+ 历年 BarChart

---

## 三、样式约定

所有新页面严格遵循现有视觉语言：

| 元素 | Class |
|------|-------|
| 页面背景 | `min-h-full bg-[#f5f5f7] pb-8` |
| 顶部 NavBar | `bg-white px-4 pt-12 pb-3 flex items-center gap-3 border-b border-gray-100 sticky top-0 z-30` |
| 内容卡片 | `mx-5 mb-4 bg-white rounded-[1.25rem] shadow-sm border border-gray-100 overflow-hidden` |
| 区块标题 | `w-1 h-4 bg-[color] rounded-full` + `text-[14px] font-bold text-gray-800` |
| 信息行 | `flex justify-between py-2.5 divide-y divide-gray-50` |
| 状态色 | 已核销=`emerald-600`，逾期=`red-600`，已出账=`[#1677ff]`，作废=`gray-400`，预警=`amber-600` |
| 主操作按钮 | `py-3 bg-[#1677ff] text-white text-[14px] font-bold rounded-[1rem]` |

---

## 四、验证清单

- [ ] `npm run build` 无 TypeScript 错误
- [ ] `/noi` 路由404（已迁移到 `/dashboard/noi-detail`）
- [ ] Finance 页 NOI 卡片点击 → NOI 看板
- [x] Finance 页角色差异化视图：各角色视图功能入口均已接通真实路由，无空路径（已通过四视图重构彻底解决）
- [ ] Invoices 页账单卡片点击 → InvoiceDetail
- [ ] InvoiceDetail 催收记录区块（假数据）可见
- [ ] MeterReadingForm 双模式切换显示对应表单
- [ ] DepositLedger "查看流水"触发底部 Sheet
- [ ] NoiBudget 月份格可编辑，全年合计自动求和

---

## 五、文件变动清单（共 14 项）

### 修改（5 项）
1. `src/app/routes.tsx`
2. `src/app/Layout.tsx`
3. `src/app/pages/Finance.tsx`
4. `src/app/pages/Invoices.tsx`
5. `src/app/data/mockFinanceData.ts`

### 新建（9 项）
6. `src/app/pages/InvoiceDetail.tsx`
7. `src/app/pages/PaymentForm.tsx`
8. `src/app/pages/MeterReadingList.tsx`
9. `src/app/pages/MeterReadingForm.tsx`
10. `src/app/pages/ExpenseList.tsx`
11. `src/app/pages/ExpenseForm.tsx`
12. `src/app/pages/TurnoverReports.tsx`
13. `src/app/pages/DepositLedger.tsx`
14. `src/app/pages/NoiBudget.tsx`
