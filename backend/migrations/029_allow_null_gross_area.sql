-- =============================================================================
-- Migration: 029_allow_null_gross_area
-- Description: 允许 units.gross_area 为 NULL，支持从 DXF 导入不带面积标注的房间
--
-- 背景：
--   split_dxf_by_floor.py + annotate_hotzone.py 按 AREA_TEXT_RE 正则匹配面积文字，
--   但部分房间（如无面积标注的配套用房、过道等）在 DXF 中没有对应文字，
--   area_m2 字段为 None → Dart 传入 null → NOT NULL 约束导致 INSERT 失败 → 该房间跳过。
--   实测：每层 22 个房间中有 12 个因此被跳过，只有 10 个成功入库。
--
-- 修复：
--   去除 NOT NULL 约束，允许 gross_area 为空（面积可在导入后通过台账编辑补录）。
--   CHECK (gross_area > 0) 保留：PostgreSQL 对 NULL 值不触发 CHECK，
--   仅对明确传入非正数的情况拦截，保持原有数据质量防护。
--
-- 影响：
--   - 存量数据不受影响（已有记录 gross_area 均非 NULL）
--   - 新 DXF 导入时无面积标注的单元可成功入库，后续手动补录
--   - 下游 NOI / WALE 等计算若依赖 gross_area 须已做可空处理（Dart Unit.grossArea: double?）
-- =============================================================================

BEGIN;

ALTER TABLE units ALTER COLUMN gross_area DROP NOT NULL;

COMMIT;
