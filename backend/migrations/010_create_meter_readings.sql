-- =============================================================================
-- Migration: 010_create_meter_readings
-- Description: 水电气抄表记录（v1.7 新增）
--   支持水/电/气三种表计、阶梯计价明细、公摊分摊。
--   抄表数据录入后自动生成对应水电费账单（关联 invoices）。
-- 依赖: 001, 003, 004, 007
-- =============================================================================

BEGIN;

CREATE TABLE meter_readings (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id          UUID          NOT NULL REFERENCES units(id),
    meter_type       meter_type    NOT NULL,              -- water / electricity / gas
    reading_cycle    reading_cycle NOT NULL DEFAULT 'monthly',
    -- 读数
    current_reading  NUMERIC(12,2) NOT NULL,              -- 本期读数
    previous_reading NUMERIC(12,2) NOT NULL,              -- 上期读数
    consumption      NUMERIC(12,2) NOT NULL,              -- 用量 = current - previous
    -- 计费
    unit_price       NUMERIC(10,4) NOT NULL,              -- 元/度 或 元/吨
    cost_amount      NUMERIC(12,2) NOT NULL,              -- 费用 = consumption × unit_price
    -- 阶梯计价明细（可选；格式：[{"from":0,"to":100,"price":0.5,"amount":50}, ...]）
    tiered_details   JSONB,
    -- 抄表信息
    reading_date     DATE          NOT NULL,
    recorded_by      UUID          REFERENCES users(id),
    -- 是否已生成账单
    invoice_generated BOOLEAN      NOT NULL DEFAULT FALSE,
    generated_invoice_id UUID      REFERENCES invoices(id),
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meter_unit      ON meter_readings(unit_id);
CREATE INDEX idx_meter_date      ON meter_readings(reading_date DESC);
CREATE INDEX idx_meter_type      ON meter_readings(meter_type);
-- 快速定位待生成账单的抄表记录
CREATE INDEX idx_meter_uninvoiced ON meter_readings(invoice_generated)
    WHERE invoice_generated = FALSE;

COMMIT;
