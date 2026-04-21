-- =============================================================================
-- Migration: 018_create_notifications
-- Description: 站内通知 + 催收记录（v1.7 新增）
--   notifications：按角色/用户推送、已读未读、关联资源跳转
--   dunning_logs：逾期账单催收过程记录（多方式，多结果）
-- 依赖: 001, 003, 007
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 站内通知
-- -------------------------------------------------------------------------
CREATE TABLE notifications (
    id            UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 接收用户（ON DELETE CASCADE 确保用户删除时通知一并清理）
    user_id       UUID                  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type          notification_type     NOT NULL,
    severity      notification_severity NOT NULL DEFAULT 'info',
    title         VARCHAR(200)          NOT NULL,
    content       TEXT                  NOT NULL,
    is_read       BOOLEAN               NOT NULL DEFAULT FALSE,
    -- 关联资源（用于前端跳转，如 contract / invoice / workorder 等）
    resource_type VARCHAR(50),
    resource_id   UUID,
    created_at    TIMESTAMPTZ           NOT NULL DEFAULT NOW()
);

-- 未读通知快速检索（最高频查询）
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read)
    WHERE is_read = FALSE;
CREATE INDEX idx_notifications_user_time   ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_type        ON notifications(type);

-- -------------------------------------------------------------------------
-- 催收记录
-- -------------------------------------------------------------------------
CREATE TABLE dunning_logs (
    id            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 催收关联账单（ON DELETE CASCADE 确保账单撤销时日志一并删除）
    invoice_id    UUID            NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    method        dunning_method  NOT NULL,
    content       TEXT            NOT NULL,   -- 催收内容摘要
    result        TEXT,                       -- 催收结果/回复
    dunning_date  DATE            NOT NULL,
    created_by    UUID            NOT NULL REFERENCES users(id),
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dunning_logs_invoice ON dunning_logs(invoice_id);
CREATE INDEX idx_dunning_logs_date    ON dunning_logs(dunning_date);

COMMIT;
