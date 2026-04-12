# 财务模块缺口补全执行方案

> 文档版本: v1.0  
> 创建日期: 2026-04-12  
> 基于: PRD v1.8 模块 3 对比分析结果

## 总体策略

沿用现有设计语言：深色 Hero + 白色圆角卡片 + Sheet 底部弹窗。  
Must 级缺口优先，Should 级随后，Phase 2 功能不纳入本次范围。

---

## Phase A — 账单管理增强（修改现有页面）

### A1. Invoices.tsx — 导出 Excel + 账单作废入口

**UX**：
- NavBar 右侧增加 `Download` icon 導出按钮，点击弹出 Sheet 让用户选时间范围和维度
- 账单作废在 InvoiceDetail 增加入口，AlertDialog 二次确认 + 必填"作废原因"，红色危险风格

**视觉**：
- 导出 Sheet 内日期范围 + 维度 Checkbox（楼栋/业态/租客），蓝色"导出"确认按钮
- 作废 Dialog：红色边框警告框，表单验证通过才能点击确认

### A2. InvoiceDetail.tsx — 税务发票 section

**UX**：
- 紧贴"收款核销"section 下方，新增"税务发票"section
- Toggle 切换"未开票 → 已开票"，切换后动画展出发票号 + 开票日期输入框

**视觉**：
- 待开票：`text-[#1677ff] bg-[#1677ff]/[0.08]` badge
- 已开票：`text-emerald-600 bg-emerald-50` badge

### A3. PaymentForm.tsx — 跨账单核销分配

**UX**：
- 顶部：总收款金额 + 日期 + 方式（原有字段）
- 中部：该租户所有待付账单列表，Checkbox 勾选参与分配，系统按先到期先核销自动分配
- 底部固定栏：`已分配 X / 共 Y` 进度条 + 提交按钮（分配不等于总额时禁用）

**视觉**：
- 进度条：= 总额绿色，< 总额橙色，> 总额红色
- 账单行：逾期用红色金额，正常用灰色

---

## Phase B — KPI 系统补全

### B1. 新增 KPISchemes.tsx（/finance/kpi/schemes）

**UX**：
- 从 KPIDashboard NavBar 右上角 `Settings` icon 进入
- 方案列表，每张卡片显示：方案名、适用对象 chip、评估周期 pill、指标数、权重校验badge、启用Switch
- FAB 右下角 `+` 创建新方案

**视觉**：
- Hero: `from-violet-800 to-violet-600` 紫色渐变（与蓝/墨区分）
- 权重校验：✓ emerald = 权重合计100%，⚠ amber = 未达，✗ red = 超出

### B2. 新增 KPISchemeForm.tsx（新建/编辑）

**UX**：
- 4步向导：基本信息 → 指标权重 → 阈值调整 → 生效时间
- Step 2（核心）：左侧 Checkbox 选指标，右侧权重 Slider，底部权重合计环形进度条
- 实时校验：权重合计 < 100% 时"下一步"禁用

**视觉**：
- 步骤指示：已完成=蓝实心，当前=蓝描边脉冲动画，待完成=灰
- 环形进度条：外圈渐变弧线 SVG，中心显示 `87/100%`，< 100 amber，= 100 emerald，> 100 red

### B3. KPIDashboard.tsx 扩展

| 位置 | 改动 |
|------|------|
| NavBar | 右侧加 `Settings`（方案配置）+ `Download`（导出）icon 按钮，管理员可见 |
| Hero 下方 | 视角切换 Segmented："我的 KPI / 团队 KPI"（管理员可见团队Tab） |
| 指标展开 | 增加"查看原始数据 →"跳转链接 |
| 新增 section | HistoryTrendSection：6个月折线 + 去年同期虚线，同比/环比chip |
| 团队视角 | 全员得分列表（本期/前期/趋势） + 申诉审核区（管理员可审核） |

---

## Phase C — NOI L3 下钻（NOIDashboard.tsx）

### C1. 楼栋卡 → Sheet底部弹窗（三 Tab）

- Tab 1「逐笔明细」: 该楼栋本月账单列表（状态色点标记）
- Tab 2「支出明细」: OpEx 各类目明细
- Tab 3「空置单元」: 空置单元列表（单元号/面积/空置天数/估算月损失）

### C2. 收款率 → "未缴款租户"展开区

- 收款率进度条下方增加折叠展开区
- 默认收起，"展开 N 笔未缴款 ↓" 按钮
- 展开列表按逾期天数色阶标注，点击行跳转账单详情

---

## Phase D — 水电抄表优化

### D1. MeterReadingForm.tsx — 阶梯价 + 业态开关

- Switch 切换"固定单价 / 阶梯价"，展开最多3段（动画展开）
- 选择公寓业态后出现"含于租金（不生成独立账单）"选项

### D2. MeterReadingList.tsx — 生成账单按钮

- `pending` 状态卡片右下角增加 amber 色"生成账单"按钮
- 点击后 Confirm toast + 3秒撤销倒计时
- 成功后卡片变为 `billed` 状态（emerald 只读标签）

---

## 文件清单

| 文件 | 类型 | 对应任务 |
|------|------|---------|
| `frontend/src/app/data/mockFinanceData.ts` | 扩充 | KPI schemes mock + NOI L3 mock |
| `frontend/src/app/pages/Invoices.tsx` | 修改 | A1 |
| `frontend/src/app/pages/InvoiceDetail.tsx` | 修改 | A2 |
| `frontend/src/app/pages/PaymentForm.tsx` | 修改 | A3 |
| `frontend/src/app/pages/KPISchemes.tsx` | 新增 | B1 |
| `frontend/src/app/pages/KPISchemeForm.tsx` | 新增 | B2 |
| `frontend/src/app/pages/KPIDashboard.tsx` | 修改 | B3 |
| `frontend/src/app/pages/NOIDashboard.tsx` | 修改 | C1+C2 |
| `frontend/src/app/pages/MeterReadingForm.tsx` | 修改 | D1 |
| `frontend/src/app/pages/MeterReadingList.tsx` | 修改 | D2 |
| `frontend/src/app/routes.tsx` | 修改 | 新增 KPISchemes/KPISchemeForm 路由 |

## 决策说明（按建议执行）

1. KPIDashboard 视角：同一页面 Tab 切换（管理员才见"团队"Tab）
2. 账单导出：`toast.success("导出成功，文件下载中")` 模拟，不接真实接口
3. Finance.tsx "KPI考核" 入口：保持跳到 KPIDashboard，Dashboard NavBar 右上角有"方案配置"跳 Schemes

## 排除范围（Phase 2）

- 催收模板配置
- 抄表周期配置
- NOI 穿透视角（二房东穿透）
- KPI 与薪酬系统对接
