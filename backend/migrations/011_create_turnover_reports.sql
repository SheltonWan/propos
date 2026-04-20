-- =============================================================================
-- Migration: 011_create_turnover_reports
-- Description: 商铺营业额申报（v1.7 新增）
--   支持月度申报、审核、差额补单、补报/修正历史追踪。
--   同一合同同一月份仅允许一条非补报（is_amendment = FALSE）的正式记录。
-- 依赖: 001, 003, 006, 007
-- =============================================================================

BEGIN;

CREATE TABLE turnover_reports (
    id                 UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id        UUID                     NOT NULL REFERENCES contracts(id),
    -- 申报月份（统一对齐到 yyyy-mm-01）
    report_month       DATE                     NOT NULL,
    -- 营业额数据
    reported_revenue   NUMERIC(12,2)            NOT NULL,  -- 商户申报营业额（元）
    revenue_share_rate NUMERIC(5,4)             NOT NULL,  -- 分成比例
    base_rent          NUMERIC(12,2)            NOT NULL,  -- 保底租金（元）
    -- 计算分成额 = MAX(reported_revenue × rate - base_rent, 0)
    calculated_share   NUMERIC(12,2)            NOT NULL,
    -- 审核
    approval_status    turnover_approval_status NOT NULL DEFAULT 'pending',
    reviewed_by        UUID                     REFERENCES users(id),
    reviewed_at        TIMESTAMPTZ,
    rejection_reason   TEXT,
    -- 附件（POS 流水或审计报表）：TEXT 数组存多个路径
    attachment_paths   TEXT[],
    -- 补报/修正标识
    is_amendment       BOOLEAN                  NOT NULL DEFAULT FALSE,
    -- 补报时关联原始申报记录
    original_report_id UUID                     REFERENCES turnover_reports(id),
    -- 自动生成的账单
    generated_invoice_id UUID                   REFERENCES invoices(id),
    -- 争议处理记录
    dispute_note       TEXT,
    submitted_by       UUID                     REFERENCES users(id),
    created_at         TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ              NOT NULL DEFAULT NOW()
);

-- 同一合同同一月份仅一条正式申报（补报记录不受此约束）
CREATE UNIQUE INDEX uq_turnover_original
    ON turnover_reports(contract_id, report_month)
    WHERE is_amendment = FALSE;

CREATE INDEX idx_turnover_contract ON turnover_reports(contract_id);
CREATE INDEX idx_turnover_month    ON turnover_reports(report_month);
CREATE INDEX idx_turnover_status   ON turnover_reports(approval_status);

COMMIT;
