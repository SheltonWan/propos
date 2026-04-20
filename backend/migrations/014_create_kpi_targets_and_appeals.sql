-- =============================================================================
-- Migration: 014_create_kpi_targets_and_appeals
-- Description: KPI 方案绑定对象 + KPI 申诉
--   kpi_scheme_targets：将方案绑定到具体部门或员工，支持多目标
--   kpi_appeals：员工在快照冻结后 7 个自然日内提交申诉
-- 依赖: 002, 003, 013
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- KPI 方案绑定对象（部门级 / 员工级）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_scheme_targets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id     UUID NOT NULL REFERENCES kpi_schemes(id) ON DELETE CASCADE,
    -- 绑定到用户（员工考核）或部门（团队考核），至少指定其一
    user_id       UUID REFERENCES users(id),
    department_id UUID REFERENCES departments(id),
    CHECK (user_id IS NOT NULL OR department_id IS NOT NULL)
);

-- 同一方案内每个绑定目标唯一（用户级和部门级分别约束）
CREATE UNIQUE INDEX uq_scheme_target_user
    ON kpi_scheme_targets(scheme_id, user_id)
    WHERE user_id IS NOT NULL;

CREATE UNIQUE INDEX uq_scheme_target_dept
    ON kpi_scheme_targets(scheme_id, department_id)
    WHERE department_id IS NOT NULL;

CREATE INDEX idx_scheme_targets_scheme ON kpi_scheme_targets(scheme_id);
CREATE INDEX idx_scheme_targets_dept   ON kpi_scheme_targets(department_id)
    WHERE department_id IS NOT NULL;

-- -------------------------------------------------------------------------
-- KPI 申诉（快照冻结后 7 日内可提交）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_appeals (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id    UUID        NOT NULL REFERENCES kpi_score_snapshots(id),
    appellant_id   UUID        NOT NULL REFERENCES users(id),
    reason         TEXT        NOT NULL,
    -- 申诉状态：pending=待审核, approved=通过（触发快照重算), rejected=已驳回
    status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewer_id    UUID        REFERENCES users(id),
    review_comment TEXT,
    reviewed_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kpi_appeals_snapshot ON kpi_appeals(snapshot_id);
-- 快速检索待处理申诉
CREATE INDEX idx_kpi_appeals_pending  ON kpi_appeals(status)
    WHERE status = 'pending';

COMMIT;
