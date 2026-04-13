# PropOS 后端 API 清单草案 v1.7

> 版本: v1.5
> 日期: 2026-04-13
> 范围: Phase 1 Must + 部分 Should
> 依据: PRD v1.8 / ARCH v1.4 / data_model v1.4
> 说明: 所有接口统一使用响应信封。成功为 `{ data, meta? }`，失败为 `{ error: { code, message } }`。分页参数统一为 `page` 和 `pageSize`，默认 20，最大 100。
> **契约文档**: 各端点字段级 Request/Response DTO 定义见 [API_CONTRACT_v1.7.md](API_CONTRACT_v1.7.md)

---

## 一、认证与用户

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/auth/login | 登录并获取 access token | 公共 |
| POST | /api/auth/refresh | 刷新 token | 已登录 |
| POST | /api/auth/logout | 注销当前会话 | 已登录 |
| GET | /api/auth/me | 获取当前用户与权限 | 已登录 |
| GET | /api/users | 用户列表（支持 `role`、`department_id`、`is_active` 过滤） | super_admin |
| GET | /api/users/:id | 用户详情 | super_admin |
| POST | /api/users | 创建后台账号或二房东账号 | super_admin |
| PATCH | /api/users/:id | 更新用户基本信息（`name`、`email`） | super_admin |
| PATCH | /api/users/:id/status | 启停用账号 | super_admin |
| PATCH | /api/users/:id/role | 变更角色 | super_admin |
| PATCH | /api/users/:id/department | 变更员工所属部门 | super_admin |
| POST | /api/auth/change-password | 修改密码（需提供旧密码，触发 `session_version` 递增） | 已登录 |

### 认证接口备注

1. 登录失败达到阈值后返回 `ACCOUNT_LOCKED`。
2. 二房东账号首次登录需触发强制改密流程。
3. 主合同冻结或改密后，旧 token 应因 `session_version` 失效。
4. 密码复杂度：最少 8 位，必须含大小写字母 + 数字，禁止与用户名相同（v1.7）。
5. `POST /api/auth/change-password` 成功后返回新的 access token 和 refresh token（旧会话立即失效）。

---

## 一-A、组织架构管理

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/departments | 部门树列表（返回嵌套结构，最多 3 级） | org.read |
| POST | /api/departments | 创建部门 | org.manage |
| PATCH | /api/departments/:id | 更新部门（名称、排序、父级） | org.manage |
| DELETE | /api/departments/:id | 停用部门（逻辑删除，设 `is_active = false`） | org.manage |
| GET | /api/managed-scopes | 查询管辖范围（支持按 `department_id` 或 `user_id` 过滤） | org.read |
| PUT | /api/managed-scopes | 设置管辖范围（批量覆写某部门或某用户的范围配置） | org.manage |

### 组织架构接口备注

1. 部门树最多 3 级（公司→部门→组），创建时校验 `level` 不超过 3。
2. 停用部门前需检查是否有在职员工，若有则返回 `DEPARTMENT_HAS_ACTIVE_USERS`。
3. 管辖范围支持绑定到部门（默认范围）或个人（覆盖范围），KPI 取数时个人范围优先于部门默认。

---

## 二、资产模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/buildings | 楼栋列表 | assets.read |
| POST | /api/buildings | 创建楼栋 | assets.write |
| GET | /api/buildings/:id | 楼栋详情 | assets.read |
| PATCH | /api/buildings/:id | 更新楼栋 | assets.write |
| GET | /api/floors | 楼层列表 | assets.read |
| POST | /api/floors | 创建楼层 | assets.write |
| GET | /api/floors/:id | 楼层详情 | assets.read |
| POST | /api/floors/:id/cad | 上传楼层图并触发转换 | assets.write |
| GET | /api/floors/:id/heatmap | 获取热区与状态色块 | assets.read |
| GET | /api/floors/:id/plans | 楼层图纸版本列表 | assets.read |
| PATCH | /api/floor-plans/:id/set-current | 将指定版本设为当前生效版本 | assets.write |
| GET | /api/units | 单元分页列表 | assets.read |
| POST | /api/units | 创建单元 | assets.write |
| GET | /api/units/:id | 单元详情（含 `market_rent_reference`、`predecessor_unit_ids`、`archived_at`） | assets.read |
| PATCH | /api/units/:id | 更新单元 | assets.write |
| POST | /api/units/import | 批量导入单元 | assets.write |
| GET | /api/renovations | 改造记录列表（支持按 `unit_id` 过滤） | assets.read |
| POST | /api/renovations | 新增改造记录 | assets.write |
| GET | /api/renovations/:id | 改造记录详情 | assets.read |
| PATCH | /api/renovations/:id | 更新改造记录 | assets.write |
| POST | /api/renovations/:id/photos | 上传改造前/后照片（`photo_stage=before/after`） | assets.write |
| GET | /api/units/export | 导出全部房源台账 Excel（支持 `property_type` 筛选） | assets.read |
| GET | /api/assets/overview | 资产概览看板（按业态汇总：总套数/已租/空置/出租率） | assets.read |

### 资产接口备注（v1.7 新增）

1. `PATCH /api/units/:id` 更改为归档时需设置 `archived_at`，旧单元不物理删除。
2. 单元拆分/合并时 `predecessor_unit_ids` 记录前序单元 ID 列表，保持历史合同关联不脱钩。
3. `GET /api/floors/:id/plans` 返回该楼层的所有图纸版本，包含 `is_current`、上传人、上传时间、`version_label`。
4. `GET /api/units/export` 按 `property_type` 三业态分别导出（`office`/`retail`/`apartment`），生成 Excel 文件直接返回二进制流（`Content-Disposition: attachment`）。

---

## 三、租务与合同

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/tenants | 租客列表（含 `credit_rating` 字段） | contracts.read |
| POST | /api/tenants | 创建租客 | contracts.write |
| GET | /api/tenants/:id | 租客详情（含信用评级与逾期统计） | contracts.read |
| PATCH | /api/tenants/:id | 更新租客 | contracts.write |
| POST | /api/tenants/:id/unmask | 二次鉴权后返回租客证件号/手机完整明文（请求体传 `current_password`，成功后写审计日志） | contracts.read |
| GET | /api/contracts | 合同分页列表 | contracts.read |
| POST | /api/contracts | 创建合同（支持多单元通过 `contract_units` 绑定） | contracts.write |
| GET | /api/contracts/:id | 合同详情（含 `tax_inclusive`、`applicable_tax_rate`、终止信息） | contracts.read |
| PATCH | /api/contracts/:id | 更新合同 | contracts.write |
| POST | /api/contracts/:id/attachments | 上传合同附件 | contracts.write |
| GET | /api/contracts/:id/attachments | 合同附件列表（返回当前合同的所有附件） | contracts.read |
| POST | /api/contracts/:id/renew | 创建续签合同 | contracts.write |
| POST | /api/contracts/:id/terminate | 执行合同提前终止（v1.7 新增） | contracts.write |
| GET | /api/contracts/:id/escalation-phases | 查询递增阶段 | contracts.read |
| PUT | /api/contracts/:id/escalation-phases | 覆盖递增阶段配置 | contracts.write |
| GET | /api/contracts/wale | 查询 WALE 双口径（收入加权 + 面积加权），支持 `groupBy` | contracts.read |
| GET | /api/alerts | 预警列表（支持 `contract_id`、`alert_type`、`is_read` 过滤） | alerts.read |
| GET | /api/alerts/unread | 未读预警数量（桌面端/Web 30 秒轮询使用，返回 `{ data: { count } }`） | alerts.read |
| PATCH | /api/alerts/:id/read | 标记单条预警已读 | alerts.read |
| POST | /api/alerts/read-all | 批量标记所有预警已读 | alerts.read |
| POST | /api/alerts/replay | 按条件补发预警 | alerts.write |

## 三-A、押金管理（v1.7 新增）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/contracts/:id/deposits | 查询合同关联押金列表 | deposit.read |
| POST | /api/contracts/:id/deposits | 创建押金记录（状态 `collected`） | deposit.write |
| GET | /api/deposits/:id | 押金详情（含交易流水） | deposit.read |
| POST | /api/deposits/:id/freeze | 冻结押金 | deposit.write |
| POST | /api/deposits/:id/deduct | 部分冲抵（需金额、原因） | deposit.write |
| POST | /api/deposits/:id/refund | 退还押金（需财务确认无欠费） | deposit.write |
| POST | /api/deposits/:id/transfer | 转移至续签合同 | deposit.write |
| GET | /api/deposits/:id/transactions | 押金交易流水查询 | deposit.read |

### 押金接口备注

1. 押金不计入 NOI 收入，独立于租金账单体系。
2. 状态流转：`collected → frozen → partially_credited → refunded`，每次变更记录到 `deposit_transactions`。
3. 押金退还触发前，系统需校验合同无未结账单。
4. 每次状态变更均写入审计日志。

---

## 三-B、租金递增模板

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/escalation-templates | 递增规则模板列表（支持按 `property_type`、`is_active` 过滤） | contracts.read |
| POST | /api/escalation-templates | 创建递增规则模板 | contracts.write |
| GET | /api/escalation-templates/:id | 模板详情（含各阶段配置） | contracts.read |
| PATCH | /api/escalation-templates/:id | 更新模板 | contracts.write |
| DELETE | /api/escalation-templates/:id | 停用模板（逻辑删除，设 `is_active = false`） | contracts.write |
| POST | /api/contracts/:id/apply-template | 将模板阶段复制到合同递增配置（幂等：覆盖已有阶段） | contracts.write |

---

## 三-C、合同租金预测与 WALE 趋势（Should）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/contracts/:id/rent-forecast | 合同全生命周期租金预测表（按 `granularity=monthly/yearly`） | contracts.read |
| GET | /api/contracts/:id/rent-forecast/export | 导出租金预测 Excel | contracts.read |
| GET | /api/contracts/wale/trend | WALE 近 12 个月历史趋势（支持 `groupBy=building/property_type`） | contracts.read |
| GET | /api/contracts/wale/waterfall | 未来到期瀑布图（按年份分布到期面积与租金） | contracts.read |

### 合同接口备注（v1.7 变更）

1. `POST /api/contracts` 请求体新增 `contract_units[]`（每项含 `unit_id`、`billing_area`、`unit_price`），替代原 `unit_id` 单值字段。
2. `POST /api/contracts/:id/terminate` 请求体需包含 `termination_type`（`tenant_early | negotiated | owner_termination`）、`termination_date`、`penalty_amount`、`deposit_deduction_details`、`termination_reason`。终止后自动取消未生成账单、关闭递增规则、触发押金流程。
3. WALE 接口返回 `wale_income_weighted` 和 `wale_area_weighted` 双口径；已终止合同（`termination_type IS NOT NULL`）剩余租期归零不参与计算。
4. 租客信用评级（`credit_rating`）每月 1 日自动重算：A（逾期≤1次且≤3天）/ B（2~3次或4~15天）/ C（≥4次或>15天）。
5. `PATCH /api/contracts/:id` 可变更字段白名单：`payment_cycle_months`、`management_fee_rate`、`tax_inclusive`、`applicable_tax_rate`、`revenue_share_rate`、`min_guarantee_rent`；合同关联单元（`contract_units`）**不可通过此端点变更**，如需调整请终止当前合同后创建新合同。
6. `POST /api/tenants/:id/unmask` 请求体传 `current_password`（二次鉴权），验证通过后返回完整证件号与手机号，并写入审计日志（`action="tenant.view_sensitive"`）。脱敏策略：证件号默认返回 `****XXXX`（末4位），手机默认返回 `***XXXX`（末4位）。

---

## 四、财务与 NOI

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/invoices | 账单分页列表 | finance.read |
| POST | /api/invoices/generate | 手工触发账单生成 | finance.write |
| GET | /api/invoices/export | 导出账单 Excel（支持 `period`、`building_id`、`property_type`、`tenant_id` 过滤） | finance.read |
| GET | /api/invoices/:id | 账单详情 | finance.read |
| GET | /api/invoices/:id/items | 账单费项明细 | finance.read |
| PATCH | /api/invoices/:id | 更新账单（录入外部发票号、标记已开票、修正到期日等） | finance.write |
| POST | /api/invoices/:id/void | 作废账单（需填写原因，限 `issued` 状态） | finance.write |
| POST | /api/payments | 新增收款主记录并分配核销 | finance.write |
| GET | /api/payments | 收款记录列表 | finance.read |
| GET | /api/payments/:id | 收款与分配详情 | finance.read |
| PATCH | /api/payments/:id/allocations | 调整核销分配 | finance.write |
| GET | /api/expenses | 运营支出列表 | finance.read |
| POST | /api/expenses | 新增运营支出 | finance.write |
| PATCH | /api/expenses/:id | 更新运营支出 | finance.write |
| DELETE | /api/expenses/:id | 删除运营支出（限未关联工单的记录） | finance.write |
| GET | /api/noi/summary | NOI 汇总卡片（不含税口径） | finance.read |
| GET | /api/noi/trend | NOI 趋势 | finance.read |
| GET | /api/noi/breakdown | 按楼栋或业态拆分 NOI | finance.read |
| GET | /api/noi/vacancy-loss | 空置损失测算（基于 `market_rent_reference` 字段） | finance.read |
| GET | /api/noi/budget | NOI 预算列表 | finance.read |
| POST | /api/noi/budget | 录入 NOI 预算（用于 K07 NOI 达成率计算） | finance.write |
| GET | /api/kpi/metrics | KPI 指标定义库列表（K01~K10，含 `direction`、`is_enabled`） | kpi.view |
| PATCH | /api/kpi/metrics/:id | 启用/停用指标（`is_enabled`） | kpi.manage |
| POST | /api/kpi/metrics/:id/manual-input | 录入手动指标值（仅 K10 租户满意度，需 `period_start`、`period_end`、`value`、`target_user_id`） | kpi.manage |
| GET | /api/kpi/schemes | KPI 考核方案列表 | kpi.view |
| POST | /api/kpi/schemes | 创建 KPI 考核方案 | kpi.manage |
| GET | /api/kpi/schemes/:id | KPI 方案详情（含绑定指标与权重） | kpi.view |
| PATCH | /api/kpi/schemes/:id | 更新方案基本信息（名称、周期、有效期等） | kpi.manage |
| DELETE | /api/kpi/schemes/:id | 停用方案（逻辑删除，已有快照不受影响） | kpi.manage |
| GET | /api/kpi/schemes/:id/metrics | 方案指标列表（含权重与阈值覆盖） | kpi.view |
| PUT | /api/kpi/schemes/:id/metrics | 覆盖方案指标配置（权重/阈值，需校验权重之和 = 100%） | kpi.manage |
| GET | /api/kpi/schemes/:id/targets | 方案绑定对象列表 | kpi.view |
| PUT | /api/kpi/schemes/:id/targets | 设置方案绑定对象（部门/员工，批量覆写） | kpi.manage |
| GET | /api/kpi/scores | KPI 快照列表（支持 `scheme_id`、`evaluated_user_id`、`period` 过滤） | kpi.view |
| POST | /api/kpi/scores/generate | 触发指定方案+周期的 KPI 打分（生成快照草稿） | kpi.manage |
| POST | /api/kpi/scores/recalculate | 手工重算 KPI 快照（需快照 ID，保留重算审计记录） | kpi.manage |
| GET | /api/kpi/scores/:id | KPI 快照详情（含各指标实际值、得分、加权得分） | kpi.view |
| POST | /api/kpi/scores/:id/freeze | 冻结 KPI 快照草稿（`draft → frozen`，触发申诉窗口 7 日计时，写 `frozen_at`） | kpi.manage |
| GET | /api/kpi/rankings | KPI 排名榜（按方案+周期+维度） | kpi.view |
| GET | /api/kpi/trends | KPI 历史趋势 + 同比环比 | kpi.view |
| GET | /api/kpi/export | 导出 KPI 评分报告（Excel） | kpi.manage |
| POST | /api/kpi/appeals | 提交 KPI 申诉 | kpi.appeal |
| GET | /api/kpi/appeals | 申诉列表（支持按状态过滤） | kpi.view |
| PATCH | /api/kpi/appeals/:id/review | 审核申诉（批准/驳回） | kpi.manage |

### 财务接口备注

1. `POST /api/payments` 需要支持一笔收款分配到多张账单。
2. `PATCH /api/payments/:id/allocations` 仅允许在未结账或未锁账期间调整。
3. NOI 默认返回不含税经营口径（v1.7 明确），需通过查询参数区分 `receivable` 和 `received` 视角。
4. KPI 方案中指标新增 `direction` 字段（`positive` / `negative`），反向指标线性插值逻辑翻转（v1.7）。
5. KPI 已升级为正式考核模块，`scoring_mode` 默认为 `'official'`。
6. 申诉窗口为快照冻结后 7 个自然日，超时返回 `APPEAL_WINDOW_CLOSED`。
7. Excel 导出包含方案名、周期、各指标实际值/得分/加权得分详细明细。
8. `POST /api/noi/budget` 录入格式：`{ building_id?, property_type?, period_year, period_month?, budget_noi }`；K07 取数时以最近一条匹配的预算为基准。
9. `GET /api/invoices/export` 直接返回 Excel 二进制流，文件名格式 `invoices_{period}.xlsx`。
10. `POST /api/invoices/:id/void` 作废账单后，系统自动对应收款核销分配做反冲，写审计日志。
11. `POST /api/kpi/scores/generate` 执行后返回快照草稿（`snapshot_status='draft'`），管理员确认后调用 `POST /api/kpi/scores/:id/freeze` 冻结；冻结后 `snapshot_status` 变为 `frozen`，`frozen_at` 记录冻结时间，申诉窗口 7 日从此刻起算。重算后状态变为 `recalculated`，不可再次申诉。

---

## 四-A、水电抄表（v1.7 新增）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/meter-readings | 抄表记录分页列表（支持按 `unit_id`、`meter_type`、`reading_cycle` 过滤） | finance.read |
| POST | /api/meter-readings | 录入抄表读数 | meterReading.write |
| GET | /api/meter-readings/:id | 抄表详情（含费用计算明细） | finance.read |
| PATCH | /api/meter-readings/:id | 修正抄表记录（限未生成账单前） | meterReading.write |

### 水电抄表接口备注

1. `POST /api/meter-readings` 请求体：`unit_id`、`meter_type`（`water` / `electricity` / `gas`）、`reading_cycle`、`previous_reading`、`current_reading`。
2. 系统自动校验 `current_reading > previous_reading`，否则返回 `INVALID_READING`。
3. 用量 = `current_reading - previous_reading`，支持阶梯计价（`tier1_limit`、`tier1_price`、`tier2_price`）。
4. 录入成功后自动生成水电费账单（`invoice_type = 'utility'`）。

---

## 四-B、商铺营业额申报（v1.7 新增）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/turnover-reports | 营业额申报列表 | finance.read |
| POST | /api/turnover-reports | 商户提交营业额申报 | finance.write |
| GET | /api/turnover-reports/:id | 申报详情 | finance.read |
| PATCH | /api/turnover-reports/:id/approve | 财务审核通过 | turnoverReview.approve |
| PATCH | /api/turnover-reports/:id/reject | 财务审核退回（需填退回原因） | turnoverReview.approve |

### 营业额申报接口备注

1. 请求体：`contract_id`、`report_month`、`reported_revenue`、`supporting_docs[]`。
2. 审核状态流转：`pending → approved / rejected`，退回后允许商户修正后重提。
3. 审核通过后自动生成分成账单 = `MAX(revenue × share_rate - base_rent, 0)`。
4. 补报或修正时系统自动生成差额账单。
5. 仅 `approved` 状态的申报数据参与 NOI 收入计算。

---

## 五、工单模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/workorders | 工单分页列表（支持 `work_order_type` 筛选：`repair` / `complaint` / `inspection`） | workorders.read |
| POST | /api/workorders | 创建工单（需指定 `work_order_type`，默认 `repair`） | workorders.write |
| GET | /api/workorders/:id | 工单详情 | workorders.read |
| PATCH | /api/workorders/:id/approve | 审核/派单 | workorders.write |
| PATCH | /api/workorders/:id/reject | 拒绝工单（需填写原因，仅限 `submitted` 或 `pending_inspection` 状态） | workorders.write |
| PATCH | /api/workorders/:id/start | 开始处理 | workorders.write |
| PATCH | /api/workorders/:id/hold | 挂起工单 | workorders.write |
| PATCH | /api/workorders/:id/complete | 完工并录入成本 | workorders.write |
| PATCH | /api/workorders/:id/inspect | 验收工单 | workorders.write |
| PATCH | /api/workorders/:id/reopen | 重开工单 | workorders.write |
| POST | /api/workorders/:id/photos | 上传工单照片 | workorders.write |
| GET | /api/suppliers | 供应商列表 | workorders.read |
| POST | /api/suppliers | 新增供应商 | workorders.write |
| GET | /api/suppliers/:id | 供应商详情 | workorders.read |
| PATCH | /api/suppliers/:id | 更新供应商信息 | workorders.write |

---

## 六、二房东穿透模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/sublease-portal/login | 二房东门户登录 | 公共 |
| GET | /api/sublease-portal/units | 获取当前二房东可填报单元列表 | sublease.portal |
| GET | /api/sublease-portal/subleases | 获取当前二房东已提交记录 | sublease.portal |
| POST | /api/sublease-portal/subleases | 新增子租赁填报（支持 `review_status=draft` 暂存） | sublease.portal |
| POST | /api/sublease-portal/subleases/import | 批量导入子租赁（固定路径，须在 `/:id` 路由前注册） | sublease.portal |
| GET | /api/sublease-portal/subleases/:id | 查询单条子租赁填报详情（行级隔离：仅可见自身主合同范围） | sublease.portal |
| PATCH | /api/sublease-portal/subleases/:id | 修改待审核或退回记录 | sublease.portal |
| POST | /api/sublease-portal/subleases/:id/submit | 将草稿提交审核（`draft → pending`） | sublease.portal |
| DELETE | /api/sublease-portal/subleases/:id | 删除草稿（仅限 `draft` 状态） | sublease.portal |
| GET | /api/subleases | 内部子租赁分页列表 | sublease.read |
| GET | /api/subleases/:id | 子租赁详情 | sublease.read |
| POST | /api/subleases/:id/unmask | 二次鉴权后返回子租赁方证件号/手机完整明文（请求体传 `current_password`，写审计日志） | sublease.read |
| PATCH | /api/subleases/:id/approve | 审核通过 | sublease.write |
| PATCH | /api/subleases/:id/reject | 退回并填写原因 | sublease.write |
| GET | /api/subleases/dashboard | 穿透基础看板（含穿透出租率、空置/在租/未入住统计） | sublease.read |
| GET | /api/subleases/export | 导出子租赁数据 Excel（仅 `approved` 记录） | sublease.read |

### 二房东接口备注

1. 门户类接口除 RBAC 外，必须在 Repository 层追加主合同范围过滤。
2. 仅 `approved` 记录参与穿透看板和统计口径。
3. 查看完整证件号或手机号必须通过 `POST /api/subleases/:id/unmask`（或 `/api/tenants/:id/unmask`）进行二次鉴权（请求体传 `current_password`），默认详情接口返回脱敏值（末4位），不得直接暴露明文；每次 unmask 调用均写审计日志（`action="sublease.view_sensitive"` / `"tenant.view_sensitive"`）。
4. 强制 HTTPS（TLS 1.2+），禁止 HTTP 明文访问（v1.7）。

---

## 七、数据导入与批次管理（v1.7 新增）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/imports | 提交导入任务（支持 `dry_run` 模式） | assets.write / contracts.write |
| GET | /api/imports | 导入批次列表 | assets.read |
| GET | /api/imports/:id | 批次详情（含成功/失败行数与错误明细） | assets.read |
| POST | /api/imports/:id/rollback | 按批次回滚导入数据 | super_admin |
| GET | /api/imports/:id/errors | 获取错误行详细报告（Excel 下载） | assets.read |

### 导入接口备注

1. `POST /api/imports` 请求体包含 `data_type`（`unit` / `contract` / `sublease` / `invoice`）+ Excel 文件。
2. `dry_run = true` 时仅执行校验，不写入数据库，返回校验结果预览。
3. 单元台账导入使用整批回滚（一条出错全部不导入）；合同和账单使用部分导入。
4. 每条导入数据标记 `import_batch_id`，支持按批次精确回滚。
5. 回滚操作限 `super_admin` 权限，需记录审计日志。

---

## 八、运维与辅助接口

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/jobs/executions | 定时任务执行列表 | ops.read |
| POST | /api/jobs/executions/:id/retry | 手工重试失败任务 | ops.write |
| GET | /api/files/:path | 代理下载附件或图纸 | 已登录 |
| POST | /api/files | 通用文件上传（返回存储路径，供业务接口引用） | 已登录 |
| GET | /api/audit-logs | 审计日志分页列表（支持 `resource_type`、`resource_id`、`user_id`、`created_at` 范围过滤） | super_admin |
| GET | /api/health | 健康检查 | 公共 |

### 运维接口备注

1. **路由注册顺序约定**（Shelf 按注册顺序匹配，固定路径须在参数路由前注册）：
   - `GET /api/invoices/export` 须在 `GET /api/invoices/:id` **之前**注册
   - `POST /api/kpi/scores/generate`、`POST /api/kpi/scores/recalculate` 须在 `GET /api/kpi/scores/:id` 和 `POST /api/kpi/scores/:id/freeze` **之前**注册
   - `POST /api/sublease-portal/subleases/import` 须在 `POST /api/sublease-portal/subleases/:id/submit` **之前**注册
   - 本文档各路由表中的排列顺序即推荐的 Shelf 注册顺序
2. `GET /api/audit-logs` 支持分页（`page` + `pageSize`，默认 50，最大 200）。
3. `POST /api/files` 返回 `{ data: { storage_path, file_size_kb, content_type } }`，客户端持 `storage_path` 填入各业务接口字段。

---

## 九、建议优先冻结的 DTO

> 以下 DTO 已在 [API_CONTRACT_v1.7.md](API_CONTRACT_v1.7.md) 中完成字段级定义（含类型、必填/可选、校验规则），本节仅保留索引清单。

1. LoginResponse
2. Building / Floor / UnitSummary / UnitDetail（含 `market_rent_reference`、`predecessor_unit_ids`）
3. ContractDetail / ContractCreateRequest（含 `contract_units[]`、`tax_inclusive`、`applicable_tax_rate`）/ EscalationPhaseDto / ContractAttachmentListItem
4. TerminateContractRequest（含 `termination_type`、`penalty_amount`、`deposit_deduction_details`）
5. DepositDetail / DepositTransactionDto
6. InvoiceDetail / PaymentCreateRequest / PaymentAllocationDto
7. MeterReadingCreateRequest / MeterReadingDetail
8. TurnoverReportCreateRequest / TurnoverReportDetail
9. WorkOrderDetail / WorkOrderRejectRequest（`rejected_reason`）
10. SubleasePortalUnit / SubleaseDetail / SubleaseReviewRequest
11. ImportBatchDetail / ImportErrorReport
12. DepartmentTree / ManagedScopeConfig
13. KpiRankingResponse / KpiTrendResponse / KpiAppealCreateRequest / KpiAppealReviewRequest
14. EscalationTemplateDto / ApplyTemplateRequest
15. FloorPlanVersionDto
16. RentForecastRow / RentForecastExportRequest
17. WaleTrendPoint / WaleWaterfallItem
18. NoiBudgetCreateRequest / NoiVacancyLossItem
19. KpiMetricDefinitionDto / ManualKpiInputRequest
20. KpiSchemeDetail / KpiSchemeMetricConfig / KpiSchemeTargetConfig
21. KpiScoreSnapshotDetail（含 `items[]`，`snapshot_status: 'draft'|'frozen'|'recalculated'`，`frozen_at`）
22. InvoiceVoidRequest / InvoiceExportQuery
23. AlertUnreadResponse
24. AuditLogEntry
25. UnmaskRequest（`current_password`）/ UnmaskResponse（`id_number`、`contact_phone`）

---

## 十、v1.7 → v1.2 补充变更摘要

| 变更项 | 新增端点 |
|--------|----------|
| 用户列表/详情/更新 + 改密 | `GET /api/users`, `GET /api/users/:id`, `PATCH /api/users/:id`, `POST /api/auth/change-password` |
| 楼层图纸版本管理 | `GET /api/floors/:id/plans`, `PATCH /api/floor-plans/:id/set-current` |
| 改造记录详情/更新/照片 | `GET/PATCH /api/renovations/:id`, `POST /api/renovations/:id/photos` |
| 资产台账导出 + 概览看板 | `GET /api/units/export`, `GET /api/assets/overview` |
| 预警已读操作 | `GET /api/alerts/unread`, `PATCH /api/alerts/:id/read`, `POST /api/alerts/read-all` |
| 租金递增模板全套 CRUD | `GET/POST /api/escalation-templates`, `GET/PATCH/DELETE /api/escalation-templates/:id`, `POST /api/contracts/:id/apply-template` |
| 合同租金预测 + WALE 趋势/瀑布 | `GET /api/contracts/:id/rent-forecast`, `GET .../export`, `GET /api/contracts/wale/trend`, `GET .../waterfall` |
| 账单更新/作废/导出 | `PATCH /api/invoices/:id`, `POST /api/invoices/:id/void`, `GET /api/invoices/export` |
| 运营支出更新/删除 | `PATCH/DELETE /api/expenses/:id` |
| NOI 空置损失 + 预算 | `GET /api/noi/vacancy-loss`, `GET/POST /api/noi/budget` |
| KPI 指标管理 + 手动录入 | `GET /api/kpi/metrics`, `PATCH /api/kpi/metrics/:id`, `POST /api/kpi/metrics/:id/manual-input` |
| KPI 方案详情/更新/删除 | `GET/PATCH/DELETE /api/kpi/schemes/:id` |
| KPI 方案指标/绑定对象管理 | `GET/PUT /api/kpi/schemes/:id/metrics`, `GET/PUT /api/kpi/schemes/:id/targets` |
| KPI 快照详情 + 生成触发 | `GET /api/kpi/scores/:id`, `POST /api/kpi/scores/generate` |
| 供应商详情/更新 | `GET/PATCH /api/suppliers/:id` |
| 二房东门户单记录/草稿提交/删除 | `GET /api/sublease-portal/subleases/:id`, `POST .../submit`, `DELETE .../` |
| 子租赁导出 | `GET /api/subleases/export` |
| 通用文件上传 + 审计日志 | `POST /api/files`, `GET /api/audit-logs` |
| KPI 快照冻结 | `POST /api/kpi/scores/:id/freeze` |
| 合同附件列表 | `GET /api/contracts/:id/attachments` |
| 工单拒绝 | `PATCH /api/workorders/:id/reject` |
| 敏感字段脱敏/还原 | `POST /api/tenants/:id/unmask`, `POST /api/subleases/:id/unmask` |
| 合同 PATCH 字段白名单 | 备注第 5 条明确可变更字段集合，`contract_units` 不可通过 PATCH 变更 |
| 路由注册顺序修正 | `invoices/export`、`kpi/scores/generate|recalculate`、`sublease-portal/import` 调至参数路由前 |

### v1.4 对齐 data_model v1.3（2026-04-08）

内容已完整覆盖 data_model v1.3 所有新增端点（`floor_plans` 版本管理、`escalation_templates` 模板 CRUD、`sublease_review_status.draft` 草稿暂存、`alerts.target_user_id` 定向推送等），本次仅更新依据文档版本引用。

---

## 十一、v1.7 对齐变更摘要（原版保留）

| 变更项 | 影响端点 |
|--------|---------|
| 合同-单元 M:N 关联 | `POST /api/contracts`（`contract_units[]`），`GET /api/contracts/:id` |
| 合同提前终止 | 新增 `POST /api/contracts/:id/terminate` |
| 含税/不含税标识 + 税率 | `POST/PATCH /api/contracts`，`GET /api/noi/*` |
| 押金独立管理 | 新增 §三-A 全部端点 |
| 水电抄表 | 新增 §四-A 全部端点 |
| 营业额申报 | 新增 §四-B 全部端点 |
| 导入批次管理 | 新增 §七 全部端点 |
| WALE 双口径 | `GET /api/contracts/wale` 响应增加 `wale_area_weighted` |
| KPI 指标方向 | `POST /api/kpi/schemes` 请求体增加 `direction` |
| KPI 升级为正式考核 | KPI 接口从“试运行”改为“考核”，`scoring_mode` 默认 `'official'` |
| KPI 排名/趋势/导出 | 新增 `GET /api/kpi/rankings`、`GET /api/kpi/trends`、`GET /api/kpi/export` |
| KPI 申诉 | 新增 `POST /api/kpi/appeals`、`GET /api/kpi/appeals`、`PATCH /api/kpi/appeals/:id/review` |
| 组织架构管理 | 新增 §一-A 全部端点（部门与管辖范围） |
| 员工部门变更 | 新增 `PATCH /api/users/:id/department` |
| 租户信用评级 | `GET /api/tenants/:id` 响应增加 `credit_rating` 及统计字段 |
| 密码复杂度 | 登录/改密接口增强校验 |
---

## 十二、v1.8 对齐变更摘要（PRD v1.8）

| 变更项 | 影响端点 |
|--------|----------|
| NOI Margin/OpEx Ratio 聚合 | `GET /api/noi/summary` 响应新增 `noi_margin`、`opex_ratio` 字段 |
| NOI 年度预算管理 | `GET/POST /api/noi/budget`（已存在）：`POST` 请求体新增 `period_month`（NULL=年度预算）支持 |
| 工单完工费用性质 | `PATCH /api/workorders/:id/complete` 请求体新增 `cost_nature`（`"opex"` / `"capex"`，NULLABLE，仅 repair 类型适用） |
| 运营支出类目扩展 | `POST /api/expenses` 请求体 `category` 新增 `"professional_service"` 枚举字字段展示 || HTTPS 强制 | 二房东门户强制 TLS 1.2+ |
