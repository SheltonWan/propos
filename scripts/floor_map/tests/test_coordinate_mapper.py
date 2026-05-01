"""coordinate_mapper 单元测试。"""
from __future__ import annotations

import pytest

from scripts.floor_map.coordinate_mapper import (
    CoordinateMapper,
    Viewport,
    compute_bbox,
)


def test_viewport_clamp():
    vp = Viewport(50, 5000).clamp()
    assert vp.width == 100
    assert vp.height == 4000


def test_mapper_y_axis_flipped():
    # DXF: bbox (0,0)-(100,100), viewport 1200x900 padding 20
    m = CoordinateMapper.from_bbox(0, 0, 100, 100)
    # DXF (0,100) [左上角] → 像素左上附近
    px, py = m.map_point((0, 100))
    # DXF (0,0) [左下角] → 像素左下附近
    px2, py2 = m.map_point((0, 0))
    assert py < py2  # 顶部 Y 像素值应小于底部


def test_mapper_centering():
    m = CoordinateMapper.from_bbox(0, 0, 100, 100)
    # 中心点 (50,50) → 像素中心
    px, py = m.map_point((50, 50))
    assert abs(px - 600) < 1
    assert abs(py - 450) < 1


def test_mapper_invalid_bbox():
    with pytest.raises(ValueError):
        CoordinateMapper.from_bbox(10, 10, 10, 20)
    with pytest.raises(ValueError):
        CoordinateMapper.from_bbox(10, 10, 20, 10)


def test_compute_bbox_empty():
    with pytest.raises(ValueError):
        compute_bbox([])


def test_compute_bbox_basic():
    bbox = compute_bbox([(0, 0), (10, 5), (-3, 8)])
    assert bbox == (-3, 0, 10, 8)


def test_map_length_uses_scale():
    m = CoordinateMapper.from_bbox(0, 0, 1000, 1000)
    # scale 取决于 viewport 与 bbox 比;此处只验证 1mm 长度被等比放大
    assert m.map_length(1) == round(m.scale, 2)
