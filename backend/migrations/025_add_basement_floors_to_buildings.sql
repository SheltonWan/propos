-- =============================================================================
-- Migration: 025_add_basement_floors_to_buildings
-- Description: 为 buildings 表新增 basement_floors 列，持久化地下层数量。
--   - 地下层数此前仅通过 floors 表的 floor_number < 0 行隐式存储，
--     buildings 表缺少对应的快速读取字段。
--   - 本迁移从现有 floors 表反推初始值，保证数据一致性。
-- 依赖: 004_create_assets, 021_alter_assets_schema
-- =============================================================================

BEGIN;

-- 新增 basement_floors 列，默认值 0，必须 >= 0
ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS basement_floors SMALLINT NOT NULL DEFAULT 0
        CHECK (basement_floors >= 0);

-- 从现有 floors 表反推已有楼栋的地下层数
UPDATE buildings b
SET basement_floors = (
    SELECT COUNT(*)::SMALLINT
    FROM floors f
    WHERE f.building_id = b.id
      AND f.floor_number < 0
);

COMMIT;
