-- =============================================================================
-- Migration: 005_create_user_managed_scopes
-- Description: 管辖范围（部门默认 + 个人覆盖双机制）
--   KPI 数据归集时取个人范围（优先）或继承部门范围。
-- 依赖: 002, 003, 004
-- =============================================================================

BEGIN;

CREATE TABLE user_managed_scopes (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 绑定到部门（默认范围）或个人（覆盖范围），至少指定其一
    department_id UUID          REFERENCES departments(id),
    user_id       UUID          REFERENCES users(id),
    -- 管辖维度（可多维度叠加）
    building_id   UUID          REFERENCES buildings(id),
    floor_id      UUID          REFERENCES floors(id),
    property_type property_type,
    CHECK (department_id IS NOT NULL OR user_id IS NOT NULL)
);

CREATE INDEX idx_managed_scopes_dept  ON user_managed_scopes(department_id)
    WHERE department_id IS NOT NULL;
CREATE INDEX idx_managed_scopes_user  ON user_managed_scopes(user_id)
    WHERE user_id IS NOT NULL;

COMMIT;
