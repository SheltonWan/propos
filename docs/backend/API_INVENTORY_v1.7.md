# PropOS 后端 API 清单草案 v1.7

> 版本: v1.1
> 日期: 2026-04-06
> 范围: Phase 1 Must + 部分 Should
> 依据: PRD v1.7 / ARCH v1.2 / data_model v1.2
> 说明: 所有接口统一使用响应信封。成功为 `{ data, meta? }`，失败为 `{ error: { code, message } }`。分页参数统一为 `page` 和 `pageSize`，默认 20，最大 100。

---

## 一、认证与用户

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/auth/login | 登录并获取 access token | 公共 |
| POST | /api/auth/refresh | 刷新 token | 已登录 |
| POST | /api/auth/logout | 注销当前会话 | 已登录 |
| GET | /api/auth/me | 获取当前用户与权限 | 已登录 |
| POST | /api/users | 创建后台账号或二房东账号 | super_admin |
| PATCH | /api/users/:id/status | 启停用账号 | super_admin |
| PATCH | /api/users/:id/role | 变更角色 | super_admin |

### 认证接口备注

1. 登录失败达到阈值后返回 `ACCOUNT_LOCKED`。
2. 二房东账号首次登录需触发强制改密流程。
3. 主合同冻结或改密后，旧 token 应因 `session_version` 失效。
4. 密码复杂度：最少 8 位，必须含大小写字母 + 数字，禁止与用户名相同（v1.7）。

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
| GET | /api/units | 单元分页列表 | assets.read |
| POST | /api/units | 创建单元 | assets.write |
| GET | /api/units/:id | 单元详情（含 `market_rent_reference`、`predecessor_unit_ids`、`archived_at`） | assets.read |
| PATCH | /api/units/:id | 更新单元 | assets.write |
| POST | /api/units/import | 批量导入单元 | assets.write |
| GET | /api/renovations | 改造记录列表 | assets.read |
| POST | /api/renovations | 新增改造记录 | assets.write |

### 资产接口备注（v1.7 新增）

1. `PATCH /api/units/:id` 更改为归档时需设置 `archived_at`，旧单元不物理删除。
2. 单元拆分/合并时 `predecessor_unit_ids` 记录前序单元 ID 列表，保持历史合同关联不脱钩。

---

## 三、租务与合同

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/tenants | 租客列表（含 `credit_rating` 字段） | contracts.read |
| POST | /api/tenants | 创建租客 | contracts.write |
| GET | /api/tenants/:id | 租客详情（含信用评级与逾期统计） | contracts.read |
| PATCH | /api/tenants/:id | 更新租客 | contracts.write |
| GET | /api/contracts | 合同分页列表 | contracts.read |
| POST | /api/contracts | 创建合同（支持多单元通过 `contract_units` 绑定） | contracts.write |
| GET | /api/contracts/:id | 合同详情（含 `tax_inclusive`、`applicable_tax_rate`、终止信息） | contracts.read |
| PATCH | /api/contracts/:id | 更新合同 | contracts.write |
| POST | /api/contracts/:id/attachments | 上传合同附件 | contracts.write |
| POST | /api/contracts/:id/renew | 创建续签合同 | contracts.write |
| POST | /api/contracts/:id/terminate | 执行合同提前终止（v1.7 新增） | contracts.write |
| GET | /api/contracts/:id/escalation-phases | 查询递增阶段 | contracts.read |
| PUT | /api/contracts/:id/escalation-phases | 覆盖递增阶段配置 | contracts.write |
| GET | /api/contracts/wale | 查询 WALE 双口径（收入加权 + 面积加权），支持 `groupBy` | contracts.read |
| GET | /api/alerts | 预警列表 | alerts.read |
| POST | /api/alerts/replay | 按条件补发预警 | alerts.write |

### 合同接口备注（v1.7 变更）

1. `POST /api/contracts` 请求体新增 `contract_units[]`（每项含 `unit_id`、`billing_area`、`unit_price`），替代原 `unit_id` 单值字段。
2. `POST /api/contracts/:id/terminate` 请求体需包含 `termination_type`（`tenant_early | negotiated | owner_termination`）、`termination_date`、`penalty_amount`、`deposit_deduction_details`、`termination_reason`。终止后自动取消未生成账单、关闭递增规则、触发押金流程。
3. WALE 接口返回 `wale_income_weighted` 和 `wale_area_weighted` 双口径；已终止合同（`termination_type IS NOT NULL`）剩余租期归零不参与计算。
4. 租客信用评级（`credit_rating`）每月 1 日自动重算：A（逾期≤1次且≤3天）/ B（2~3次或4~15天）/ C（≥4次或>15天）。

---

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
2. 状态流转：`collected → frozen → partially_deducted → refunded`，每次变更记录到 `deposit_transactions`。
3. 押金退还触发前，系统需校验合同无未结账单。
4. 每次状态变更均写入审计日志。

---

## 四、财务与 NOI

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/invoices | 账单分页列表 | finance.read |
| POST | /api/invoices/generate | 手工触发账单生成 | finance.write |
| GET | /api/invoices/:id | 账单详情 | finance.read |
| GET | /api/invoices/:id/items | 账单费项明细 | finance.read |
| POST | /api/payments | 新增收款主记录并分配核销 | finance.write |
| GET | /api/payments | 收款记录列表 | finance.read |
| GET | /api/payments/:id | 收款与分配详情 | finance.read |
| PATCH | /api/payments/:id/allocations | 调整核销分配 | finance.write |
| GET | /api/expenses | 运营支出列表 | finance.read |
| POST | /api/expenses | 新增运营支出 | finance.write |
| GET | /api/noi/summary | NOI 汇总卡片（不含税口径） | finance.read |
| GET | /api/noi/trend | NOI 趋势 | finance.read |
| GET | /api/noi/breakdown | 按楼栋或业态拆分 NOI | finance.read |
| GET | /api/kpi/schemes | KPI 试运行方案列表 | kpi.view |
| POST | /api/kpi/schemes | 创建 KPI 试运行方案 | kpi.manage |
| GET | /api/kpi/scores | KPI 快照列表 | kpi.view |
| POST | /api/kpi/scores/recalculate | 手工重算 KPI 快照 | kpi.manage |

### 财务接口备注

1. `POST /api/payments` 需要支持一笔收款分配到多张账单。
2. `PATCH /api/payments/:id/allocations` 仅允许在未结账或未锁账期间调整。
3. NOI 默认返回不含税经营口径（v1.7 明确），需通过查询参数区分 `receivable` 和 `received` 视角。
4. KPI 方案中指标新增 `direction` 字段（`positive` / `negative`），反向指标线性插值逻辑翻转（v1.7）。

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
| GET | /api/workorders | 工单分页列表 | workorders.read |
| POST | /api/workorders | 创建工单 | workorders.write |
| GET | /api/workorders/:id | 工单详情 | workorders.read |
| PATCH | /api/workorders/:id/approve | 审核/派单 | workorders.write |
| PATCH | /api/workorders/:id/start | 开始处理 | workorders.write |
| PATCH | /api/workorders/:id/hold | 挂起工单 | workorders.write |
| PATCH | /api/workorders/:id/complete | 完工并录入成本 | workorders.write |
| PATCH | /api/workorders/:id/inspect | 验收工单 | workorders.write |
| PATCH | /api/workorders/:id/reopen | 重开工单 | workorders.write |
| POST | /api/workorders/:id/photos | 上传工单照片 | workorders.write |
| GET | /api/suppliers | 供应商列表 | workorders.read |
| POST | /api/suppliers | 新增供应商 | workorders.write |

---

## 六、二房东穿透模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/sublease-portal/login | 二房东门户登录 | 公共 |
| GET | /api/sublease-portal/units | 获取当前二房东可填报单元列表 | sublease.portal |
| GET | /api/sublease-portal/subleases | 获取当前二房东已提交记录 | sublease.portal |
| POST | /api/sublease-portal/subleases | 新增子租赁填报 | sublease.portal |
| PATCH | /api/sublease-portal/subleases/:id | 修改待审核或退回记录 | sublease.portal |
| POST | /api/sublease-portal/subleases/import | 批量导入子租赁 | sublease.portal |
| GET | /api/subleases | 内部子租赁分页列表 | sublease.read |
| GET | /api/subleases/:id | 子租赁详情 | sublease.read |
| PATCH | /api/subleases/:id/approve | 审核通过 | sublease.write |
| PATCH | /api/subleases/:id/reject | 退回并填写原因 | sublease.write |
| GET | /api/subleases/dashboard | 穿透基础看板 | sublease.read |

### 二房东接口备注

1. 门户类接口除 RBAC 外，必须在 Repository 层追加主合同范围过滤。
2. 仅 `approved` 记录参与穿透看板和统计口径。
3. 查看完整证件号或手机号必须触发二次授权，不应在默认详情接口直接返回。
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
| GET | /api/health | 健康检查 | 公共 |

---

## 九、建议优先冻结的 DTO

1. LoginResponse
2. Building / Floor / UnitSummary / UnitDetail（含 `market_rent_reference`、`predecessor_unit_ids`）
3. ContractDetail / ContractCreateRequest（含 `contract_units[]`、`tax_inclusive`、`applicable_tax_rate`）/ EscalationPhaseDto
4. TerminateContractRequest（含 `termination_type`、`penalty_amount`、`deposit_deduction_details`）
5. DepositDetail / DepositTransactionDto
6. InvoiceDetail / PaymentCreateRequest / PaymentAllocationDto
7. MeterReadingCreateRequest / MeterReadingDetail
8. TurnoverReportCreateRequest / TurnoverReportDetail
9. WorkOrderDetail
10. SubleasePortalUnit / SubleaseDetail / SubleaseReviewRequest
11. ImportBatchDetail / ImportErrorReport

---

## 十、v1.7 对齐变更摘要

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
| 租户信用评级 | `GET /api/tenants/:id` 响应增加 `credit_rating` 及统计字段 |
| 密码复杂度 | 登录/改密接口增强校验 |
| HTTPS 强制 | 二房东门户强制 TLS 1.2+ |
