-- =============================================================================
-- Migration: 026_create_cad_import_jobs
-- Description: 楼栋级 CAD（DXF）导入任务表
--   支持 admin 上传整栋 DXF → 后端调用 split_dxf_by_floor.py 切分 → 自动匹配楼层 →
--   未匹配 SVG 写入 unmatched_svgs，由管理员后续手动指派。
--
--   状态机：uploaded → splitting → done | failed
--   - uploaded ：DXF 已落盘但切分任务尚未启动
--   - splitting：切分进程运行中
--   - done     ：切分完成（无论是否全部楼层都匹配上）
--   - failed   ：切分进程退出码非 0 / 抛出异常
-- 依赖: 004_create_assets, 003_create_users_and_audit
-- =============================================================================

BEGIN;

CREATE TABLE cad_import_jobs (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id     UUID         NOT NULL REFERENCES buildings(id),
    -- 任务状态机；CHECK 约束确保只能取以下四个值
    status          VARCHAR(20)  NOT NULL DEFAULT 'uploaded'
                    CHECK (status IN ('uploaded', 'splitting', 'done', 'failed')),
    -- 上传后落盘的原始 DXF 相对路径：cad/{building_id}/{job_id}.dxf
    dxf_path        TEXT         NOT NULL,
    -- 切分脚本输出 SVG 文件名前缀（默认从原始文件名推断）
    prefix          VARCHAR(100) NOT NULL,
    -- 自动匹配到 floors 表的 SVG 数量
    matched_count   INTEGER      NOT NULL DEFAULT 0,
    -- 未匹配 SVG 列表，格式：[{"label":"F11","tmp_path":"cad/.../<prefix>_F11.svg"}, ...]
    unmatched_svgs  JSONB        NOT NULL DEFAULT '[]'::jsonb,
    -- 失败时的错误描述（status='failed' 时填充）
    error_message   TEXT,
    created_by      UUID         REFERENCES users(id),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cad_import_jobs_building ON cad_import_jobs(building_id);
CREATE INDEX idx_cad_import_jobs_status   ON cad_import_jobs(status);

COMMIT;
