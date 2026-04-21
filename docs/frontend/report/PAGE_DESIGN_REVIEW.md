# 前端页面设计与 PRD 需求匹配度分析报告

> **分析对象**: PAGE_SPEC_v1.8.md + PAGE_WIREFRAMES_v1.8.md vs PRD.md v1.8
> **分析日期**: 2026-04-10
> **结论**: 一级页面架构设计合理可行，覆盖了 PRD 约 **85%** 的 Must 级需求。以下列出缺口与补充建议。

---

## 一、一级页面架构可行性评估

### 1.1 Admin PC 端（7 个侧边栏分组）

| 分组 | 一级页面 | 与 PRD 模块对应 | 评估结论 |
|------|---------|----------------|---------|
| Dashboard | DashboardView | 跨模块 L1 概览 | ✅ **优秀** — 4 张核心指标卡片（出租率/NOI/WALE/收款率）+ 三业态分拆 + 趋势图 + 预警汇总，信息密度恰当 |
| 资产 | AssetsView | M1 资产与空间 | ✅ **良好** — 三业态汇总卡片 + 楼栋列表 + 导入/导出入口，作为资产管理入口合理 |
| 合同 | ContractsView | M2 租务与合同 | ✅ **良好** — 多维筛选 + 状态分布 + 核心操作入口（续签/终止/押金），符合日常操作场景 |
| 财务 | FinanceView | M3 财务与NOI | ✅ **良好** — NOI 汇总卡片(L1) + 快捷入口(账单/费用/抄表/营业额) + 逾期警示 + 收款进度 |
| 工单 | WorkOrderListView | M4 工单系统 | ✅ **可行** — 三类型工单统一列表 + 类型/状态筛选，符合内部员工操作习惯 |
| 二房东 | SubleasesView | M5 二房东穿透 | ✅ **可行** — 审核列表 + 状态筛选，作为管理入口合理 |
| 系统设置 | 子菜单导航 | 跨模块配置 | ✅ **合理** — 用户/组织/KPI方案/预警/模板/申诉/审计日志7个子页面，归类清晰 |

**结论**: Admin 一级页面架构 **设计合理，无需调整顶层结构**。7 个分组精准对应 5 个业务模块 + 概览 + 系统配置，导航深度合理（大多数高频操作在 L1→L2 两层内完成）。

### 1.2 Flutter 移动端（5 Tab + go_router）

| TabBar | 页面 | 评估结论 |
|--------|------|---------|
| 总览 | dashboard/index | ✅ 核心指标 2×2 网格 + 三业态 + 预警，信息密度适合移动端 |
| 资产 | assets/index | ✅ 楼栋列表入口，向下 drill-down 到楼层/单元 |
| 合同 | contracts/index | ✅ 卡片列表 + 下拉筛选 + 上拉加载，标准移动端模式 |
| 工单 | workorders/index | ✅ **核心移动场景**（扫码报修/现场派单），正确占位 TabBar |
| 财务 | finance/index | ✅ 概览 + 账单入口 + KPI 入口 |

**结论**: 5-Tab 结构 **可行且合理**。二房东管理通过 navigateTo 进入（非高频操作）是正确决策。

**关键设计原则确认**：
- ✅ NOI 三级架构（L1 Dashboard → L2 NoiDetailView → L3 Collapse/Dialog）执行到位
- ✅ Flutter 移动端仅承载 L1，L2/L3 由 Admin PC 承载
- ✅ 复杂表单（合同新建/编辑、KPI 方案配置）仅在 Admin 端提供
- ✅ WALE 双口径在 Dashboard(L1) + WaleDetailView(L2) 正确展示

---

## 二、PRD 需求覆盖矩阵

### 2.1 模块 1：资产与空间可视化

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 楼栋档案管理 | Must | ✅ 已覆盖 | BuildingDetailView |
| CAD 平面图导入展示 | Must | ✅ 已覆盖 | FloorPlanView（SVG + 热区） |
| 单元元数据档案 | Must | ✅ 已覆盖 | UnitDetailView |
| 业态差异化字段 | Must | ✅ 已覆盖 | UnitDetailView（条件渲染） |
| 楼层状态色块 | Must | ✅ 已覆盖 | FloorPlanView（CSS class 注入） |
| 改造记录管理 | Must | ⚠️ **查看已有，新增/编辑缺表单** | UnitDetailView（查看）→ 缺 RenovationForm |
| 资产台账导出 | Must | ✅ 已覆盖 | AssetsView 导出按钮 |
| 资产概览看板 | Should | ✅ 已覆盖 | AssetsView 三业态卡片 + DashboardView |
| Excel 批量导入 + dry_run | Must | ✅ **优秀** | UnitImportView（三步骤：选文件→预校验→确认） |
| 热区绑定 unit_id | Must | ✅ 已覆盖 | FloorPlanView（data-unit-id 事件委托） |
| 图纸版本管理 | Must | ❌ **缺失** | FloorPlanView 无上传/版本历史 UI |
| 单元拆分/合并工作流 | Must | ❌ **缺失** | 无专门 UI（仅 UnitDetailView 显示前序单元） |
| 参考市场租金维护 | Must | ✅ 已覆盖 | UnitDetailView 显示 + UnitFormView 编辑 |

#### 缺口详情与建议

**Gap-M1-01: 改造记录新增/编辑表单**

- **现状**: UnitDetailView 有"新增改造记录"按钮，但无对应表单规格
- **PRD 要求**: 改造类型、日期、施工造价、改造前后照片
- **建议**: 通过 **L3 Dialog** 在 UnitDetailView 内弹出表单
- **组件树**:
```
ElDialog(title="新增改造记录" width="560px")
└── ElForm
    ├── ElFormItem("改造类型") → ElSelect(隔间改造/整体翻新/设备更换/其他)
    ├── ElFormItem("改造日期") → ElDatePicker
    ├── ElFormItem("施工造价") → ElInputNumber(prefix="¥")
    ├── ElFormItem("改造前照片") → ElUpload(accept="image/*" :limit="5")
    ├── ElFormItem("改造后照片") → ElUpload(accept="image/*" :limit="5")
    ├── ElFormItem("备注") → ElInput(type="textarea")
    └── ElButton(type="primary") "保存"
```

**Gap-M1-02: 图纸版本管理 UI**

- **现状**: FloorPlanView 仅展示当前 SVG，无上传/版本切换功能
- **PRD 要求**: 同一楼层允许多版本，默认仅展示最新；历史版本只读保留；替换需记录上传人/时间/版本说明
- **建议**: 在 FloorPlanView 工具栏添加 **L2 Drawer** 管理版本
- **组件树**:
```
FloorPlanView 工具栏追加:
├── ElButton(icon="Clock") "版本历史"
│   → ElDrawer(title="图纸版本" direction="rtl")
│     ├── ElButton(type="primary" icon="Upload") "上传新版本"
│     │   → ElDialog: ElUpload + ElInput("版本说明")
│     └── ElTimeline
│         └── ElTimelineItem(v-for="version in versions")
│             ├── 版本号 | 上传人 | 上传时间
│             ├── 版本说明
│             └── ElButton(link) "预览" / "设为当前版本"
```

**Gap-M1-03: 单元拆分/合并工作流**

- **现状**: UnitDetailView 显示 `predecessor_unit_ids` 字段，但无发起拆分/合并的操作入口
- **PRD 要求**: 单元拆分、合并、停租、转非可租需记录前序单元 ID，旧单元标记 archived
- **建议**: 在 UnitDetailView 操作区添加 **L2 Dialog/Wizard**
- **优先级**: 可列为 Should，初始化阶段通过数据导入处理，日常运营中拆合频率低
- **组件树**:
```
UnitDetailView 操作按钮追加:
├── ElDropdown("更多操作")
│   ├── "拆分单元" → ElDialog(UnitSplitWizard)
│   │   Step 1: 选择拆分方式（一分二/一分多）
│   │   Step 2: 填写新单元信息（编号/面积/业态）
│   │   Step 3: 确认（原单元标记archived）
│   ├── "合并单元" → ElDialog(UnitMergeWizard)
│   │   Step 1: 选择要合并的相邻单元
│   │   Step 2: 填写合并后单元信息
│   │   Step 3: 确认
│   └── "停租/转非可租" → ElMessageBox.confirm
```

---

### 2.2 模块 2：租务与合同生命周期管理

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 租客全景画像 | Must | ✅ 已覆盖 | TenantDetailView（基本信息+信用+租赁历史+工单） |
| 合同 CRUD + 多单元绑定 | Must | ✅ 已覆盖 | ContractFormView（M:N 单元表格） |
| 合同状态机 | Must | ✅ 已覆盖 | StatusTag + 操作按钮控制 |
| 提前终止（4种类型） | Must | ✅ **优秀** | ContractTerminateView（含影响预览） |
| 附件管理 | Must | ✅ 已覆盖 | ContractDetailView Tab 5 |
| 续签管理 | Must | ✅ 已覆盖 | ContractRenewView（含押金处理选项） |
| 商铺营业额分成字段 | Must | ✅ 已覆盖 | ContractFormView（v-if retail） |
| 押金独立管理 | Must | ✅ **优秀** | ContractDetailView Tab 3（4种操作弹窗） |
| 预警引擎 | Must | ✅ 已覆盖 | AlertCenterView + Dashboard 预警列表 |
| 预警补发 | Must | ✅ 已覆盖 | AlertCenterView "补发预警"按钮 |
| WALE 双口径 | Must | ✅ 已覆盖 | WaleDetailView（收入+面积并列） |
| WALE 分维度（楼栋/业态）| Must | ✅ 已覆盖 | WaleDetailView（RadioGroup 切换） |
| WALE 趋势图 | Should | ✅ 已覆盖 | WaleDetailView（ECharts 双线） |
| 到期瀑布图 | Should | ✅ 已覆盖 | WaleDetailView（ECharts bar） |
| 递增规则配置器（6类型+混合）| Must | ✅ **优秀** | EscalationConfigView（完整配置） |
| 递增模板管理 | Must | ✅ 已覆盖 | EscalationTemplateListView |
| 未来租金预测表 | Must | ✅ 已覆盖 | EscalationConfigView 底部预测表 |
| 信用评级显示 | Must | ✅ 已覆盖 | TenantListView + TenantDetailView |
| 数据脱敏 + 二次授权 | Must | ✅ 已覆盖 | TenantDetailView（Unlock 按钮） |
| 续签对比（涨跌幅） | Must | ⚠️ **部分覆盖** | ContractRenewView 显示原租金和新租金，但缺自动涨跌幅计算展示 |
| 租金预测导出 Excel | Should | ⚠️ **缺导出按钮** | EscalationConfigView 预测表无导出 |

#### 缺口详情与建议

**Gap-M2-01: 续签涨跌幅对比**

- **现状**: ContractRenewView 展示原合同"当前月租"和新合同"新月租金"字段
- **PRD 要求**: "续签时自动对比原合同末期租金与新合同起始租金，计算实际涨跌幅"
- **建议**: 在 ContractRenewView 的"原合同概要"区域添加 **computed 对比卡片**
```
ElAlert(type="info" :closable="false")
├── "原合同末期月租: ¥{{ oldEndRent }}"
├── "新合同起始月租: ¥{{ form.newRent }}"
└── "涨跌幅: {{ ((form.newRent - oldEndRent) / oldEndRent * 100).toFixed(1) }}%"
    // 正值显示 ↑ success, 负值显示 ↓ danger, 零 → info
```
- **改动量**: 极小，在现有 L2 页面内追加一个计算卡片即可

**Gap-M2-02: 递增模板创建/编辑表单**

- **现状**: EscalationTemplateListView 仅有列表，无 FormView 规格
- **建议**: 复用 EscalationConfigView 的阶段配置组件，包装为模板表单页
- **改动量**: L2 页面 `EscalationTemplateFormView`，复用已有组件

---

### 2.3 模块 3：财务与业财一体化

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 账单列表 + 多维筛选 + 导出 | Must | ✅ 已覆盖 | InvoicesView（含导出按钮） |
| 账单详情 + 费项明细 | Must | ✅ 已覆盖 | InvoiceDetailView |
| 收款核销（部分/拆分/跨账单）| Must | ✅ **优秀** | PaymentFormView（核销分配表） |
| 发票管理（状态+发票号） | Must | ✅ 已覆盖 | InvoiceDetailView"录入发票号" |
| 手工触发账单生成 | Must | ✅ 已覆盖 | InvoicesView"手工触发生成" |
| 账单导出 Excel | Must | ✅ 已覆盖 | InvoicesView 导出按钮 |
| 水电抄表录入 | Must | ✅ 已覆盖 | MeterReadingFormView（含阶梯价格预览） |
| 营业额申报审核 | Must | ✅ 已覆盖 | TurnoverReportListView + DetailView |
| NOI L1 概览 | Must | ✅ 已覆盖 | DashboardView MetricCard |
| NOI L2 完整看板 | Must | ✅ **优秀** | NoiDetailView（瀑布结构+业态分拆+趋势+支出饼图） |
| NOI L3 下钻 | Should | ✅ 已覆盖 | NoiDetailView Collapse 面板（3个） |
| NOI 预算对比 | Must | ✅ 已覆盖 | NoiDetailView"NOI 达成率"卡片 + 趋势叠加 |
| NOI Margin + OpEx Ratio | Must | ✅ 已覆盖 | NoiDetailView 效率指标卡片 |
| 收款进度 | Must | ✅ 已覆盖 | FinanceView 进度条 + DashboardView 环形图 |
| KPI 仪表盘（雷达图/排名/趋势）| Must | ✅ **优秀** | KpiView（完整覆盖） |
| KPI 方案管理（步骤向导）| Must | ✅ 已覆盖 | KpiSchemeFormView（3步ElSteps） |
| KPI 申诉机制 | Must | ✅ 已覆盖 | KpiAppealView（双视角） |
| KPI 导出 Excel | Must | ✅ 已覆盖 | KpiView 导出按钮 |
| KPI 同比/环比 | Must | ✅ 已覆盖 | KpiView 趋势图区域 |
| **运营支出录入/管理** | Must | ❌ **缺失** | FinanceView有快捷链接但无 ExpenseListView / ExpenseFormView |
| **水电抄表列表（历史查看）** | Must | ❌ **缺失** | 仅有 FormView（新增），缺 ListView |
| **收款记录列表** | Should | ❌ **缺失** | 仅有 PaymentFormView，缺 PaymentListView |
| **NOI 预算录入** | Must | ⚠️ **缺录入入口** | NoiDetailView 展示预算但无录入/导入页面 |
| KPI 指标下钻到原始数据 | Should | ⚠️ **部分覆盖** | KpiView Collapse 显示明细但未链接到原始数据 |
| 催收模板配置 | Should | ❌ **缺失** | 无 DunningTemplateView（可 Phase 1.5） |
| 公摊分摊规则配置 | Must | ⚠️ **缺配置 UI** | MeterReadingFormView 计算公摊但无规则配置入口 |

#### 缺口详情与建议

**Gap-M3-01: 运营支出管理页（高优先级 ❗）**

这是 **最大缺口**。NOI = EGI - OpEx，OpEx 中除了工单维修费自动汇入外，还有大量手工录入的经常性支出（物管费、保险、税金、专业服务费）。当前没有页面承载这些数据的录入和查看。

- **建议**: 新增 **L2 页面** `ExpenseListView` + `ExpenseFormView`
- **路由**: `/finance/expenses` + `/finance/expenses/new`
- **组件树**:
```
ExpenseListView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "支出类目: 全部/物管费/水电公摊/维修费/保险/税金/专业服务费"
    │   ├── ElSelect "费用性质: 全部/OpEx/CapEx"
    │   ├── ElSelect "楼栋"
    │   ├── ElDatePicker(type="daterange")
    │   ├── ElButton(icon="Download") "导出"
    │   └── ElButton(type="primary" icon="Plus") "新增支出"
    └── ProposTable
        ├── ElTableColumn("日期")
        ├── ElTableColumn("类目") → ElTag
        ├── ElTableColumn("摘要")
        ├── ElTableColumn("金额(¥)")
        ├── ElTableColumn("费用性质") → ElTag(OpEx=info, CapEx=warning)
        ├── ElTableColumn("归属楼栋")
        ├── ElTableColumn("来源") → ElTag(手录/工单)
        └── ElTableColumn("操作") → [编辑] [删除]
        Footer: "合计: ¥xxx (OpEx: ¥xxx | CapEx: ¥xxx)"

ExpenseFormView
└── ElForm
    ├── ElFormItem("支出类目") → ElSelect(物管费/水电公摊/维修费/保险/税金/专业服务费/其他)
    ├── ElFormItem("费用性质") → ElRadioGroup(OpEx / CapEx)
    ├── ElFormItem("金额") → ElInputNumber(prefix="¥")
    ├── ElFormItem("日期") → ElDatePicker
    ├── ElFormItem("归属楼栋") → ElSelect
    ├── ElFormItem("摘要") → ElInput
    ├── ElFormItem("附件") → ElUpload
    └── ElButton(type="primary") "保存"
```

**Gap-M3-02: 水电抄表列表页**

- **现状**: 仅有 MeterReadingFormView（新增录入），缺少历史抄表记录查看页
- **建议**: 新增 **L2 页面** `MeterReadingListView`
- **路由**: `/finance/meter-readings`
```
MeterReadingListView
└── div
    ├── ElForm(inline)
    │   ├── ElSelect "表计类型: 全部/水表/电表/燃气表"
    │   ├── ElSelect "楼栋"
    │   ├── ElDatePicker(type="month") "抄表周期"
    │   └── ElButton(type="primary" icon="Plus") "录入抄表" → /finance/meter-readings/new
    └── ProposTable
        ├── ElTableColumn("单元")
        ├── ElTableColumn("表计类型")
        ├── ElTableColumn("周期")
        ├── ElTableColumn("上期读数")
        ├── ElTableColumn("本期读数")
        ├── ElTableColumn("用量")
        ├── ElTableColumn("金额(¥)")
        └── ElTableColumn("账单状态") → StatusTag(已生成/未生成)
```

**Gap-M3-03: NOI 预算录入页**

- **现状**: NoiDetailView 显示"NOI 达成率"和预算对比趋势，但无预算数据录入入口
- **PRD 要求**: "支持按楼栋/业态录入年度 NOI 预算（Excel 导入或手动录入）"
- **建议**: 在 NoiDetailView 添加 **L2 Dialog** 或在设置中新增页面
```
NoiDetailView 追加:
├── ElButton(icon="Setting") "预算管理"
│   → ElDialog(title="年度 NOI 预算" width="720px")
│     ├── ElSelect("预算年度: 2026 / 2027")
│     ├── ElTable(border)
│     │   ├── ElTableColumn("楼栋/业态")
│     │   └── ElTableColumn("年度预算(¥)") → ElInputNumber(可编辑)
│     ├── ElButton(icon="Upload") "Excel 导入"
│     └── ElButton(type="primary") "保存预算"
```

**Gap-M3-04: 收款记录列表页**

- **现状**: 收款仅通过 PaymentFormView 从账单详情发起，无独立收款记录查看入口
- **建议**: 新增 **L2 页面** `PaymentListView`（方便财务对账和审计）
- **路由**: `/finance/payments`
- **优先级**: Should — 可通过 InvoiceDetailView 的核销记录替代部分需求

---

### 2.4 模块 4：物业运营与工单系统

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 三类工单（报修/投诉/验房） | Must | ✅ 已覆盖 | WorkOrderFormView（类型选择） |
| 移动端快速报修 | Must | ✅ 已覆盖 | pages/workorders/new |
| 扫码报修 | Must | ✅ 已覆盖 | pages/workorders/scan |
| 照片上传 | Must | ✅ 已覆盖 | WorkOrderFormView |
| 紧急程度标记 | Must | ✅ 已覆盖 | WorkOrderFormView |
| 状态追踪 | Must | ✅ 已覆盖 | WorkOrderDetailView |
| 派单操作 | Must | ✅ 已覆盖 | WorkOrderDetailView（派单Dialog） |
| 维修成本录入（OpEx/CapEx） | Must | ✅ 已覆盖 | WorkOrderDetailView 成本区域 |
| 工单状态机 | Must | ✅ 已覆盖 | 状态依赖操作按钮 |
| **退租验房检查清单** | Must | ⚠️ **部分覆盖** | inspection 类型需专用查验组件 |
| **供应商管理** | Should | ❌ **缺失** | 无 SupplierListView |
| **维修成本汇总报表** | Should | ❌ **缺失** | 无 CostReportView |
| **SLA 倒计时/超时标识** | Must | ⚠️ **未明确** | WorkOrderDetailView 未显示 SLA 状态 |
| 挂起/拒绝/重开操作 | Must | ⚠️ **未明确列出** | 需确认在 DetailView 操作按钮中 |

#### 缺口详情与建议

**Gap-M4-01: 退租验房检查清单组件**

- **现状**: WorkOrderFormView 通过 work_order_type 动态切换字段，但 inspection 类型缺少逐项检查清单
- **PRD 要求**: "验房员逐项检查并拍照记录（墙面、地面、门窗、水电、空调等）"
- **建议**: 在 WorkOrderFormView/DetailView 中通过 **L3 组件** 嵌入检查清单
```
<!-- v-if="type === 'inspection'" -->
InspectionChecklistComponent
└── ElTable(border)
    ├── ElTableColumn("检查项") // 墙面/地面/门窗/水电/空调/其他
    ├── ElTableColumn("状况") → ElSelect(正常/需维修/严重损坏)
    ├── ElTableColumn("照片") → ElUpload(:limit="3")
    └── ElTableColumn("备注") → ElInput
Footer:
├── ElFormItem("查验结论") → ElRadioGroup(正常交还 / 需维修)
└── ElFormItem("押金扣减建议(¥)") → ElInputNumber (v-if 需维修)
```

**Gap-M4-02: 供应商管理页**

- **建议**: 新增 **L2 页面** `SupplierListView` + 新增弹窗
- **路由**: `/settings/suppliers`（归入系统设置）
- **优先级**: Should — Phase 1 可先在工单表单中提供自由文本输入供应商信息

**Gap-M4-03: 维修成本汇总报表**

- **PRD 要求**: "按时间段/楼栋/费用类型/工单类型查看维修费用汇总"
- **建议**: 成本数据已汇入 NOI OpEx，可在 ExpenseListView 中通过 "来源=工单" 筛选覆盖
- **优先级**: Should — 启用 Gap-M3-01 的 ExpenseListView 后即可满足

**Gap-M4-04: SLA 状态展示**

- **建议**: 在 WorkOrderDetailView 和 WorkOrderListView 中追加 SLA 倒计时或超时标识
```
WorkOrderDetailView 追加:
├── ElDescriptionsItem("派单 SLA")
│   └── v-if="未派单"
│       ElCountdown(:value="slaDeadline") 或 ElTag(type="danger") "已超时 2h"
├── ElDescriptionsItem("完工 SLA")
│   └── v-if="处理中"
│       ElTag(type="warning") "预计完成: 2026-04-10 18:00"

WorkOrderListView 追加:
├── ElTableColumn("SLA") → ElTag(type="danger" v-if="slaExpired") "超时"
```

---

### 2.5 模块 5：二房东穿透管理

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 内部管理列表 + 审核 | Must | ✅ 已覆盖 | SubleasesView |
| 外部门户（单元列表+填报表单）| Must | ✅ 已覆盖 | SubLandlordPortalLayout + SubleaseFillingView |
| 批量导入 | Must | ✅ 已覆盖 | SubleaseImportView |
| 审核通过/退回 | Must | ✅ 已覆盖 | SubleasesView 操作列 |
| 退回原因展示 + 重提 | Must | ✅ 已覆盖 | SubleaseFillingView（ElAlert 退回面板） |
| 合同详情子租赁 Tab | Must | ✅ 已覆盖 | ContractDetailView Tab 4 |
| 填报进度监控 | Must | ✅ 已覆盖 | 外部门户顶部 ElProgress |
| 楼层穿透模式 | Should | ✅ 已覆盖 | FloorPlanView "穿透模式"开关 |
| **穿透分析看板** | Should | ❌ **缺失** | 无 SubleasePenetrationDashboard |
| **转租溢价分析** | Should | ❌ **缺失** | 无溢价计算展示 |
| **穿透出租率** | Should | ❌ **缺失** | 无穿透 vs 整体出租率对比 |
| **子租赁到期预警** | Should | ⚠️ **部分** | AlertCenterView 支持但未明确此类型 |
| **提交版本历史对比** | Must | ⚠️ **缺版本对比 UI** | 仅记录变更日志，无差异展示 |

#### 缺口详情与建议

**Gap-M5-01: 穿透分析看板（建议新增 L2 页面）**

- **PRD 5.5** 描述了完整的穿透分析看板需求
- **建议**: 新增 `SubleasePenetrationView`
- **路由**: `/subleases/analytics`
```
SubleasePenetrationView
└── div
    ├── ── 二房东总览卡片 ──
    │   ElRow(:gutter="24")
    │   └── ElCard(v-for="landlord in subLandlords")
    │       ├── ElStatistic("主合同月租金", "¥xxx")
    │       ├── ElStatistic("已填报单元", "45/60")
    │       ├── ElStatistic("终端出租面积", "xxx m²")
    │       └── ElStatistic("终端空置面积", "xxx m²" type="danger")
    │
    ├── ── 转租溢价分析 ──
    │   ElCard(header="转租溢价分析")
    │   └── ElTable
    │       ├── ElTableColumn("二房东")
    │       ├── ElTableColumn("主合同单价(¥/m²)")
    │       ├── ElTableColumn("终端平均单价(¥/m²)")
    │       ├── ElTableColumn("溢价率") → ElTag(type="warning")
    │       └── ElTableColumn("终端出租率")
    │
    ├── ── 穿透出租率对比 ──
    │   ElCard(header="穿透出租率 vs 整体出租率")
    │   └── ECharts(type: bar, 对比柱状图)
    │
    └── ── 填报完整度监控 ──
        ElCard(header="填报完整度")
        └── ElTable
            ├── ElTableColumn("二房东")
            ├── ElTableColumn("应填报")
            ├── ElTableColumn("已填报")
            └── ElTableColumn("完成率") → ElProgress
```
- **优先级**: Should — 可在 Must 功能闭环后迭代

---

### 2.6 系统设置 & 跨模块需求

| PRD 需求 | 优先级 | 前端覆盖情况 | 覆盖页面 |
|---------|--------|------------|---------|
| 用户管理 CRUD | Must | ✅ 已覆盖 | UserManagementView + UserFormView |
| 组织架构三级树 | Must | ✅ **优秀** | OrganizationManageView（左右布局） |
| 管辖范围配置 | Must | ✅ 已覆盖 | OrganizationManageView 右侧面板 |
| 审计日志 | Must | ✅ 已覆盖 | AuditLogView（4类操作筛选） |
| **导入批次管理/回滚** | Must | ⚠️ **部分覆盖** | UnitImportView 支持导入但无历史批次列表和回滚入口 |
| **二房东账号与主合同联动** | Must | ⚠️ **未明确** | UserFormView 角色下拉含 sub_landlord 但无合同绑定字段 |

#### 缺口详情与建议

**Gap-S-01: 导入批次历史与回滚**

- **PRD 要求**: "支持按导入批次回滚（撤销某次导入的全部数据），需记录每条数据的导入批次号"
- **建议**: 在 UnitImportView 末尾或新增独立页面展示导入历史
```
UnitImportView 追加（或独立 /assets/import-history）:
ElCard(header="导入历史")
└── ElTable
    ├── ElTableColumn("批次号")
    ├── ElTableColumn("数据类型")
    ├── ElTableColumn("导入时间")
    ├── ElTableColumn("操作人")
    ├── ElTableColumn("总条数/成功/失败")
    └── ElTableColumn("操作")
        ├── ElButton(link) "查看明细"
        └── ElButton(link type="danger") "回滚"
            → ElMessageBox.confirm("确认回滚？将撤销此批次全部数据")
```

**Gap-S-02: 二房东账号与主合同关联**

- **建议**: 在 UserFormView 中，当角色选择 `sub_landlord` 时动态显示合同绑定字段
```
<!-- v-if="form.role === 'sub_landlord'" -->
ElDivider "二房东配置"
├── ElFormItem("关联主合同") → ElSelect(filterable remote :options="masterContracts")
├── ElFormItem("账号有效期") → ElDatePicker(disabled, 自动同步合同到期日)
└── ElText(type="info") "账号有效期将自动与主合同到期日同步"
```

---

## 三、缺口优先级汇总与处理建议

### 必须补充（Must 级 / 影响业务闭环）

| 编号 | 缺口 | 影响模块 | 建议层级 | 工作量评估 |
|------|------|---------|---------|-----------|
| **Gap-M3-01** | 运营支出录入/管理页 | M3 NOI | L2 页面（新增2个View） | 中 |
| **Gap-M3-02** | 水电抄表列表页 | M3 水电 | L2 页面（新增1个View） | 小 |
| **Gap-M3-03** | NOI 预算录入入口 | M3 NOI/KPI K07 | L2 Dialog（现有页面追加） | 小 |
| **Gap-M4-01** | 退租验房检查清单 | M4 工单 | L3 组件（嵌入现有页面） | 中 |
| **Gap-M4-04** | SLA 状态展示 | M4 工单 | L1/L2 字段追加 | 小 |
| **Gap-M1-01** | 改造记录新增/编辑表单 | M1 资产 | L3 Dialog | 小 |
| **Gap-M1-02** | 图纸版本管理 UI | M1 资产 | L2 Drawer | 小 |
| **Gap-S-01** | 导入批次历史/回滚 | 跨模块 | L2 区域/页面 | 小 |
| **Gap-S-02** | 二房东账号合同关联 | M5 安全 | 表单字段追加 | 极小 |

### 建议补充（Should 级 / 提升管理效能）

| 编号 | 缺口 | 影响模块 | 建议层级 | 工作量评估 |
|------|------|---------|---------|-----------|
| **Gap-M5-01** | 穿透分析看板 | M5 分析 | L2 页面（新增） | 中 |
| **Gap-M3-04** | 收款记录列表页 | M3 财务 | L2 页面（新增） | 小 |
| **Gap-M4-02** | 供应商管理页 | M4 工单 | L2 页面（新增） | 小 |
| **Gap-M1-03** | 单元拆分/合并工作流 | M1 资产 | L2 Dialog/Wizard | 中 |
| **Gap-M2-01** | 续签涨跌幅对比 | M2 合同 | 计算卡片追加 | 极小 |
| **Gap-M2-02** | 递增模板创建/编辑表单 | M2 配置 | L2 页面 | 小 |

### 可延后（Could 级 / Phase 1.5）

| 编号 | 缺口 | 说明 |
|------|------|------|
| 催收模板配置 | M3 催收 | 后端模板即可，管理 UI 可 Phase 1.5 |
| 公摊分摊规则配置 | M3 水电 | 可先用固定面积比例，配置 UI 延后 |
| KPI 指标深度下钻 | M3 KPI | Collapse 明细已满足基本需求 |

---

## 四、最终建议

### 4.1 不建议修改的内容

1. **Admin 7 分组侧边栏结构** — 合理完整，无需调整
2. **Flutter 5-Tab 结构** — 符合移动端操作习惯
3. **NOI 三级架构** — 设计精良，渐进披露到位
4. **押金管理嵌入合同详情 Tab** — 比独立页面更符合业务语境（押金始终关联合同）
5. **KPI 放置在财务模块下** — 财务与考核的关联性最强，归类合理

### 4.2 建议立即补充的页面

按优先级排序：

1. **ExpenseListView + ExpenseFormView** (`/finance/expenses`) — NOI 计算依赖，无此页面 OpEx 数据无法录入
2. **MeterReadingListView** (`/finance/meter-readings`) — 月度抄表是高频操作，需要查看历史记录
3. **NOI 预算录入 Dialog** — KPI K07（NOI 达成率）依赖预算基准
4. **退租验房检查清单组件** — 验房是 inspection 类型工单的核心差异化功能
5. **改造记录表单 Dialog** — 资产管理基础操作
6. **图纸版本管理 Drawer** — PRD Must 级要求
7. **SLA 状态标识** — 工单管理基础需求
8. **导入批次管理** — 数据初始化阶段强依赖

### 4.3 页面总数预估调整

| 类别 | 当前 PAGE_SPEC | 补充后 | 变化 |
|------|---------------|--------|------|
| Admin Views | 44 | **50** | +6（ExpenseList/Form, MeterReadingList, PaymentList, SupplierList, PenetrationDashboard） |
| Flutter Pages | 16 | 16 | 无变化（缺口均为 Admin 端） |
| 外部门户 | 3 | 3 | 无变化 |
| **合计** | **63** | **69** | **+6 个 L2 页面** |
| Dialog/Drawer（L3） | 未统计 | +5 | 改造表单/图纸版本/预算录入/检查清单/拆合向导 |

> 所有缺口均通过 **L2 子页面**或 **L3 Dialog/Drawer** 补充，**L1 一级页面架构无需调整**。
