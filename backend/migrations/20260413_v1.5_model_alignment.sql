-- =============================================================================
-- Migration: 20260413_v1.5_model_alignment
-- Description: data_model v1.5 对齐 — 枚举扩展、新枚举类型、表结构变更、Seed 补充
--   1. unit_status 新增 renovating / pre_lease
--   2. credit_rating 新增 D 级
--   3. 新增 pricing_model 枚举 + contracts.pricing_model 字段
--   4. 新增 kpi_scheme_status 枚举，kpi_schemes.is_active → status
--   5. 新增 kpi_metric_category 枚举 + kpi_metric_definitions.category 字段
--   6. alerts 新增 target_roles 字段
--   7. KPI 指标种子数据 K11-K14
-- Note: ALTER TYPE ... ADD VALUE 不能在事务块内执行，
--       需分步部署或使用 psql 的隐式事务模式。
-- =============================================================================

-- ─────────────────────────────────────────────
-- Step 1: 枚举扩展（必须在事务外执行）
-- ─────────────────────────────────────────────

ALTER TYPE unit_status ADD VALUE IF NOT EXISTS 'renovating';
ALTER TYPE unit_status ADD VALUE IF NOT EXISTS 'pre_lease';
ALTER TYPE credit_rating ADD VALUE IF NOT EXISTS 'D';

-- ─────────────────────────────────────────────
-- Step 2: 新增枚举类型
-- ─────────────────────────────────────────────

CREATE TYPE pricing_model AS ENUM ('area', 'flat', 'revenue');
CREATE TYPE kpi_scheme_status AS ENUM ('draft', 'active', 'archived');
CREATE TYPE kpi_metric_category AS ENUM ('leasing', 'finance', 'service', 'growth');

-- ─────────────────────────────────────────────
-- Step 3: 表结构变更（事务内执行）
-- ─────────────────────────────────────────────

BEGIN;

-- 3a. contracts 新增 pricing_model 字段
ALTER TABLE contracts
    ADD COLUMN IF NOT EXISTS pricing_model pricing_model NOT NULL DEFAULT 'area';
COMMENT ON COLUMN contracts.pricing_model IS
    'area=按面积计租(元/m²/月); flat=整套月租; revenue=保底+分成';

-- 3b. kpi_metric_definitions 新增 category 字段
ALTER TABLE kpi_metric_definitions
    ADD COLUMN IF NOT EXISTS category kpi_metric_category NOT NULL DEFAULT 'leasing';

-- 3c. kpi_schemes: is_active BOOLEAN → status kpi_scheme_status
ALTER TABLE kpi_schemes
    ADD COLUMN IF NOT EXISTS status kpi_scheme_status NOT NULL DEFAULT 'draft';

-- 迁移数据：is_active=true → 'active', is_active=false → 'archived'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'kpi_schemes' AND column_name = 'is_active'
    ) THEN
        UPDATE kpi_schemes SET status = CASE
            WHEN is_active = TRUE THEN 'active'::kpi_scheme_status
            ELSE 'archived'::kpi_scheme_status
        END;
        ALTER TABLE kpi_schemes DROP COLUMN is_active;
    END IF;
END $$;

-- 3d. alerts 新增 target_roles 字段
ALTER TABLE alerts
    ADD COLUMN IF NOT EXISTS target_roles user_role[];
COMMENT ON COLUMN alerts.target_roles IS
    '按角色广播推送目标；NULL 时仅推送给 target_user_id 指定用户';

COMMIT;

-- ─────────────────────────────────────────────
-- Step 4: 回填 kpi_metric_definitions.category
-- ─────────────────────────────────────────────

BEGIN;

UPDATE kpi_metric_definitions SET category = 'leasing'
    WHERE code IN ('K01','K03','K04','K06','K09');
UPDATE kpi_metric_definitions SET category = 'finance'
    WHERE code IN ('K02','K07','K08');
UPDATE kpi_metric_definitions SET category = 'service'
    WHERE code IN ('K05','K10');
-- K11-K14 将在 Step 5 INSERT 时直接指定

COMMIT;

-- ─────────────────────────────────────────────
-- Step 5: 新增 KPI 指标种子数据 K11-K14
-- ─────────────────────────────────────────────

BEGIN;

INSERT INTO kpi_metric_definitions
    (code, name, category, default_full_score_threshold, default_pass_threshold,
     default_fail_threshold, higher_is_better, direction, source_module, is_manual_input)
VALUES
    ('K11', '预防性维修率',     'service'::kpi_metric_category,
     0.90, 0.70, 0.50, TRUE, 'positive', 'workorders', FALSE),
    ('K12', '空置面积降幅',     'growth'::kpi_metric_category,
     0.20, 0.10, 0,    TRUE, 'positive', 'assets',     FALSE),
    ('K13', '新签约面积（m²）', 'growth'::kpi_metric_category,
     2000, 1000, 500,  TRUE, 'positive', 'contracts',  FALSE),
    ('K14', '续签率',           'leasing'::kpi_metric_category,
     0.80, 0.60, 0.40, TRUE, 'positive', 'contracts',  FALSE)
ON CONFLICT (code) DO NOTHING;

COMMIT;
