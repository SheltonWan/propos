-- =============================================================================
-- Migration: 021_alter_assets_schema
-- Description: 根据 data_model.md v1.5 规范更新资产模块表结构
--   - buildings:         重命名 gross_area→gfa, leasable_area→nla, year_built→built_year；
--                        address 改为可选；删除 city/cover_image_path/is_active
--   - floors:            重命名 label→floor_name, floor_area→nla；
--                        新增 svg_path/png_path/updated_at；删除 is_active
--   - floor_plans:       重构为单版本双路径（version_label + svg_path + png_path）；
--                        替换 is_current 普通索引为唯一索引
--   - units:             重命名 unit_no→unit_number, decoration→decoration_status,
--                        status→current_status；新增业态/朝向/层高/可租标识/ext_fields/
--                        current_contract_id/qr_code/updated_at；
--                        迁移 floor_plan_coords→ext_fields；删除 billing_area/floor_plan_coords/notes；
--                        更新唯一约束
--   - renovation_records: 重命名 record_type→renovation_type, start_date→started_at,
--                         end_date→completed_at；新增 before_photo_paths/after_photo_paths/
--                         contractor/updated_at；迁移 photo_paths；删除旧列；
--                         description 改为可选
-- 依赖: 004_create_assets
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- buildings
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE buildings RENAME COLUMN gross_area TO gfa;
ALTER TABLE buildings RENAME COLUMN leasable_area TO nla;
ALTER TABLE buildings RENAME COLUMN year_built TO built_year;

-- address 改为可选（data_model 未标注 NOT NULL）
ALTER TABLE buildings ALTER COLUMN address DROP NOT NULL;

-- 删除多余列
ALTER TABLE buildings DROP COLUMN IF EXISTS city;
ALTER TABLE buildings DROP COLUMN IF EXISTS cover_image_path;
ALTER TABLE buildings DROP COLUMN IF EXISTS is_active;

-- ─────────────────────────────────────────────────────────────────────────────
-- floors
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE floors RENAME COLUMN label TO floor_name;
ALTER TABLE floors RENAME COLUMN floor_area TO nla;

ALTER TABLE floors ADD COLUMN IF NOT EXISTS svg_path   TEXT;
ALTER TABLE floors ADD COLUMN IF NOT EXISTS png_path   TEXT;
ALTER TABLE floors ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE floors DROP COLUMN IF EXISTS is_active;

-- ─────────────────────────────────────────────────────────────────────────────
-- floor_plans: 合并 svg/png 双行为单行（version_label + svg_path + png_path）
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE floor_plans ADD COLUMN IF NOT EXISTS version_label VARCHAR(50);
ALTER TABLE floor_plans ADD COLUMN IF NOT EXISTS svg_path      TEXT;
ALTER TABLE floor_plans ADD COLUMN IF NOT EXISTS png_path      TEXT;

-- 将 svg 行的 storage_path 赋给 svg_path，生成 version_label
UPDATE floor_plans
    SET version_label = COALESCE(version::text, '1'),
        svg_path      = storage_path
WHERE file_type = 'svg' OR file_type IS NULL;

-- 将同版本的 png 行的 storage_path 更新到对应 svg 行的 png_path
UPDATE floor_plans AS fp_svg
    SET png_path = sub.storage_path
FROM (
    SELECT floor_id, version, storage_path
    FROM floor_plans
    WHERE file_type = 'png'
) AS sub
WHERE fp_svg.floor_id = sub.floor_id
  AND fp_svg.version  = sub.version
  AND fp_svg.file_type = 'svg';

-- 删除 png-only 行（已合并）
DELETE FROM floor_plans WHERE file_type = 'png';

-- 为剩余行补全 version_label / svg_path（防止旧数据为空）
UPDATE floor_plans SET version_label = COALESCE(version::text, '1') WHERE version_label IS NULL;
UPDATE floor_plans SET svg_path      = ''                            WHERE svg_path      IS NULL;

ALTER TABLE floor_plans ALTER COLUMN version_label SET NOT NULL;
ALTER TABLE floor_plans ALTER COLUMN svg_path      SET NOT NULL;

-- 删除旧列
ALTER TABLE floor_plans DROP COLUMN IF EXISTS version;
ALTER TABLE floor_plans DROP COLUMN IF EXISTS file_type;
ALTER TABLE floor_plans DROP COLUMN IF EXISTS storage_path;

-- 替换普通索引为唯一约束（同楼层只允许一个 is_current=true 的版本）
DROP INDEX IF EXISTS idx_floor_plans_current;
CREATE UNIQUE INDEX IF NOT EXISTS uq_floor_plan_current
    ON floor_plans(floor_id)
    WHERE is_current = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- units
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE units RENAME COLUMN unit_no         TO unit_number;
ALTER TABLE units RENAME COLUMN decoration      TO decoration_status;
ALTER TABLE units RENAME COLUMN status          TO current_status;

-- 新增列
ALTER TABLE units ADD COLUMN IF NOT EXISTS property_type        property_type;
ALTER TABLE units ADD COLUMN IF NOT EXISTS orientation          VARCHAR(20);
ALTER TABLE units ADD COLUMN IF NOT EXISTS ceiling_height       NUMERIC(4,2);
ALTER TABLE units ADD COLUMN IF NOT EXISTS is_leasable          BOOLEAN      NOT NULL DEFAULT TRUE;
ALTER TABLE units ADD COLUMN IF NOT EXISTS ext_fields           JSONB        NOT NULL DEFAULT '{}';
ALTER TABLE units ADD COLUMN IF NOT EXISTS current_contract_id  UUID;
ALTER TABLE units ADD COLUMN IF NOT EXISTS qr_code             VARCHAR(100);
ALTER TABLE units ADD COLUMN IF NOT EXISTS updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW();

-- 迁移 floor_plan_coords → ext_fields（仅在 floor_plan_coords 有非空值时合并）
UPDATE units
    SET ext_fields = floor_plan_coords
WHERE floor_plan_coords IS NOT NULL
  AND floor_plan_coords::text NOT IN ('null', '{}', '');

-- 根据楼栋 property_type 为 units 补全业态（存量数据）
UPDATE units u
    SET property_type = b.property_type
FROM buildings b
WHERE u.building_id = b.id
  AND u.property_type IS NULL;

-- 兜底：若仍有 NULL（楼栋也为 NULL 则不可能，但防御性处理）
UPDATE units SET property_type = 'office' WHERE property_type IS NULL;

ALTER TABLE units ALTER COLUMN property_type SET NOT NULL;

-- 删除旧列
ALTER TABLE units DROP COLUMN IF EXISTS billing_area;
ALTER TABLE units DROP COLUMN IF EXISTS floor_plan_coords;
ALTER TABLE units DROP COLUMN IF EXISTS notes;

-- 更新唯一约束：旧（building_id, floor_id, unit_no）→ 新（building_id, unit_number）
ALTER TABLE units DROP CONSTRAINT IF EXISTS units_building_id_floor_id_unit_no_key;
ALTER TABLE units ADD CONSTRAINT units_building_id_unit_number_key UNIQUE (building_id, unit_number);

-- qr_code 唯一约束（允许 NULL，只对非 NULL 值唯一）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'units_qr_code_key'
    ) THEN
        ALTER TABLE units ADD CONSTRAINT units_qr_code_key UNIQUE (qr_code);
    END IF;
END $$;

-- 新增索引
CREATE INDEX IF NOT EXISTS idx_units_property_type ON units(property_type);
CREATE INDEX IF NOT EXISTS idx_units_ext_fields    ON units USING GIN(ext_fields);

-- ─────────────────────────────────────────────────────────────────────────────
-- renovation_records
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE renovation_records RENAME COLUMN record_type  TO renovation_type;
ALTER TABLE renovation_records ALTER  COLUMN renovation_type TYPE VARCHAR(100);
ALTER TABLE renovation_records RENAME COLUMN start_date   TO started_at;
ALTER TABLE renovation_records RENAME COLUMN end_date     TO completed_at;

-- description 改为可选
ALTER TABLE renovation_records ALTER COLUMN description DROP NOT NULL;

-- 新增列
ALTER TABLE renovation_records ADD COLUMN IF NOT EXISTS before_photo_paths TEXT[];
ALTER TABLE renovation_records ADD COLUMN IF NOT EXISTS after_photo_paths   TEXT[];
ALTER TABLE renovation_records ADD COLUMN IF NOT EXISTS contractor          VARCHAR(200);
ALTER TABLE renovation_records ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 迁移 photo_paths → before_photo_paths（存量数据视为改造前照片）
UPDATE renovation_records
    SET before_photo_paths = photo_paths
WHERE photo_paths IS NOT NULL
  AND array_length(photo_paths, 1) > 0;

ALTER TABLE renovation_records DROP COLUMN IF EXISTS photo_paths;

COMMIT;
