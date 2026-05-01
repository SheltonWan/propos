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
