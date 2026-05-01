"""outline_extractor 单元测试。"""
from __future__ import annotations

from scripts.floor_map.coordinate_mapper import CoordinateMapper
from scripts.floor_map.outline_extractor import (
    extract_outline,
    simplify_to_max,
)


def test_extract_outline_returns_polygon(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    outline = extract_outline(synthetic_dxf, mapper)
    assert outline is not None
    assert outline["type"] == "polygon"
    assert 3 <= len(outline["points"]) <= 32


def test_simplify_to_max_caps_length():
    pts = [(i, (i * 3) % 50) for i in range(80)]
    result = simplify_to_max(pts, max_points=20)
    assert len(result) <= 20


def test_simplify_to_max_passthrough():
    pts = [(0, 0), (10, 0), (10, 10)]
    assert simplify_to_max(pts, max_points=32) == pts


def test_extract_outline_returns_none_when_no_layer(tmp_path):
    import ezdxf

    doc = ezdxf.new(dxfversion="R2010")
    msp = doc.modelspace()
    msp.add_line((0, 0), (10, 10))
    p = tmp_path / "empty.dxf"
    doc.saveas(p)

    mapper = CoordinateMapper.from_bbox(0, 0, 10, 10)
    assert extract_outline(str(p), mapper) is None
