-- =============================================================================
-- Migration: 014_create_password_reset_tokens
-- Description: 忘记密码 token 表
--   password_reset_tokens — 存储密码重置请求 token（哈希值），有效期 2 小时
--   安全规则：
--     1. 数据库只存 SHA-256 哈希，原始 token 仅出现在邮件链接中
--     2. used_at 记录使用时刻，已使用 token 不可二次提交
--     3. 发起新请求时清理同用户的历史过期/未用 token（防止枚举）
-- 依赖: 003_create_users_and_audit
-- =============================================================================

BEGIN;

CREATE TABLE password_reset_tokens (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 绑定用户（级联删除）
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- SHA-256 哈希后的 token，数据库不存明文
    token_hash  TEXT         NOT NULL UNIQUE,
    -- 申请时间
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- 过期时间（created_at + 2 小时）
    expires_at  TIMESTAMPTZ  NOT NULL,
    -- 使用时间（NULL 表示尚未使用）
    used_at     TIMESTAMPTZ
);

-- 按 token_hash 快速查验
CREATE INDEX idx_password_reset_tokens_token_hash
    ON password_reset_tokens (token_hash);

-- 按用户 ID 清理历史请求
CREATE INDEX idx_password_reset_tokens_user_id
    ON password_reset_tokens (user_id);

COMMIT;
