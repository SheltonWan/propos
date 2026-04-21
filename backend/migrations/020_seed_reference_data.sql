-- =============================================================================
-- Migration: 020_seed_reference_data
-- Description: 参考数据初始化（依赖所有表已建完）
--   1. 初始超级管理员账号（密码须在首次登录后强制修改）
--   2. 初始三个部门（租务部/财务部/物业运营部）
--   3. KPI 指标库 K01-K14（含 direction / category）
--
-- 注意：密码哈希应在部署时由 scripts/check_env.sh 生成，此处为临时占位值。
--   实际部署应通过环境变量 ADMIN_DEFAULT_PASSWORD_HASH 注入，
--   或在容器启动脚本中替换此行。
-- 依赖: 001-018
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 1. 初始超级管理员
--    密码哈希对应明文 'ChangeMe@2026!'（bcrypt cost=12，首登后强制修改）
-- -------------------------------------------------------------------------
INSERT INTO users (id, name, email, password_hash, role, is_active)
VALUES (
    'f0000000-0000-0000-0000-000000000001',  -- 与 scripts/seed.sql v_user_admin 保持一致
    '系统管理员',
    'admin@propos.local',
    '$2b$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',  -- 占位哈希
    'super_admin',
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- -------------------------------------------------------------------------
-- 2. 初始三个部门（第 2 级，parent_id = NULL 的顶级节点为公司级虚拟节点）
-- -------------------------------------------------------------------------
INSERT INTO departments (id, name, parent_id, level, sort_order)
VALUES
    -- UUID 与 scripts/seed.sql v_dept_lease/v_dept_fin/v_dept_ops 保持一致
    ('de000000-0000-0000-0000-000000000002', '租务部',     NULL, 2, 10),
    ('de000000-0000-0000-0000-000000000003', '财务部',     NULL, 2, 20),
    ('de000000-0000-0000-0000-000000000004', '物业运营部', NULL, 2, 30)
ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------------------
-- 3. KPI 指标库 K01-K14
-- -------------------------------------------------------------------------
-- UUID 前缀 cc，与 scripts/seed.sql v_km_k01..v_km_k10 保持一致
INSERT INTO kpi_metric_definitions
    (id, code, name, category,
     default_full_score_threshold, default_pass_threshold, default_fail_threshold,
     higher_is_better, direction, source_module, is_manual_input)
VALUES
    ('cc000000-0000-0000-0000-000000000001',
     'K01', '出租率', 'leasing',
     0.95, 0.80, 0.60, TRUE, 'positive', 'assets', FALSE),

    ('cc000000-0000-0000-0000-000000000002',
     'K02', '收款及时率', 'finance',
     0.95, 0.85, 0.70, TRUE, 'positive', 'finance', FALSE),

    ('cc000000-0000-0000-0000-000000000003',
     'K03', '租户集中度', 'leasing',
     0.40, 0.55, 0.70, FALSE, 'negative', 'contracts', FALSE),

    ('cc000000-0000-0000-0000-000000000004',
     'K04', '续约率', 'leasing',
     0.80, 0.60, 0.40, TRUE, 'positive', 'contracts', FALSE),

    ('cc000000-0000-0000-0000-000000000005',
     'K05', '工单响应时效', 'service',
     24, 48, 72, FALSE, 'negative', 'workorders', FALSE),

    ('cc000000-0000-0000-0000-000000000006',
     'K06', '空置周转天数', 'leasing',
     30, 60, 90, FALSE, 'negative', 'assets', FALSE),

    ('cc000000-0000-0000-0000-000000000007',
     'K07', 'NOI 达成率', 'finance',
     1.00, 0.85, 0.70, TRUE, 'positive', 'finance', FALSE),

    ('cc000000-0000-0000-0000-000000000008',
     'K08', '逾期率', 'finance',
     0.05, 0.15, 0.20, FALSE, 'negative', 'finance', FALSE),

    ('cc000000-0000-0000-0000-000000000009',
     'K09', '租金递增执行率', 'leasing',
     0.95, 0.85, 0.70, TRUE, 'positive', 'contracts', FALSE),

    ('cc000000-0000-0000-0000-000000000010',
     'K10', '租户满意度', 'service',
     90, 75, 60, TRUE, 'positive', 'workorders', TRUE),

    ('cc000000-0000-0000-0000-000000000011',
     'K11', '预防性维修率', 'service',
     0.90, 0.70, 0.50, TRUE, 'positive', 'workorders', FALSE),

    ('cc000000-0000-0000-0000-000000000012',
     'K12', '空置面积降幅', 'growth',
     0.20, 0.10, 0, TRUE, 'positive', 'assets', FALSE),

    ('cc000000-0000-0000-0000-000000000013',
     'K13', '新签约面积', 'growth',
     2000, 1000, 500, TRUE, 'positive', 'contracts', FALSE),

    ('cc000000-0000-0000-0000-000000000014',
     'K14', '续签率', 'leasing',
     0.80, 0.60, 0.40, TRUE, 'positive', 'contracts', FALSE)

ON CONFLICT (id) DO NOTHING;

COMMIT;
