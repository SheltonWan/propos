-- =============================================================================
-- Migration: 022_extend_import_data_types
-- Description: 扩展 import_data_type 枚举，新增 'users' / 'departments'
--   用于支持 POST /api/users/import 与 POST /api/departments/import（v1.8）
-- 依赖: 015
-- 注意: ALTER TYPE ADD VALUE 不能放在事务里，因此本文件不使用 BEGIN/COMMIT
-- =============================================================================

ALTER TYPE import_data_type ADD VALUE IF NOT EXISTS 'users';
ALTER TYPE import_data_type ADD VALUE IF NOT EXISTS 'departments';
