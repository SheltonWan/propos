-- =============================================================================
-- PropOS 楼栋/楼层种子数据 — 3 栋综合体 × 24 层
-- 用途: 单元台账导入前置数据（buildings + floors）
-- 执行: psql -U propos -d propos -f scripts/seed_buildings_24f.sql
-- 幂等: 同名楼栋已存在则跳过插入，可重复执行
--
-- 重置说明（如需清空重导）：
--   DELETE FROM floors WHERE building_id IN (
--       SELECT id FROM buildings
--       WHERE name IN ('融创智汇大厦A座','融创智汇大厦B座','融创智汇大厦C座')
--   );
--   DELETE FROM buildings
--   WHERE name IN ('融创智汇大厦A座','融创智汇大厦B座','融创智汇大厦C座');
--
-- 业态说明:
--   buildings.property_type 仅作楼栋"主业态"标签（综合体需选一个主导业态）；
--   每个单元的实际业态以 units.property_type 为准（导入时可按行指定）。
-- =============================================================================

BEGIN;

DO $$
DECLARE
    -- 3 栋综合体（UUID 由数据库自动生成，运行时按 name 查回）
    v_bld_a UUID;
    v_bld_b UUID;
    v_bld_c UUID;

    v_floor_per_building CONSTANT SMALLINT := 24;
    v_gfa_per_floor      CONSTANT NUMERIC(10,2) := 600.00;  -- 单层建筑面积 m²
    v_nla_per_floor      CONSTANT NUMERIC(10,2) := 510.00;  -- 单层净可租面积 m²
    v_total_gfa          CONSTANT NUMERIC(10,2) := 14400.00; -- = 600 × 24
    v_total_nla          CONSTANT NUMERIC(10,2) := 12240.00; -- = 510 × 24

    rec RECORD;
    i SMALLINT;
BEGIN
    -- =====================================================================
    -- ① 楼栋（3 栋）
    -- =====================================================================
    -- 已存在同名楼栋则跳过
    IF NOT EXISTS (SELECT 1 FROM buildings WHERE name = '融创智汇大厦A座') THEN
        INSERT INTO buildings (name, property_type, total_floors, gfa, nla, address, built_year)
        VALUES ('融创智汇大厦A座', 'office', v_floor_per_building,
                v_total_gfa, v_total_nla, '深圳市南山区科技园', 2018)
        RETURNING id INTO v_bld_a;
        RAISE NOTICE '✓ 创建楼栋: 融创智汇大厦A座 (id=%)', v_bld_a;
    ELSE
        SELECT id INTO v_bld_a FROM buildings WHERE name = '融创智汇大厦A座';
        RAISE NOTICE '⊙ 楼栋已存在: 融创智汇大厦A座 (id=%)', v_bld_a;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM buildings WHERE name = '融创智汇大厦B座') THEN
        INSERT INTO buildings (name, property_type, total_floors, gfa, nla, address, built_year)
        VALUES ('融创智汇大厦B座', 'apartment', v_floor_per_building,
                v_total_gfa, v_total_nla, '深圳市南山区科技园', 2019)
        RETURNING id INTO v_bld_b;
        RAISE NOTICE '✓ 创建楼栋: 融创智汇大厦B座 (id=%)', v_bld_b;
    ELSE
        SELECT id INTO v_bld_b FROM buildings WHERE name = '融创智汇大厦B座';
        RAISE NOTICE '⊙ 楼栋已存在: 融创智汇大厦B座 (id=%)', v_bld_b;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM buildings WHERE name = '融创智汇大厦C座') THEN
        INSERT INTO buildings (name, property_type, total_floors, gfa, nla, address, built_year)
        VALUES ('融创智汇大厦C座', 'retail', v_floor_per_building,
                v_total_gfa, v_total_nla, '深圳市南山区科技园', 2020)
        RETURNING id INTO v_bld_c;
        RAISE NOTICE '✓ 创建楼栋: 融创智汇大厦C座 (id=%)', v_bld_c;
    ELSE
        SELECT id INTO v_bld_c FROM buildings WHERE name = '融创智汇大厦C座';
        RAISE NOTICE '⊙ 楼栋已存在: 融创智汇大厦C座 (id=%)', v_bld_c;
    END IF;

    -- =====================================================================
    -- ② 楼层（每栋 24 层：1F ~ 24F）
    -- 楼层 UNIQUE (building_id, floor_number)，重复执行自动跳过
    -- =====================================================================
    FOR rec IN SELECT unnest(ARRAY[v_bld_a, v_bld_b, v_bld_c]) AS bid LOOP
        FOR i IN 1..v_floor_per_building LOOP
            INSERT INTO floors (building_id, floor_number, floor_name, nla)
            VALUES (rec.bid, i, i::TEXT || 'F', v_nla_per_floor)
            ON CONFLICT (building_id, floor_number) DO NOTHING;
        END LOOP;
    END LOOP;

    RAISE NOTICE '✓ 楼层数据写入完成（每栋 24 层，共 72 层）';
END $$;

COMMIT;

-- =============================================================================
-- 验证查询（执行后请人工核对结果）
-- =============================================================================
SELECT
    b.name        AS 楼栋名称,
    b.property_type::TEXT AS 主业态,
    b.total_floors AS 总层数,
    COUNT(f.id)   AS 已建楼层数,
    b.gfa         AS 建筑面积,
    b.nla         AS 净可租面积
FROM buildings b
LEFT JOIN floors f ON f.building_id = b.id
WHERE b.name LIKE '融创智汇大厦%'
GROUP BY b.id, b.name, b.property_type, b.total_floors, b.gfa, b.nla
ORDER BY b.name;
