-- =============================================================================
-- Migration: 20260413_role_expansion
-- Description: 角色体系扩展 v2.0
--   1. 重命名: admin → super_admin
--   2. 重命名: lease_specialist → leasing_specialist
--   3. 重命名: frontline_staff → maintenance_staff（若存在）
--   4. 重命名: read_only → report_viewer
--   5. 新增: property_inspector
-- Strategy: PostgreSQL 不支持 ALTER TYPE RENAME VALUE，
--   采用 CREATE NEW → ALTER COLUMN USING CAST → DROP OLD 三步法
-- =============================================================================

BEGIN;

-- Step 1: 创建新枚举类型（8 值）
CREATE TYPE user_role_v2 AS ENUM (
  'super_admin',
  'operations_manager',
  'leasing_specialist',
  'finance_staff',
  'maintenance_staff',
  'property_inspector',
  'report_viewer',
  'sub_landlord'
);

-- Step 2: 迁移 users 表 role 列
ALTER TABLE users
  ALTER COLUMN role TYPE user_role_v2
  USING (
    CASE role::text
      WHEN 'admin'            THEN 'super_admin'::user_role_v2
      WHEN 'lease_specialist'  THEN 'leasing_specialist'::user_role_v2
      WHEN 'frontline_staff'   THEN 'maintenance_staff'::user_role_v2
      WHEN 'read_only'         THEN 'report_viewer'::user_role_v2
      -- 已存在的值直接映射
      WHEN 'operations_manager' THEN 'operations_manager'::user_role_v2
      WHEN 'finance_staff'      THEN 'finance_staff'::user_role_v2
      WHEN 'maintenance_staff'  THEN 'maintenance_staff'::user_role_v2
      WHEN 'sub_landlord'       THEN 'sub_landlord'::user_role_v2
      ELSE role::text::user_role_v2
    END
  );

-- Step 3: 迁移 audit_logs 表（如有 actor_role 列引用旧枚举）
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'audit_logs' AND column_name = 'actor_role'
  ) THEN
    EXECUTE 'ALTER TABLE audit_logs
      ALTER COLUMN actor_role TYPE user_role_v2
      USING (
        CASE actor_role::text
          WHEN ''admin''            THEN ''super_admin''::user_role_v2
          WHEN ''lease_specialist''  THEN ''leasing_specialist''::user_role_v2
          WHEN ''frontline_staff''   THEN ''maintenance_staff''::user_role_v2
          WHEN ''read_only''         THEN ''report_viewer''::user_role_v2
          ELSE actor_role::text::user_role_v2
        END
      )';
  END IF;
END $$;

-- Step 4: 删除旧枚举类型，重命名新枚举
DROP TYPE IF EXISTS user_role;
ALTER TYPE user_role_v2 RENAME TO user_role;

-- Step 5: 验证——应输出 8 个枚举值
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'user_role'::regtype ORDER BY enumsortorder;

COMMIT;
