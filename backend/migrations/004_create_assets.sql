-- =============================================================================
-- Migration: 004_create_assets
-- Description: 资产与空间可视化（M1 模块）
--   buildings → floors → floor_plans（楼层图纸）
--   buildings → floors → units（单元）
--   units → renovation_records（改造记录）
-- 依赖: 001, 003
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 楼栋
-- -------------------------------------------------------------------------
CREATE TABLE buildings (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)  NOT NULL,
    property_type   property_type NOT NULL,
    -- 地理位置
    address         TEXT          NOT NULL,
    city            VARCHAR(50)   NOT NULL DEFAULT '深圳市',
    -- 楼栋概况
    total_floors    SMALLINT      NOT NULL CHECK (total_floors > 0),
    -- 总建筑面积（m²），写字楼/商铺为 GFA，公寓含公摊
    gross_area      NUMERIC(10,2) NOT NULL CHECK (gross_area > 0),
    -- 总可租面积（m²），计算出租率分母
    leasable_area   NUMERIC(10,2) NOT NULL CHECK (leasable_area > 0),
    -- 建成年份（用于折旧、维保计划）
    year_built      SMALLINT,
    -- 楼栋封面图
    cover_image_path TEXT,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------------------
-- 楼层
-- -------------------------------------------------------------------------
CREATE TABLE floors (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID        NOT NULL REFERENCES buildings(id),
    -- 楼层号（可含负值：-1=地下1层）
    floor_number SMALLINT   NOT NULL,
    -- 楼层面积（m²，用于公摊分摊计算）
    floor_area  NUMERIC(10,2),
    -- 楼层名称（如 "B1" / "1F" / "M层"），为空时用楼层号
    label       VARCHAR(20),
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, floor_number)
);

CREATE INDEX idx_floors_building ON floors(building_id);

-- -------------------------------------------------------------------------
-- 楼层图纸（多版本 SVG/PNG，支持 CAD 转换结果存储）
-- -------------------------------------------------------------------------
CREATE TABLE floor_plans (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id    UUID        NOT NULL REFERENCES floors(id),
    version     SMALLINT    NOT NULL DEFAULT 1,
    -- 文件类型：'svg' / 'png'
    file_type   VARCHAR(10) NOT NULL DEFAULT 'svg',
    -- 存储路径：floors/{building_id}/{floor_id}.svg
    storage_path TEXT       NOT NULL,
    -- 是否为当前生效版本
    is_current  BOOLEAN     NOT NULL DEFAULT TRUE,
    -- 上传者
    uploaded_by UUID        REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_floor_plans_floor   ON floor_plans(floor_id);
CREATE INDEX idx_floor_plans_current ON floor_plans(floor_id, is_current)
    WHERE is_current = TRUE;

-- -------------------------------------------------------------------------
-- 单元（房间）
-- -------------------------------------------------------------------------
CREATE TABLE units (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id     UUID          NOT NULL REFERENCES buildings(id),
    floor_id        UUID          NOT NULL REFERENCES floors(id),
    -- 单元号（如 "A101" / "301" / "B1-05"）
    unit_no         VARCHAR(50)   NOT NULL,
    -- 建筑面积（m²，产权证面积）
    gross_area      NUMERIC(10,2) NOT NULL CHECK (gross_area > 0),
    -- 计租面积（m²，含分摊系数）
    billing_area    NUMERIC(10,2) NOT NULL CHECK (billing_area > 0),
    -- 标准使用面积（m²，供参考）
    net_area        NUMERIC(10,2),
    decoration      unit_decoration NOT NULL DEFAULT 'blank',
    status          unit_status     NOT NULL DEFAULT 'vacant',
    -- 市场参考单价（元/m²/月），用于估值及 KPI 基准
    market_rent_reference NUMERIC(8,2),
    -- 前任单元 ID 列表（切割或合并历史追溯）
    predecessor_unit_ids UUID[],
    -- 归档时间（改建/拆除后归档，不再参与出租率计算）
    archived_at     TIMESTAMPTZ,
    -- 楼层热区坐标（SVG 可点击区域，{x,y,width,height}）
    floor_plan_coords JSONB,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, floor_id, unit_no)
);

CREATE INDEX idx_units_building ON units(building_id);
CREATE INDEX idx_units_floor    ON units(floor_id);
CREATE INDEX idx_units_status   ON units(status);

-- -------------------------------------------------------------------------
-- 改造记录
-- -------------------------------------------------------------------------
CREATE TABLE renovation_records (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id      UUID        NOT NULL REFERENCES units(id),
    -- 改造类型：'renovation'=改造装修, 'maintenance'=日常维修, 'split'=拆分, 'merge'=合并
    record_type  VARCHAR(20) NOT NULL DEFAULT 'renovation',
    description  TEXT        NOT NULL,
    -- 改造费用（元）
    cost         NUMERIC(12,2),
    -- 改造期（对应 unit_status = renovating）
    start_date   DATE,
    end_date     DATE,
    -- 照片存储路径列表：renovations/{record_id}/{index}.jpg
    photo_paths  TEXT[],
    created_by   UUID        REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_renovation_unit ON renovation_records(unit_id);

COMMIT;
