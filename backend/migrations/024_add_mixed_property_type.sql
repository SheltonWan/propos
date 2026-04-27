-- =============================================================================
-- Migration: 024_add_mixed_property_type
-- Description: 为 property_type ENUM 新增 'mixed' 值，用于综合体（一栋楼多种业态）
--   仅作用于 buildings.property_type 与 noi_budgets.property_type 的标签维度，
--   units.property_type 仍只允许 office / retail / apartment（按行实际业态指定）。
-- =============================================================================

BEGIN;

ALTER TYPE property_type ADD VALUE IF NOT EXISTS 'mixed';

COMMIT;
