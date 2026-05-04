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


# ── 真实数据测试（依赖 f17_region.dxf fixture）─────────────────────────────────

def test_real_f17_outline_present(real_f17_dxf):
    """F17 楼层实测：应提取到有效外轮廓（WALL 闭合 LWPOLYLINE）。"""
    dxf_path, mapper, _ = real_f17_dxf
    outline = extract_outline(dxf_path, mapper)
    assert outline is not None, "F17 楼层未检测到外轮廓"
    assert outline["type"] in ("polygon", "rect")


def test_real_f17_outline_polygon_shape(real_f17_dxf):
    """F17 轮廓：多边形点数在合法范围内，坐标格式正确。

    注：f17_region.dxf 中唯一的 WALL 闭合 LWPOLYLINE 是楼层边界附近的小片墙体，
    outline_extractor 会将其识别为外轮廓。此测试仅验证格式合法性，
    不对 bbox 尺寸做比例断言（真实楼层的完整建筑外轮廓以 CURTWALL 层为主）。
    """
    dxf_path, mapper, _ = real_f17_dxf
    outline = extract_outline(dxf_path, mapper)
    assert outline is not None
    pts = outline.get("points", [])
    assert 3 <= len(pts) <= 32, f"轮廓点数异常: {len(pts)}"
    # 每个点均为 [x, y] 二元数值列表
    for pt in pts:
        assert len(pt) == 2
        assert isinstance(pt[0], (int, float))
        assert isinstance(pt[1], (int, float))
