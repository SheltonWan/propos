"""column_detector 单元测试。"""
from __future__ import annotations

from scripts.floor_map.column_detector import detect_columns
from scripts.floor_map.coordinate_mapper import CoordinateMapper


def test_detect_columns_finds_four(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    cols = detect_columns(synthetic_dxf, mapper)
    assert len(cols) == 4
    for c in cols:
        assert c["type"] == "column"
        assert c["source"] == "auto"
        assert isinstance(c["point"], list) and len(c["point"]) == 2


def test_detect_columns_filters_too_small(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    # 把阈值调到 1000mm,合成的 200×200 柱将全被过滤
    cols = detect_columns(synthetic_dxf, mapper, min_size_mm=1000.0)
    assert cols == []


def test_detect_columns_uses_custom_layers(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    # 指定不存在的图层 → 0 个柱
    cols = detect_columns(synthetic_dxf, mapper, layers=("不存在的层",))
    assert cols == []


# ── 真实数据测试（依赖 f17_region.dxf fixture）─────────────────────────────────

def test_real_f17_column_count(real_f17_dxf):
    """F17 楼层实测：应检测到 ≥15 根柱（实际约 22 根，COLU LWPOLYLINE 层）。"""
    dxf_path, mapper, _ = real_f17_dxf
    cols = detect_columns(dxf_path, mapper)
    assert len(cols) >= 15, f"期望 ≥15 根柱，实际: {len(cols)}"


def test_real_f17_column_schema(real_f17_dxf):
    """F17 柱：每个结果必须包含正确字段且坐标在视口范围内。"""
    dxf_path, mapper, meta = real_f17_dxf
    cols = detect_columns(dxf_path, mapper)
    vw = meta["viewport"]["width"]
    vh = meta["viewport"]["height"]
    for c in cols:
        assert c["type"] == "column"
        assert c["source"] == "auto"
        px, py = c["point"]
        assert 0 <= px <= vw, f"柱 x={px} 超出视口宽度 {vw}"
        assert 0 <= py <= vh, f"柱 y={py} 超出视口高度 {vh}"
