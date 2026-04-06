# PropOS 数据库迁移草案 v1.6

> 版本: v1.0
> 日期: 2026-04-06
> 范围: Phase 1 Must + 必要基础设施
> 目标: 将数据模型文档转成迁移实施顺序，作为后续 SQL migration 编写基线。

---

## 一、迁移原则

1. 先建 ENUM 与基础表，再建业务表，最后补循环依赖外键。
2. 所有迁移文件必须可重复执行或通过版本表保证只执行一次。
3. 涉及敏感字段的列命名必须显式标注加密用途，避免后续误用。
4. 索引以 Phase 1 查询场景优先，不提前为 Could 场景过度设计。

---

## 二、建议迁移序列

| 顺序 | 文件名建议 | 主要内容 |
|------|-----------|---------|
| 001 | 001_create_enums.sql | property_type、contract_status、invoice_status、work_order_status 等 ENUM |
| 002 | 002_create_users_and_audit.sql | users、audit_logs、job_execution_logs |
| 003 | 003_create_assets.sql | buildings、floors、units、renovation_records |
| 004 | 004_create_contracts.sql | tenants、contracts、contract_attachments、rent_escalation_phases、alerts |
| 005 | 005_create_finance.sql | invoices、invoice_items、payments、payment_allocations、expenses |
| 006 | 006_create_workorders.sql | suppliers、work_orders、work_order_photos |
| 007 | 007_create_subleases.sql | subleases |
| 008 | 008_create_kpi.sql | kpi_metric_definitions、kpi_schemes、kpi_scheme_metrics、kpi_score_snapshots、kpi_score_snapshot_items |
| 009 | 009_add_deferred_foreign_keys.sql | users.bound_contract_id、expenses.work_order_id、work_orders.expense_id |
| 010 | 010_seed_reference_data.sql | 超级管理员、KPI 指标库、基础字典数据 |

---

## 三、关键迁移内容

### 1. users 与审计基础设施

必须包含以下 v1.6 字段：

1. `failed_login_attempts`
2. `locked_until`
3. `password_changed_at`
4. `last_login_at`
5. `session_version`
6. `frozen_at` / `frozen_reason`

审计基础设施需同时创建：

1. `audit_logs`
2. `job_execution_logs`

---

### 2. 资产表

资产迁移需要注意：

1. `units` 需要支持三业态扩展字段。
2. 图纸路径字段需预留给 SVG / PNG。
3. 热区坐标不建议直接进第一版 SQL 约束，避免 CAD 导入链路过早卡死。

---

### 3. 合同与递增规则

合同迁移必须支持：

1. 续签链 `parent_contract_id`
2. 二房东主合同标识
3. 递增阶段表 `rent_escalation_phases`
4. 预警记录表 `alerts`

---

### 4. 财务核销模型

v1.6 不建议使用“payments 直连 invoices 的单表核销”。应采用：

1. `payments` 作为到账主记录
2. `payment_allocations` 作为核销分配明细
3. `invoices` 增加 `paid_amount` 和 `outstanding_amount`

这样才能覆盖：

1. 部分收款
2. 一次收多账单
3. 单账单多次核销
4. 调整分配关系后重算账单状态

---

### 5. 工单与支出联动

需要延迟建立的关键关系：

1. `expenses.work_order_id`
2. `work_orders.expense_id`

原因是工单与支出存在双向关联，必须在主表完成后再补 FK。

---

### 6. 二房东穿透

`subleases` 迁移必须支持以下字段：

1. `review_status`
2. `version_no`
3. `declared_for_month`
4. `submission_channel`
5. `truth_declared_at`
6. `submitted_at`

同时建议索引：

1. `master_contract_id`
2. `unit_id`
3. `review_status`
4. `occupancy_status`

---

## 四、初始化与种子数据

| 类别 | 内容 |
|------|------|
| 账号 | 初始化一个 super_admin |
| KPI 指标库 | 写入 K01 ~ K10 |
| 业务常量 | 预警阈值、逾期节点等可放配置表或应用常量 |
| 样本数据 | 不写入正式迁移，单独维护测试或验收 seed |

---

## 五、回滚策略

1. DDL 回滚以 migration 反向脚本为准，不在生产直接手工删表。
2. 种子数据回滚需要显式按 code 或 email 精确删除。
3. 导入样本数据与正式迁移分离，避免污染生产基线。

---

## 六、迁移验收检查项

| 检查项 | 验证方式 |
|--------|---------|
| ENUM 完整 | `\dT+` 或 schema diff |
| 延迟 FK 生效 | 执行建表后检查约束存在 |
| 核销双表完整 | 插入 payment + allocations 验证账单回写逻辑 |
| 二房东安全字段完整 | 检查 users / subleases 列结构 |
| 索引齐全 | `pg_indexes` 查询 |

---

## 七、建议后续动作

1. 先按本草案创建空 migration 文件骨架。
2. 再优先实现 001 ~ 005，先打通用户、资产、合同、财务主链路。
3. 最后补工单、穿透、KPI 和 deferred FK。
