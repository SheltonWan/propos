-- =============================================================================
-- Migration: 011_add_basement_floors_to_buildings
-- Description: 为 buildings 表补充 basement_floors 字段（地下层数）
-- 依赖: 004
-- =============================================================================

BEGIN;

ALTER TABLE buildings
    ADD COLUMN basement_floors SMALLINT NOT NULL DEFAULT 0;

COMMIT;
