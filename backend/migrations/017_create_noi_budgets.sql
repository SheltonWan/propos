-- =============================================================================
-- Migration: 017_create_noi_budgets
-- Description: NOI 年度预算（v1.7 新增）
--   按楼栋或业态维度录入预算值，用于 K07（NOI 达成率）计算。
--   匹配规则：取最近一条 building_id（或 property_type）+ period_year +
--          period_month（可选）匹配的记录作为预算基准。
-- 依赖: 001, 003, 004
-- =============================================================================

BEGIN;

CREATE TABLE noi_budgets (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 可按楼栋或业态维度录入（均为可选，同时为 NULL 表示全局预算）
    building_id    UUID          REFERENCES buildings(id),
    property_type  property_type,
    -- 预算周期
    period_year    SMALLINT      NOT NULL,   -- 预算年份（如 2026）
    period_month   SMALLINT      CHECK (period_month BETWEEN 1 AND 12), -- NULL = 年度预算
    -- 预算值
    budget_noi     NUMERIC(14,2) NOT NULL,   -- 预算 NOI（元）
    -- 录入信息
    created_by     UUID          REFERENCES users(id),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_noi_budgets_building ON noi_budgets(building_id)
    WHERE building_id IS NOT NULL;
CREATE INDEX idx_noi_budgets_type     ON noi_budgets(property_type)
    WHERE property_type IS NOT NULL;
CREATE INDEX idx_noi_budgets_period   ON noi_budgets(period_year, period_month);

COMMIT;
