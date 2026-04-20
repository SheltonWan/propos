-- =============================================================================
-- Migration: 009_create_deposits
-- Description: 押金管理
--   deposits（押金主表，状态流转）
--   deposit_transactions（押金交易流水：收取/冲抵/退还）
-- 依赖: 001, 003, 006
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 押金主表
-- -------------------------------------------------------------------------
CREATE TABLE deposits (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID            NOT NULL REFERENCES contracts(id),
    -- 应收押金总额（合同约定值）
    deposit_amount  NUMERIC(12,2)   NOT NULL CHECK (deposit_amount > 0),
    -- 实收押金（入账后更新）
    paid_amount     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    -- 已冲抵金额（应付账单扣减后更新）
    credited_amount NUMERIC(12,2)   NOT NULL DEFAULT 0,
    -- 已退还金额
    refunded_amount NUMERIC(12,2)   NOT NULL DEFAULT 0,
    -- 剩余余额（冗余，加速查询）
    balance         NUMERIC(12,2)   GENERATED ALWAYS AS
                    (paid_amount - credited_amount - refunded_amount) STORED,
    status          deposit_status  NOT NULL DEFAULT 'collected',
    -- 押金收取日期（首笔到账日）
    collected_date  DATE,
    -- 退款目标（银行账户信息，退款申请用）
    refund_bank_name     VARCHAR(100),
    refund_account_no    VARCHAR(100),
    refund_account_name  VARCHAR(100),
    refund_requested_at  TIMESTAMPTZ,
    refund_approved_by   UUID        REFERENCES users(id),
    refund_approved_at   TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_deposit_contract ON deposits(contract_id);
CREATE INDEX idx_deposits_status ON deposits(status);

-- -------------------------------------------------------------------------
-- 押金交易流水
-- -------------------------------------------------------------------------
CREATE TABLE deposit_transactions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    deposit_id      UUID        NOT NULL REFERENCES deposits(id),
    -- 交易类型：'collect'=收取, 'credit'=冲抵账单, 'refund'=退还
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('collect', 'credit', 'refund')),
    amount          NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    -- 冲抵账单时关联的账单（collect/refund 为 NULL）
    invoice_id      UUID        REFERENCES invoices(id),
    -- 退款时关联的银行流水
    bank_reference  VARCHAR(200),
    transaction_date DATE        NOT NULL,
    created_by      UUID        REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_deposit_txn_deposit ON deposit_transactions(deposit_id);
CREATE INDEX idx_deposit_txn_date    ON deposit_transactions(transaction_date DESC);

COMMIT;
