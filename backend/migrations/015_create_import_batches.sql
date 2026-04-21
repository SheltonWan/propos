-- =============================================================================
-- Migration: 015_create_import_batches
-- Description: Excel 批量导入跟踪（v1.7 新增）
--   支持：试导入（仅校验）、部分导入（合同/账单）、整批回滚（单元台账）、
--         错误明细 JSONB 格式、批次状态追踪。
-- 依赖: 001, 003
-- =============================================================================

BEGIN;

CREATE TABLE import_batches (
    id              UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name      VARCHAR(200)           NOT NULL,   -- 导入批次名称/编号
    data_type       import_data_type       NOT NULL,   -- units / contracts / invoices
    total_records   INTEGER                NOT NULL,
    success_count   INTEGER                NOT NULL DEFAULT 0,
    failure_count   INTEGER                NOT NULL DEFAULT 0,
    rollback_status import_rollback_status NOT NULL DEFAULT 'committed',
    -- 错误明细（格式：[{"row":5,"field":"gross_area","error":"面积必须为正数"}, ...]）
    error_details   JSONB,
    -- 是否为试导入（仅校验不入库）
    is_dry_run      BOOLEAN                NOT NULL DEFAULT FALSE,
    -- 源文件存储路径
    source_file_path TEXT,
    created_by      UUID                   REFERENCES users(id),
    created_at      TIMESTAMPTZ            NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_import_batches_type   ON import_batches(data_type);
CREATE INDEX idx_import_batches_status ON import_batches(rollback_status);

COMMIT;
