# PropOS 数据库迁移草案 v1.7

> 版本: v1.3
> 日期: 2026-04-13
> 范围: Phase 1 Must + 必要基础设施
> 依据: PRD v1.8 / ARCH v1.4 / data_model v1.5
> 目标: 将数据模型文档转成迁移实施顺序，作为后续 SQL migration 编写基线。

---

## 一、迁移原则

1. 先建 ENUM 与基础表，再建业务表，最后补循环依赖外键。
2. 所有迁移文件必须可重复执行或通过版本表保证只执行一次。
3. 涉及敏感字段的列命名必须显式标注加密用途，避免后续误用。
4. 索引以 Phase 1 查询场景优先，不提前为 Could 场景过度设计。

---

## 二、迁移序列

> **注意**：所有历史增量变更（v1.5/v1.7/v1.8）已直接合入对应建表文件，无需单独增量迁移文件。

| 顺序 | 文件名 | 主要内容 | 关键依赖 |
|------|--------|---------|---------|
| 001 | 001_create_enums.sql | 全部 ENUM 类型（property_type / unit_status / unit_decoration / user_role / tenant_type / contract_status / pricing_model / escalation_type / alert_type / invoice_status / invoice_item_type / expense_category / cost_nature / work_order_type / work_order_status / work_order_priority / sublease_occupancy_status / sublease_review_status / kpi_period_type / kpi_scheme_status / kpi_metric_category / deposit_status / termination_type / meter_type / reading_cycle / turnover_approval_status / import_data_type / import_rollback_status / credit_rating / notification_type / notification_severity / dunning_method / approval_type / approval_status / renewal_intent） | 无 |
| 002 | 002_create_departments.sql | departments（三级组织树，仅有自引用 FK） | 001 |
| 003 | 003_create_users_and_audit.sql | users（department_id 列暂无 FK 约束）、audit_logs、job_execution_logs、refresh_tokens | 001、002 |
| 004 | 004_create_assets.sql | buildings、floors、floor_plans、units、renovation_records | 001、003 |
| 005 | 005_create_user_managed_scopes.sql | user_managed_scopes（部门默认 + 个人覆盖双机制） | 002、003、004 |
| 006 | 006_create_contracts.sql | tenants（含信用评级 4 列、data_retention_until）、contracts（含 tax_inclusive / applicable_tax_rate / termination 字段）、contract_units（M:N 中间表）、contract_attachments、rent_escalation_phases、escalation_templates、alerts（含 target_roles） | 001、003、004 |
| 007 | 007_create_finance.sql | invoices、invoice_items、payments、payment_allocations、expenses（work_order_id 列暂无 FK 约束） | 001、003、004、006 |
| 008 | 008_create_workorders.sql | suppliers、work_orders（含 work_order_type / cost_nature / contract_id）、work_order_photos | 001、003、004、006 |
| 009 | 009_create_deposits.sql | deposits、deposit_transactions | 001、003、006 |
| 010 | 010_create_meter_readings.sql | meter_readings（含阶梯计价 tiered_details JSONB） | 001、003、004、007 |
| 011 | 011_create_turnover_reports.sql | turnover_reports（UNIQUE: contract_id + report_month WHERE is_amendment = FALSE） | 001、003、006、007 |
| 012 | 012_create_subleases.sql | subleases（含 review_status / version_no / submission_channel / truth_declared_at） | 001、003、004、006 |
| 013 | 013_create_kpi.sql | kpi_metric_definitions（含 direction / category）、kpi_schemes（status 默认 draft，scoring_mode 默认 official）、kpi_scheme_metrics、kpi_score_snapshots、kpi_score_snapshot_items | 001、002、003 |
| 014 | 014_create_kpi_targets_and_appeals.sql | kpi_scheme_targets（方案绑定部门/员工）、kpi_appeals（KPI 申诉） | 002、003、013 |
| 015 | 015_create_import_batches.sql | import_batches（含 is_dry_run / rollback_status / error_details JSONB） | 001、003 |
| 016 | 016_create_noi_budgets.sql | noi_budgets（按楼栋/业态录入年度 NOI 预算） | 001、003、004 |
| 017 | 017_create_notifications.sql | notifications（站内通知）、dunning_logs（催收记录） | 001、003、007 |
| 018 | 018_add_deferred_foreign_keys.sql | users.department_id → departments、users.bound_contract_id → contracts、expenses.work_order_id → work_orders、work_orders.follow_up_work_order_id → work_orders（自引用延迟 FK） | 002、003、006、007、008 |
| 019 | 019_seed_reference_data.sql | 超级管理员账号、初始三个部门（租务部/财务部/物业运营部）、KPI 指标库 K01-K14（含 direction / category） | 001-018 |

---

## 三、关键迁移内容

### 1. ENUM 类型（v1.7 新增 8 个）

v1.6 已有：`property_type`、`contract_status`、`invoice_status`、`work_order_status`、`review_status`

v1.7 新增：

| ENUM | 值 |
|------|----|
| `work_order_type` | `repair`, `complaint`, `inspection` |
| `deposit_status` | `collected`, `frozen`, `partially_credited`, `refunded` |
| `termination_type` | `normal_expiry`, `tenant_early_exit`, `mutual_agreement`, `owner_termination` |
| `meter_type` | `water`, `electricity`, `gas` |
| `reading_cycle` | `monthly`, `bimonthly` |
| `turnover_approval_status` | `pending`, `approved`, `rejected` |
| `import_data_type` | `unit`, `contract`, `sublease`, `invoice` |
| `import_rollback_status` | `none`, `rolling_back`, `rolled_back`, `rollback_failed` |
| `credit_rating` | `A`, `B`, `C`, `D` |

v1.5 新增：

| ENUM | 值 |
|------|----|
| `pricing_model` | `area`, `flat`, `revenue` |
| `kpi_scheme_status` | `draft`, `active`, `archived` |
| `kpi_metric_category` | `leasing`, `finance`, `service`, `growth` |

v1.8 新增（通知/审批/催收）：

| ENUM | 值 |
|------|----|
| `notification_type` | `contract_expiring`, `invoice_overdue`, `workorder_assigned`, `workorder_completed`, `approval_pending`, `system_alert`, `kpi_published` |
| `notification_severity` | `info`, `warning`, `critical` |
| `dunning_method` | `phone`, `sms`, `letter`, `visit`, `legal` |
| `approval_type` | `contract_termination`, `deposit_refund`, `invoice_adjustment`, `sublease_submission` |
| `approval_status` | `pending`, `approved`, `rejected` |
| `renewal_intent` | `willing`, `undecided`, `unwilling` |

### 2. users 与审计基础设施

必须包含以下字段：

1. `failed_login_attempts`
2. `locked_until`
3. `department_id`（UUID FK → departments，延迟建约，员工归属部门）
3. `password_changed_at`
4. `last_login_at`
5. `session_version`
6. `frozen_at` / `frozen_reason`

审计基础设施需同时创建：

1. `audit_logs`
2. `job_execution_logs`

### 3. 资产表（v1.7 增强）

资产迁移需要注意：

1. `units` 需要支持三业态扩展字段。
2. `units` 新增 `market_rent_reference NUMERIC(12,2)` — 参考市场租金，用于 PGI/空置损失测算。
3. `units` 新增 `predecessor_unit_ids UUID[]` — 前序单元 ID 数组，用于拆分/合并追溯。
4. `units` 新增 `archived_at TIMESTAMPTZ` — 归档时间戳，替代物理删除。
5. 图纸路径字段需预留给 SVG / PNG。
6. 热区坐标不建议直接进第一版 SQL 约束，避免 CAD 导入链路过早卡死。

### 4. 合同与递增规则（v1.7 重大变更）

合同迁移必须支持：

1. 续签链 `parent_contract_id`
2. 二房东主合同标识 `is_master_lease`
3. **M:N 单元关联**：新建 `contract_units` 中间表（`contract_id`、`unit_id`、`billing_area`、`unit_price`），`contracts` 表移除原 `unit_id` 列。
4. **含税标识与税率**：`tax_inclusive BOOLEAN NOT NULL DEFAULT true`、`applicable_tax_rate NUMERIC(5,4)`。
5. **合同终止字段**：`termination_type`（ENUM）、`termination_date DATE`、`penalty_amount NUMERIC(14,2)`、`deposit_deduction_details JSONB`、`termination_reason TEXT`。
6. 递增阶段表 `rent_escalation_phases`
7. 预警记录表 `alerts`

租客表新增信用评级：

1. `credit_rating`（ENUM，默认 `B`）
2. `last_rating_date DATE`
3. `times_overdue_past_12m INT DEFAULT 0`
4. `max_single_overdue_days INT DEFAULT 0`

### 5. 押金管理（v1.7 新增）

**`deposits`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `contract_id` | UUID FK → contracts | |
| `amount` | NUMERIC(14,2) | 押金金额 |
| `status` | deposit_status | `collected` / `frozen` / `partially_credited` / `refunded` |
| `collected_at` | TIMESTAMPTZ | 收取时间 |
| `refunded_at` | TIMESTAMPTZ | 退还时间（nullable） |

**`deposit_transactions`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `deposit_id` | UUID FK → deposits | |
| `action` | TEXT | `collect` / `freeze` / `deduct` / `refund` / `transfer` |
| `amount` | NUMERIC(14,2) | 操作金额 |
| `reason` | TEXT | 操作原因 |
| `operator_id` | UUID FK → users | |
| `created_at` | TIMESTAMPTZ | |

### 6. 水电抄表（v1.7 新增）

**`meter_readings`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `unit_id` | UUID FK → units | |
| `meter_type` | meter_type ENUM | `water` / `electricity` / `gas` |
| `reading_cycle` | reading_cycle ENUM | `monthly` / `bimonthly` |
| `previous_reading` | NUMERIC(12,2) | 上期读数 |
| `current_reading` | NUMERIC(12,2) | 本期读数 |
| `usage` | NUMERIC(12,2) | 用量 = current - previous |
| `unit_price` | NUMERIC(10,4) | 单价 |
| `tier1_limit` / `tier1_price` / `tier2_price` | NUMERIC | 阶梯计价参数 |
| `total_amount` | NUMERIC(14,2) | 费用合计 |
| `invoice_id` | UUID FK → invoices | 自动生成的账单 |
| `recorded_by` | UUID FK → users | 抄表人 |
| `reading_date` | DATE | |

CHECK: `current_reading > previous_reading`

索引：`(unit_id, meter_type, reading_date)`

### 13. 通知系统（v1.8 新增）

**`notifications`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `user_id` | UUID FK → users | 接收人 |
| `type` | notification_type ENUM | 通知类型 |
| `severity` | notification_severity ENUM | 严重级别 |
| `title` | VARCHAR(200) | 通知标题 |
| `content` | TEXT | 通知正文 |
| `is_read` | BOOLEAN DEFAULT false | 是否已读 |
| `resource_type` | VARCHAR(50) | 关联资源类型（nullable） |
| `resource_id` | UUID | 关联资源 ID（nullable） |
| `created_at` | TIMESTAMPTZ | 创建时间 |

索引：`(user_id, is_read)` — 未读查询、`(user_id, created_at DESC)` — 时间排序、`(type)` — 按类型统计

### 14. 催收记录（v1.8 新增）

**`dunning_logs`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `invoice_id` | UUID FK → invoices | 关联账单 |
| `method` | dunning_method ENUM | 催收方式 |
| `content` | TEXT | 催收内容摘要 |
| `result` | TEXT | 催收结果（nullable） |
| `dunning_date` | DATE | 催收日期 |
| `created_by` | UUID FK → users | 操作人 |
| `created_at` | TIMESTAMPTZ | 创建时间 |

索引：`(invoice_id)` — 按账单查催收、`(dunning_date)` — 按日期排序

### 7. 营业额申报（v1.7 新增）

**`turnover_reports`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `contract_id` | UUID FK → contracts | |
| `report_month` | DATE | 申报月份 |
| `reported_revenue` | NUMERIC(16,2) | 申报营业额 |
| `share_rate` | NUMERIC(5,4) | 分成比例 |
| `base_rent` | NUMERIC(14,2) | 保底租金 |
| `calculated_share` | NUMERIC(14,2) | 计算分成 |
| `approval_status` | turnover_approval_status | `pending` / `approved` / `rejected` |
| `reviewed_by` | UUID FK → users | 审核人 |
| `reviewed_at` | TIMESTAMPTZ | |
| `reject_reason` | TEXT | 退回原因 |
| `invoice_id` | UUID FK → invoices | 审核通过后生成的分成账单 |

索引：`(contract_id, report_month)` UNIQUE

### 8. 财务核销模型

与 v1.6 一致：

1. `payments` 作为到账主记录
2. `payment_allocations` 作为核销分配明细
3. `invoices` 增加 `paid_amount` 和 `outstanding_amount`

### 9. 工单与支出联动

需要延迟建立的关键关系（单向引用，避免循环 FK）：

1. `expenses.work_order_id`

> `work_orders.expense_id` 列已移除：成本关联通过 `expenses.work_order_id` 反向查询即可，无需在工单表保留冗余外键。

> `work_orders` 表新增 `work_order_type`（ENUM `work_order_type`）列、`contract_id`（FK → contracts）列、`deposit_deduction_suggestion`（NUMERIC）列、`follow_up_work_order_id`（UUID）列。新增索引 `idx_workorders_type` 和 `idx_workorders_contract`。

### 10. 二房东穿透

`subleases` 迁移必须支持以下字段：

1. `review_status`
2. `version_no`
3. `declared_for_month`
4. `submission_channel`
5. `truth_declared_at`
6. `submitted_at`

索引：`master_contract_id`、`unit_id`、`review_status`、`occupancy_status`

### 11. KPI 指标库（v1.7 增强）

`kpi_metric_definitions` 表新增：

| 列 | 类型 | 说明 |
|----|------|------|
| `direction` | VARCHAR(10) | `positive`（正向：越高越好）或 `negative`（反向：越低越好） |

CHECK: `direction IN ('positive', 'negative')`

种子数据 K03、K05、K06、K08 设为 `negative`，其余为 `positive`。

### 12. 导入批次跟踪（v1.7 新增）

**`import_batches`** 表：

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | UUID PK | |
| `data_type` | import_data_type | `unit` / `contract` / `sublease` / `invoice` |
| `file_name` | VARCHAR(500) | 原始文件名 |
| `total_rows` | INT | 总行数 |
| `success_rows` | INT | 成功行数 |
| `failed_rows` | INT | 失败行数 |
| `error_details` | JSONB | 错误明细 |
| `dry_run` | BOOLEAN DEFAULT false | 是否为试导入 |
| `rollback_status` | import_rollback_status | `none` / `rolling_back` / `rolled_back` / `rollback_failed` |
| `rolled_back_at` | TIMESTAMPTZ | |
| `rolled_back_by` | UUID FK → users | |
| `uploaded_by` | UUID FK → users | |
| `created_at` | TIMESTAMPTZ | |

---

## 四、初始化与种子数据

| 类别 | 内容 |
|------|------|
| 账号 | 初始化一个 super_admin |
| 部门 | 初始化三个部门：租务部、财务部、物业运营部 |
| KPI 指标库 | 写入 K01 ~ K10（含 `direction` 字段） |
| ENUM | 全部 v1.7 枚举类型 |
| 业务常量 | 预警阈值、逾期节点等可放配置表或应用常量 |
| 样本数据 | 不写入正式迁移，单独维护测试或验收 seed |

---

## 五、回滚策略

1. DDL 回滚以 migration 反向脚本为准，不在生产直接手工删表。
2. 种子数据回滚需要显式按 code 或 email 精确删除。
3. 导入样本数据与正式迁移分离，避免污染生产基线。
4. v1.7 新增 `import_batches` 支持按批次精确回滚业务数据（非 DDL）。

---

## 六、迁移验收检查项

| 检查项 | 验证方式 |
|--------|---------|
| ENUM 完整（含 v1.7 新增 9 个） | `\dT+` 或 schema diff |
| contract_units M:N 关联正确 | 插入 contract + 2 个 contract_units 验证 JOIN |
| 押金状态流转正确 | 插入 deposit + transactions 验证状态流 |
| 水电抄表 CHECK 约束 | 尝试插入 current_reading < previous_reading，期望 CHECK violation |
| 营业额申报唯一约束 | 同合同同月份二次插入，期望 UNIQUE violation |
| 延迟 FK 生效 | 执行建表后检查约束存在 |
| 核销双表完整 | 插入 payment + allocations 验证账单回写逻辑 |
| 二房东安全字段完整 | 检查 users / subleases 列结构 |
| KPI direction 字段 | 查询 K03/K05/K06/K08 确认 direction = 'negative' |
| 组织架构表 | 插入 3 级部门验证 parent_id 层级约束，level CHECK(1~3) |
| 管辖范围表 | 插入部门默认范围 + 个人覆盖范围，验证 CHECK 约束 |
| KPI 方案绑定 | 插入 kpi_scheme_targets 验证部门/员工绑定 |
| KPI 申诉表 | 插入 kpi_appeals 验证状态流转 + 审计日志 |
| 导入批次表 | 插入 import_batch 验证 dry_run 与 rollback_status 字段 |
| 通知表 | 插入 notification 验证未读索引与 type/severity 枚举 |
| 催收记录表 | 插入 dunning_log 验证 invoice_id FK 与 method 枚举 |
| 通知/催收 ENUM 完整（6 个） | `\dT+` 确认 notification_type、notification_severity、dunning_method、approval_type、approval_status、renewal_intent |
| 索引齐全 | `pg_indexes` 查询 |

---

## 七、建议后续动作

1. 先按本草案创建空 migration 文件骨架（001 ~ 017）。
2. 再优先实现 001 ~ 005，先打通用户、资产、合同、财务主链路。
3. 然后实现 007 ~ 009（押金、抄表、营业额），与合同/财务联调。
4. 实现 015 ~ 016（组织架构 + 管辖范围），为 KPI 正式考核做就绪。
5. 最后补工单、穿透、KPI（011 + 017）、导入批次和 deferred FK。

---

## 八、v1.7 对齐变更摘要

| 变更项 | 影响迁移文件 |
|--------|------------|
| 新增 9 个 ENUM 类型（含 `work_order_type`） | 001 |
| units 新增 3 列（market_rent_reference, predecessor_unit_ids, archived_at）| 003 |
| tenants 新增信用评级 4 列 | 004 |
| contracts 新增含税/终止字段 6 列 | 004 |
| 新增 contract_units 中间表 | 004 |
| 新增 deposits + deposit_transactions 表 | 007（新） |
| 新增 meter_readings 表 | 008（新） |
| 新增 turnover_reports 表 | 009（新） |
| kpi_metric_definitions 新增 direction 列 | 011 |
| kpi_schemes scoring_mode 默认改为 'official' | 011 |
| 新增 import_batches 表 | 012（新） |
| 新增 departments 三级组织树表 | 015（新） |
| 新增 user_managed_scopes 管辖范围表 | 016（新） |
| users 新增 department_id 列 | 013（延迟 FK） |
| 新增 kpi_scheme_targets 方案绑定表 | 017（新） |
| 新增 kpi_appeals 申诉表 | 017（新） |
| 迁移序列从 14 扩展到 17 步 | 全局 |

### v1.5 对齐 API_CONTRACT v1.8（通知/审批/催收）

| 变更项 | 影响迁移文件 |
|---------|------------|
| 新增 6 个 ENUM 类型（notification_type、notification_severity、dunning_method、approval_type、approval_status、renewal_intent） | 020（新） |
| 新增 `notifications` 表（通知系统） | 020（新） |
| 新增 `dunning_logs` 表（催收记录） | 020（新） |
| 迁移序列从 19 扩展到 20 步 | 全局 |

### v1.2 对齐 data_model v1.3（2026-04-08）

内容已完整覆盖 data_model v1.3 所有新增表和字段（`floor_plans`、`escalation_templates`、`alerts.target_user_id`、`data_retention_until`、`sublease_review_status.draft`、`contracts.status` 默认 `quoting`），本次仅更新依据文档版本引用。

### v1.3 对齐 PRD v1.8 / data_model v1.4（2026-04-13）

| 变更项 | 影响迁移文件 |
|---------|------------|
| `expense_category` ENUM 新增 `professional_service`（专业服务费） | 001 |
| 新增 `cost_nature` ENUM（`opex`/`capex`） | 001（新） |
| `work_orders` 表新增 `cost_nature cost_nature NULL` | 006 |
| 新增 `noi_budgets` 表（NOI 年度预算） | 018（新） |

### v1.4 对齐 data_model v1.5（2026-04-13）

> 正式迁移文件：`backend/migrations/20260413_v1.5_model_alignment.sql`

| 变更项 | 影响迁移文件 |
|---------|------------|
| `unit_status` ENUM 新增 `renovating` / `pre_lease` | 001（ALTER TYPE ADD VALUE） |
| `credit_rating` ENUM 新增 `D` 级 | 001（ALTER TYPE ADD VALUE） |
| 新增 `pricing_model` ENUM（area/flat/revenue） | 001（新 ENUM） |
| 新增 `kpi_scheme_status` ENUM（draft/active/archived） | 001（新 ENUM） |
| 新增 `kpi_metric_category` ENUM（leasing/finance/service/growth） | 001（新 ENUM） |
| `contracts` 表新增 `pricing_model` 列 | 004 |
| `kpi_metric_definitions` 表新增 `category` 列 | 011 |
| `kpi_schemes` 表 `is_active BOOLEAN` → `status kpi_scheme_status` | 011 |
| `alerts` 表新增 `target_roles user_role[]` 列 | 004 |
| KPI 指标种子 K11-K14 | 014 |
| 迁移序列追加 019_v1.5_model_alignment.sql | 全局 |

**注意**：`ALTER TYPE ... ADD VALUE` 在 PostgreSQL 中不能在事务块内执行，需在事务外独立运行。
