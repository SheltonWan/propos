-- =============================================================================
-- Migration: 012_create_subleases
-- Description: 二房东穿透管理（M5 模块）
--   行级隔离：sublease_repository 所有查询必须附加
--     master_contract_id IN (SELECT id FROM contracts WHERE tenant_id = $sub_landlord_tenant_id)
--   加密字段：sub_tenant_id_number_encrypted / sub_tenant_phone_encrypted（AES-256-GCM）
--   PIPL 合规：data_retention_until（租约终止后保留 ≤ 3 年）
-- 依赖: 001, 003, 004, 006
-- =============================================================================

BEGIN;

CREATE TABLE subleases (
    id                          UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 关联二房东的主合同（is_sublease_master = TRUE）
    master_contract_id          UUID                      NOT NULL REFERENCES contracts(id),
    -- 转租单元（必须在主合同覆盖面积范围内，Service 层校验）
    unit_id                     UUID                      NOT NULL REFERENCES units(id),
    -- 终端租客信息
    sub_tenant_name             VARCHAR(200)              NOT NULL,
    sub_tenant_type             tenant_type               NOT NULL DEFAULT 'corporate',
    sub_tenant_contact_person   VARCHAR(100),
    -- [加密存储] 终端租客证件号
    sub_tenant_id_number_encrypted TEXT,                            -- 加密：AES-256-GCM
    -- [加密存储] 终端租客联系电话
    sub_tenant_phone_encrypted  TEXT,                               -- 加密：AES-256-GCM
    -- 子租赁期限
    start_date                  DATE                      NOT NULL,
    end_date                    DATE                      NOT NULL,
    -- 月租金（终端租客支付给二房东的价格，元）
    monthly_rent                NUMERIC(12,2)             NOT NULL,
    -- 单价（元/m²/月），由 Service 层根据 unit.billing_area 反算，存储供查询
    rent_per_sqm                NUMERIC(8,4),
    -- 入住状态
    occupancy_status            sublease_occupancy_status NOT NULL DEFAULT 'occupied',
    -- 公寓实际入住人数
    occupant_count              SMALLINT,
    -- 审核流程
    review_status               sublease_review_status    NOT NULL DEFAULT 'pending',
    reviewer_user_id            UUID                      REFERENCES users(id),
    reviewed_at                 TIMESTAMPTZ,
    rejection_reason            TEXT,
    version_no                  INTEGER                   NOT NULL DEFAULT 1,
    -- 申报月份（用于对账）
    declared_for_month          DATE,
    -- 填报渠道：internal=内部录入, sub_landlord=二房东自助, excel_import=批量导入
    submission_channel          VARCHAR(20)               NOT NULL DEFAULT 'internal',
    submitted_by_user_id        UUID                      REFERENCES users(id),
    submitted_at                TIMESTAMPTZ,
    truth_declared_at           TIMESTAMPTZ,
    notes                       TEXT,
    -- PIPL：个人信息保留截止时间（终止后 ≤ 3 年）
    data_retention_until        TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sublease_dates CHECK (start_date <= end_date)
);

-- 同一单元同一时间只允许一条已审核的在租或已签约记录
CREATE UNIQUE INDEX uq_sublease_active_unit
    ON subleases(unit_id)
    WHERE occupancy_status IN ('occupied', 'signed_not_moved')
      AND review_status = 'approved';

CREATE INDEX idx_subleases_master_contract ON subleases(master_contract_id);
CREATE INDEX idx_subleases_unit            ON subleases(unit_id);
CREATE INDEX idx_subleases_review_status   ON subleases(review_status);
CREATE INDEX idx_subleases_occupancy       ON subleases(occupancy_status);

COMMIT;
