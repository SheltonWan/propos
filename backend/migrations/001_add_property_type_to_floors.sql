-- -----------------------------------------------------------------------
-- 001_add_property_type_to_floors
-- 目的：为 floors 表增加 property_type 列，支持混合体楼栋的楼层级业态标注。
--
-- 应用条件：已按 000_consolidated_schema.sql 完成初始化的数据库。
-- 幂等：所有语句使用 IF NOT EXISTS / IF EXISTS，可重复执行。
-- -----------------------------------------------------------------------

-- 1. 新增列（property_type 枚举已在 000_consolidated_schema.sql 中定义）
ALTER TABLE floors
  ADD COLUMN IF NOT EXISTS property_type property_type;
-- 注释：混合体楼栋需逐层指定业态；非混合体楼栋在应用层自动继承楼栋业态，
--       NULL 代表「待定」，不阻断楼层及单元的创建。

-- 2. 回填存量数据：非 mixed 楼栋的楼层直接继承楼栋业态
--    buildings.property_type 本身就是 property_type enum，可直接赋值。
UPDATE floors f
SET property_type = b.property_type
FROM buildings b
WHERE f.building_id = b.id
  AND b.property_type IN ('office', 'retail', 'apartment')
  AND f.property_type IS NULL;

-- 3. 索引（按业态过滤楼层列表时使用）
CREATE INDEX IF NOT EXISTS idx_floors_property_type
  ON floors(property_type)
  WHERE property_type IS NOT NULL;
