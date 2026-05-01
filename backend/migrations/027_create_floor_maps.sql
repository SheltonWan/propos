-- =============================================================================
-- Migration: 027_create_floor_maps
-- Description: 楼层结构标注（Floor Map v2）数据表
--   存储单楼层的语义结构（核心筒/电梯/楼梯/卫生间/设备间/走廊/柱位/窗洞），
--   支持 DXF 自动抽取候选 + 人工审核确认两阶段。同时为 floors 表增加渲染模式
--   与版本号字段，供前端切换 vector / semantic 渲染时的乐观锁与状态追踪。
--
-- 关联规范:
--   - docs/backend/FLOOR_MAP_API_SPEC.md
--   - docs/backend/schemas/floor_map.v2.schema.json
-- 依赖: 004_create_assets, 003_create_users_and_audit
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 楼层结构表（与 floors 1:1 关联）
-- -------------------------------------------------------------------------
CREATE TABLE floor_maps (
    -- 与 floors 1:1，floor 删除时级联清理
    floor_id                UUID         PRIMARY KEY REFERENCES floors(id) ON DELETE CASCADE,
    -- floor_map.v2.schema.json 的版本号，目前固定 '2.0'
    schema_version          VARCHAR(8)   NOT NULL DEFAULT '2.0',
    -- 视口尺寸 { width, height }，单位 SVG px
    viewport                JSONB,
    -- 外轮廓 { type: 'rect'|'polygon', rect?: {...}, points?: [[x,y],...] }
    outline                 JSONB,
    -- 已确认结构数组（人工审核后的 source='manual' 记录）
    structures              JSONB        NOT NULL DEFAULT '[]'::jsonb,
    -- 窗洞数组 [{ side, offset, width }]
    windows                 JSONB        NOT NULL DEFAULT '[]'::jsonb,
    -- 指北针 { x, y, rotation_deg? }
    north                   JSONB,
    -- DXF 抽取生成的候选结构（只读，供前端左侧候选清单）
    candidates              JSONB,
    -- 候选项最近一次抽取时间
    candidates_extracted_at TIMESTAMPTZ,
    -- 最近一次人工保存时间，作为乐观锁版本号（与 floors.floor_map_updated_at 同步更新）
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by              UUID         REFERENCES users(id)
);

CREATE INDEX idx_floor_maps_updated_at ON floor_maps(updated_at);

-- -------------------------------------------------------------------------
-- floors 表新增渲染模式与楼层结构元数据
-- -------------------------------------------------------------------------
ALTER TABLE floors
    -- 渲染模式：vector=矢量原图（默认）；semantic=按 floor_maps 语义渲染
    ADD COLUMN render_mode              VARCHAR(16) NOT NULL DEFAULT 'vector'
        CHECK (render_mode IN ('vector', 'semantic')),
    -- 当前 floor_maps 数据使用的 schema 版本号（保存后写入）
    ADD COLUMN floor_map_schema_version VARCHAR(8),
    -- floor_maps 最近一次保存时间，前端通过 ETag/If-Match 做乐观锁
    ADD COLUMN floor_map_updated_at     TIMESTAMPTZ;

COMMIT;
