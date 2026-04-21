-- Migration: 015_replace_password_reset_tokens_with_otps
-- 将基于邮件链接的密码重置方案替换为 OTP 验证码方案。
-- 原 password_reset_tokens 表废弃（迁移期间直接 DROP，未上生产）。
BEGIN;

DROP TABLE IF EXISTS password_reset_tokens;

-- OTP 记录表
-- code_hash: SHA-256( 6位数字 OTP 明文 )，明文只在邮件中发送，不入库
-- failed_attempts: 累计验证失败次数，超过 5 次视为耗尽，不可继续使用
-- expires_at: 创建时写入 now() + 10 分钟
CREATE TABLE password_reset_otps (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 冗余存储邮箱，避免查 OTP 时再 JOIN users
    email            TEXT         NOT NULL,
    code_hash        TEXT         NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expires_at       TIMESTAMPTZ  NOT NULL,
    used_at          TIMESTAMPTZ,
    failed_attempts  INT          NOT NULL DEFAULT 0
);

-- 按 user_id + email 查找（发 OTP 时按邮箱查，重置时也按邮箱查最新记录）
CREATE INDEX idx_password_reset_otps_user_id ON password_reset_otps (user_id);
CREATE INDEX idx_password_reset_otps_email   ON password_reset_otps (email);

COMMIT;
