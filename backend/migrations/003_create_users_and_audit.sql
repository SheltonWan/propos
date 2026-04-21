-- =============================================================================
-- Migration: 003_create_users_and_audit
-- Description: 用户账号、审计日志、刷新令牌、定时任务日志
--   注意：users.department_id 仅声明列，不附加 FK 约束，
--   因 KPI 聚合查询需在 department → users 方向遍历；
--   正向 FK（users.department_id → departments）在 018 延迟添加。
--   users.bound_contract_id 同理，在 018 延迟添加。
-- 依赖: 001, 002
-- =============================================================================

BEGIN;

CREATE TABLE users (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL,
    -- 登录邮箱（唯一，作为登录名）
    email                 VARCHAR(255) UNIQUE NOT NULL,
    -- 密码哈希（bcrypt）
    password_hash         TEXT        NOT NULL,
    role                  user_role   NOT NULL,
    -- 所属部门（FK 延迟建立，见 018_add_deferred_foreign_keys）
    department_id         UUID,
    -- 绑定的在租合同（仅 sub_landlord 使用；FK 延迟建立，见 018）
    bound_contract_id     UUID,
    is_active             BOOLEAN     NOT NULL DEFAULT TRUE,
    -- 登录安全字段
    failed_login_attempts SMALLINT    NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    password_changed_at   TIMESTAMPTZ,
    last_login_at         TIMESTAMPTZ,
    -- 会话版本号：改密/冻结账号后递增，旧 refresh_token 自动失效
    session_version       INTEGER     NOT NULL DEFAULT 1,
    -- 二房东账号冻结（主合同到期后自动冻结）
    frozen_at             TIMESTAMPTZ,
    frozen_reason         TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_role         ON users(role);
CREATE INDEX idx_users_email        ON users(email);
CREATE INDEX idx_users_department   ON users(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_users_contract     ON users(bound_contract_id) WHERE bound_contract_id IS NOT NULL;
CREATE INDEX idx_users_locked_until ON users(locked_until) WHERE locked_until IS NOT NULL;

-- -------------------------------------------------------------------------
-- 操作审计日志（覆盖：合同变更、账单核销、权限变更、二房东数据提交）
-- -------------------------------------------------------------------------
CREATE TABLE audit_logs (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 操作人（NULL 表示系统自动触发）
    user_id     UUID        REFERENCES users(id),
    -- 操作动作：CREATE / UPDATE / DELETE / APPROVE 等
    action      VARCHAR(50) NOT NULL,
    -- 被操作资源类型（表名或业务实体名）
    entity_type VARCHAR(100) NOT NULL,
    entity_id   UUID        NOT NULL,
    -- 变更前后快照（NULL = 不适用）
    before_data JSONB,
    after_data  JSONB,
    -- 附加上下文（请求 IP、业务模块等）
    meta        JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_entity    ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_user      ON audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_created   ON audit_logs(created_at DESC);

-- -------------------------------------------------------------------------
-- JWT 刷新令牌（实现 Refresh Token 轮换机制）
-- -------------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 令牌哈希值（SHA-256，不存储明文）
    token_hash  TEXT        NOT NULL UNIQUE,
    -- 到期时间（默认 30 天）
    expires_at  TIMESTAMPTZ NOT NULL,
    -- 是否已被撤销
    revoked     BOOLEAN     NOT NULL DEFAULT FALSE,
    -- 设备标识（便于多设备管理）
    device_info TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user    ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash    ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_active  ON refresh_tokens(user_id, revoked)
    WHERE revoked = FALSE;

-- -------------------------------------------------------------------------
-- 定时任务执行日志（账单生成、表盘刷新、KPI 快照等）
-- -------------------------------------------------------------------------
CREATE TABLE job_execution_logs (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 任务名称（如 'auto_generate_invoices' / 'kpi_snapshot' / 'refresh_unit_status'）
    job_name        VARCHAR(100) NOT NULL,
    -- 执行状态：'running' / 'success' / 'failed'
    status          VARCHAR(20)  NOT NULL DEFAULT 'running',
    -- 处理数量汇总
    records_processed INTEGER,
    records_failed    INTEGER,
    -- 错误信息（failed 状态时记录）
    error_message   TEXT,
    -- 执行耗时（毫秒）
    duration_ms     INTEGER,
    started_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ
);

CREATE INDEX idx_job_logs_name    ON job_execution_logs(job_name);
CREATE INDEX idx_job_logs_status  ON job_execution_logs(status);
CREATE INDEX idx_job_logs_started ON job_execution_logs(started_at DESC);

COMMIT;
