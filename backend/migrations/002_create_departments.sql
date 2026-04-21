-- =============================================================================
-- Migration: 002_create_departments
-- Description: 三级组织架构树（公司 → 部门 → 组）
--   仅含自引用 FK（parent_id → departments），无外部依赖。
--   必须先于 users 建立，因为 users.department_id 引用此表。
-- 依赖: 001
-- =============================================================================

BEGIN;

CREATE TABLE departments (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    -- 三级树上级节点，NULL 表示顶级（公司级）
    parent_id   UUID        REFERENCES departments(id),
    -- 层级：1=公司级，2=部门级，3=小组级
    level       SMALLINT    NOT NULL CHECK (level BETWEEN 1 AND 3),
    sort_order  INTEGER     NOT NULL DEFAULT 0,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_departments_parent ON departments(parent_id);

COMMIT;
