-- =============================================================================
-- Migration: 028_fix_seed_uuids
-- Description: 修复 020/023 种子数据 UUID 格式
--   将非标准 UUID（0000-0000-0000-xxxxxxxx）更新为合规 v4 格式（4000-8000-xxxxxxxx）
--   受影响实体：users（超管）/ departments（4个）/ kpi_metric_definitions（K01-K14）
--
-- 背景：020/023 迁移首次应用时使用了旧格式 UUID，后续 commit ec968c7 在源文件中
--   修正了格式，但已应用的记录仍是旧值，需通过本迁移补齐。
--
-- 前置条件：本迁移仅适用于服务器尚未录入业务数据的初始化阶段。
--   若已有业务数据引用了旧 UUID，UPDATE 会因 FK 约束失败并自动回滚，需人工处理。
-- 依赖: 020, 023
-- =============================================================================

BEGIN;

-- =========================================================================
-- 1. 超级管理员 UUID 修复
--    旧: f0000000-0000-0000-0000-000000000001
--    新: f0000000-0000-4000-8000-000000000001
--
-- 策略：
--   NOT NULL FK 子表 → DELETE（init 阶段无业务数据，仅可能有测试登录残留）
--   可空  FK 子表 → SET NULL（解除引用，init 阶段数据归属丢失可接受）
--   然后再更新 users PK
-- =========================================================================

-- NOT NULL FK 子表：DELETE 清理
DELETE FROM refresh_tokens       WHERE user_id = 'f0000000-0000-0000-0000-000000000001';
DELETE FROM password_reset_otps  WHERE user_id = 'f0000000-0000-0000-0000-000000000001';
DELETE FROM notifications        WHERE user_id = 'f0000000-0000-0000-0000-000000000001';

-- 可空 FK 子表：SET NULL 解除引用（按表逐一处理，覆盖所有引用 users(id) 的可空列）
UPDATE audit_logs              SET user_id              = NULL WHERE user_id              = 'f0000000-0000-0000-0000-000000000001';
UPDATE user_managed_scopes     SET user_id              = NULL WHERE user_id              = 'f0000000-0000-0000-0000-000000000001';
UPDATE floor_plans             SET uploaded_by           = NULL WHERE uploaded_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE renovation_records      SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE contracts               SET responsible_user_id   = NULL WHERE responsible_user_id   = 'f0000000-0000-0000-0000-000000000001';
UPDATE contract_attachments    SET uploaded_by           = NULL WHERE uploaded_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE escalation_templates    SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE invoices                SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE invoices                SET voided_by             = NULL WHERE voided_by             = 'f0000000-0000-0000-0000-000000000001';
UPDATE payments                SET recorded_by           = NULL WHERE recorded_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE payment_allocations     SET allocated_by          = NULL WHERE allocated_by          = 'f0000000-0000-0000-0000-000000000001';
UPDATE expenses                SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE work_orders             SET assignee_user_id      = NULL WHERE assignee_user_id      = 'f0000000-0000-0000-0000-000000000001';
UPDATE work_order_photos       SET uploaded_by           = NULL WHERE uploaded_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE deposits                SET refund_approved_by    = NULL WHERE refund_approved_by    = 'f0000000-0000-0000-0000-000000000001';
UPDATE deposit_transactions    SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE meter_readings          SET recorded_by           = NULL WHERE recorded_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE turnover_reports        SET reviewed_by           = NULL WHERE reviewed_by           = 'f0000000-0000-0000-0000-000000000001';
UPDATE turnover_reports        SET submitted_by          = NULL WHERE submitted_by          = 'f0000000-0000-0000-0000-000000000001';
UPDATE subleases               SET reviewer_user_id      = NULL WHERE reviewer_user_id      = 'f0000000-0000-0000-0000-000000000001';
UPDATE subleases               SET submitted_by_user_id  = NULL WHERE submitted_by_user_id  = 'f0000000-0000-0000-0000-000000000001';
UPDATE kpi_schemes             SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE kpi_score_snapshots     SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE kpi_appeals             SET reviewer_id           = NULL WHERE reviewer_id           = 'f0000000-0000-0000-0000-000000000001';
UPDATE import_batches          SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE noi_budgets             SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';
UPDATE cad_import_jobs         SET created_by            = NULL WHERE created_by            = 'f0000000-0000-0000-0000-000000000001';

-- 所有引用均已解除，更新 users 主键
UPDATE users
    SET id = 'f0000000-0000-4000-8000-000000000001'
    WHERE id = 'f0000000-0000-0000-0000-000000000001';

-- =========================================================================
-- 2. 部门 UUID 修复（共 4 个：1 个公司根节点 + 3 个初始部门）
--
-- 注意外键顺序：三个部门的 parent_id 引用公司根节点（001），
-- 必须先断开引用 → 更新根节点 PK → 重建引用 → 再更新三个部门 PK。
-- =========================================================================

-- 2a. 用临时表保存 users.department_id 原始映射（旧 UUID → user_id）
--     更新部门 PK 后再按映射恢复，避免错认归属
CREATE TEMP TABLE _tmp_user_dept_map AS
    SELECT id AS user_id, department_id AS old_dept_id
    FROM users
    WHERE department_id IN (
        'de000000-0000-0000-0000-000000000001',
        'de000000-0000-0000-0000-000000000002',
        'de000000-0000-0000-0000-000000000003',
        'de000000-0000-0000-0000-000000000004'
    );

-- 解除所有 users 对四个旧部门 UUID 的引用
UPDATE users SET department_id = NULL
    WHERE department_id IN (
        'de000000-0000-0000-0000-000000000001',
        'de000000-0000-0000-0000-000000000002',
        'de000000-0000-0000-0000-000000000003',
        'de000000-0000-0000-0000-000000000004'
    );

-- 同步保存 departments.parent_id 自引用映射（旧 UUID → 子部门 id）
--     用户创建的子部门可能挂在 002/003/004 下面，更新 PK 前需断开，更新后再恢复
CREATE TEMP TABLE _tmp_dept_parent_map AS
    SELECT id AS dept_id, parent_id AS old_parent_id
    FROM departments
    WHERE parent_id IN (
        'de000000-0000-0000-0000-000000000001',
        'de000000-0000-0000-0000-000000000002',
        'de000000-0000-0000-0000-000000000003',
        'de000000-0000-0000-0000-000000000004'
    );

-- 解除所有 departments 自引用对四个旧部门 UUID 的指向
UPDATE departments SET parent_id = NULL
    WHERE parent_id IN (
        'de000000-0000-0000-0000-000000000001',
        'de000000-0000-0000-0000-000000000002',
        'de000000-0000-0000-0000-000000000003',
        'de000000-0000-0000-0000-000000000004'
    );

-- 2b. 公司根节点  de000000-0000-0000-0000-000000000001 → de000000-0000-4000-8000-000000000001
UPDATE departments
    SET id = 'de000000-0000-4000-8000-000000000001'
    WHERE id = 'de000000-0000-0000-0000-000000000001';

-- 2c. 三个子部门 PK 更新（自引用与 users 引用已统一解除，此处只改 PK）
UPDATE departments SET id = 'de000000-0000-4000-8000-000000000002' WHERE id = 'de000000-0000-0000-0000-000000000002';
UPDATE departments SET id = 'de000000-0000-4000-8000-000000000003' WHERE id = 'de000000-0000-0000-0000-000000000003';
UPDATE departments SET id = 'de000000-0000-4000-8000-000000000004' WHERE id = 'de000000-0000-0000-0000-000000000004';

-- 2d. 按临时表映射恢复 users.department_id（旧 UUID → 对应新 UUID）
UPDATE users u
    SET department_id = CASE m.old_dept_id
        WHEN 'de000000-0000-0000-0000-000000000001' THEN 'de000000-0000-4000-8000-000000000001'::UUID
        WHEN 'de000000-0000-0000-0000-000000000002' THEN 'de000000-0000-4000-8000-000000000002'::UUID
        WHEN 'de000000-0000-0000-0000-000000000003' THEN 'de000000-0000-4000-8000-000000000003'::UUID
        WHEN 'de000000-0000-0000-0000-000000000004' THEN 'de000000-0000-4000-8000-000000000004'::UUID
    END
    FROM _tmp_user_dept_map m
    WHERE u.id = m.user_id;

-- 2e. 按临时表映射恢复 departments.parent_id（旧 UUID → 对应新 UUID）
UPDATE departments d
    SET parent_id = CASE m.old_parent_id
        WHEN 'de000000-0000-0000-0000-000000000001' THEN 'de000000-0000-4000-8000-000000000001'::UUID
        WHEN 'de000000-0000-0000-0000-000000000002' THEN 'de000000-0000-4000-8000-000000000002'::UUID
        WHEN 'de000000-0000-0000-0000-000000000003' THEN 'de000000-0000-4000-8000-000000000003'::UUID
        WHEN 'de000000-0000-0000-0000-000000000004' THEN 'de000000-0000-4000-8000-000000000004'::UUID
    END
    FROM _tmp_dept_parent_map m
    WHERE d.id = m.dept_id;

DROP TABLE _tmp_user_dept_map;
DROP TABLE _tmp_dept_parent_map;

-- =========================================================================
-- 3. KPI 指标定义 UUID 修复（K01-K14）
--    先更新引用 metric_id 的子表，再更新 PK
-- =========================================================================

-- K01  cc000000-0000-0000-0000-000000000001 → cc000000-0000-4000-8000-000000000001
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000001' WHERE metric_id = 'cc000000-0000-0000-0000-000000000001';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000001' WHERE metric_id = 'cc000000-0000-0000-0000-000000000001';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000001' WHERE id = 'cc000000-0000-0000-0000-000000000001';

-- K02  cc000000-0000-0000-0000-000000000002 → cc000000-0000-4000-8000-000000000002
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000002' WHERE metric_id = 'cc000000-0000-0000-0000-000000000002';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000002' WHERE metric_id = 'cc000000-0000-0000-0000-000000000002';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000002' WHERE id = 'cc000000-0000-0000-0000-000000000002';

-- K03  cc000000-0000-0000-0000-000000000003 → cc000000-0000-4000-8000-000000000003
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000003' WHERE metric_id = 'cc000000-0000-0000-0000-000000000003';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000003' WHERE metric_id = 'cc000000-0000-0000-0000-000000000003';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000003' WHERE id = 'cc000000-0000-0000-0000-000000000003';

-- K04  cc000000-0000-0000-0000-000000000004 → cc000000-0000-4000-8000-000000000004
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000004' WHERE metric_id = 'cc000000-0000-0000-0000-000000000004';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000004' WHERE metric_id = 'cc000000-0000-0000-0000-000000000004';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000004' WHERE id = 'cc000000-0000-0000-0000-000000000004';

-- K05  cc000000-0000-0000-0000-000000000005 → cc000000-0000-4000-8000-000000000005
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000005' WHERE metric_id = 'cc000000-0000-0000-0000-000000000005';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000005' WHERE metric_id = 'cc000000-0000-0000-0000-000000000005';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000005' WHERE id = 'cc000000-0000-0000-0000-000000000005';

-- K06  cc000000-0000-0000-0000-000000000006 → cc000000-0000-4000-8000-000000000006
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000006' WHERE metric_id = 'cc000000-0000-0000-0000-000000000006';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000006' WHERE metric_id = 'cc000000-0000-0000-0000-000000000006';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000006' WHERE id = 'cc000000-0000-0000-0000-000000000006';

-- K07  cc000000-0000-0000-0000-000000000007 → cc000000-0000-4000-8000-000000000007
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000007' WHERE metric_id = 'cc000000-0000-0000-0000-000000000007';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000007' WHERE metric_id = 'cc000000-0000-0000-0000-000000000007';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000007' WHERE id = 'cc000000-0000-0000-0000-000000000007';

-- K08  cc000000-0000-0000-0000-000000000008 → cc000000-0000-4000-8000-000000000008
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000008' WHERE metric_id = 'cc000000-0000-0000-0000-000000000008';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000008' WHERE metric_id = 'cc000000-0000-0000-0000-000000000008';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000008' WHERE id = 'cc000000-0000-0000-0000-000000000008';

-- K09  cc000000-0000-0000-0000-000000000009 → cc000000-0000-4000-8000-000000000009
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000009' WHERE metric_id = 'cc000000-0000-0000-0000-000000000009';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000009' WHERE metric_id = 'cc000000-0000-0000-0000-000000000009';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000009' WHERE id = 'cc000000-0000-0000-0000-000000000009';

-- K10  cc000000-0000-0000-0000-000000000010 → cc000000-0000-4000-8000-000000000010
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000010' WHERE metric_id = 'cc000000-0000-0000-0000-000000000010';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000010' WHERE metric_id = 'cc000000-0000-0000-0000-000000000010';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000010' WHERE id = 'cc000000-0000-0000-0000-000000000010';

-- K11  cc000000-0000-0000-0000-000000000011 → cc000000-0000-4000-8000-000000000011
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000011' WHERE metric_id = 'cc000000-0000-0000-0000-000000000011';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000011' WHERE metric_id = 'cc000000-0000-0000-0000-000000000011';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000011' WHERE id = 'cc000000-0000-0000-0000-000000000011';

-- K12  cc000000-0000-0000-0000-000000000012 → cc000000-0000-4000-8000-000000000012
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000012' WHERE metric_id = 'cc000000-0000-0000-0000-000000000012';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000012' WHERE metric_id = 'cc000000-0000-0000-0000-000000000012';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000012' WHERE id = 'cc000000-0000-0000-0000-000000000012';

-- K13  cc000000-0000-0000-0000-000000000013 → cc000000-0000-4000-8000-000000000013
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000013' WHERE metric_id = 'cc000000-0000-0000-0000-000000000013';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000013' WHERE metric_id = 'cc000000-0000-0000-0000-000000000013';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000013' WHERE id = 'cc000000-0000-0000-0000-000000000013';

-- K14  cc000000-0000-0000-0000-000000000014 → cc000000-0000-4000-8000-000000000014
UPDATE kpi_scheme_metrics SET metric_id = 'cc000000-0000-4000-8000-000000000014' WHERE metric_id = 'cc000000-0000-0000-0000-000000000014';
UPDATE kpi_score_snapshot_items SET metric_id = 'cc000000-0000-4000-8000-000000000014' WHERE metric_id = 'cc000000-0000-0000-0000-000000000014';
UPDATE kpi_metric_definitions SET id = 'cc000000-0000-4000-8000-000000000014' WHERE id = 'cc000000-0000-0000-0000-000000000014';

-- =========================================================================
-- 4. 同步修正 _schema_migrations 中 020/023 的 hash 记录
--    使其与当前文件（已修正 UUID 的版本）保持一致，避免 setup_server.sh 再次报错
--    注：仅 setup_server.sh 维护 _schema_migrations(file_hash) 表；
--    init_local_postgres.sh 使用的是 schema_migrations（无下划线、无 file_hash 列），
--    因此用 to_regclass 判断后再执行，保证两种环境都能跑通本迁移。
-- =========================================================================
DO $$
BEGIN
    IF to_regclass('public._schema_migrations') IS NOT NULL THEN
        UPDATE _schema_migrations
            SET file_hash = 'a36685dd396165ae7eca7c9f223012bd'
            WHERE filename = '020_seed_reference_data.sql'
              AND file_hash = 'fffb6dc4a84eafcc229e6caaa851ae4b';

        UPDATE _schema_migrations
            SET file_hash = 'b434cfb2a6ccdbee54bac0f94fe9c546'
            WHERE filename = '023_seed_company_node.sql'
              AND file_hash = 'd4637734d918f1c045e6253062bdb259';
    END IF;
END$$;

COMMIT;
