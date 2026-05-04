"""window_detector 单元测试。"""
from __future__ import annotations

from scripts.floor_map.coordinate_mapper import CoordinateMapper
from scripts.floor_map.window_detector import detect_windows


def test_detect_windows_finds_four_sides(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    windows = detect_windows(synthetic_dxf, mapper)
    assert len(windows) == 4
    sides = sorted(w["side"] for w in windows)
    assert sides == ["E", "N", "S", "W"]


def test_detect_windows_no_source_field(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    windows = detect_windows(synthetic_dxf, mapper)
    for w in windows:
        assert "source" not in w
        assert set(w.keys()) == {"side", "offset", "width"}


def test_detect_windows_min_length_filter(synthetic_dxf):
    mapper = CoordinateMapper.from_bbox(0, 0, 1000, 800)
    # 调到 5000mm,所有 400mm 长窗段全被过滤
    windows = detect_windows(synthetic_dxf, mapper, min_length_mm=5000.0)
    assert windows == []


# ── 真实数据测试（依赖 f17_region.dxf fixture）─────────────────────────────────

def test_real_f17_window_count(real_f17_dxf):
    """F17 楼层实测：应检测到 ≥15 扇窗（实际约 24 扇，WINDOW 层）。"""
    dxf_path, mapper, _ = real_f17_dxf
    wins = detect_windows(dxf_path, mapper)
    assert len(wins) >= 15, f"期望 ≥15 扇窗，实际: {len(wins)}"


def test_real_f17_window_schema(real_f17_dxf):
    """F17 窗：每个结果字段完整，offset/width 均为正数。"""
    dxf_path, mapper, _ = real_f17_dxf
    wins = detect_windows(dxf_path, mapper)
    valid_sides = {"N", "S", "E", "W"}
    for w in wins:
        assert set(w.keys()) == {"side", "offset", "width"}
        assert w["side"] in valid_sides, f"非法方位: {w['side']}"
        assert w["offset"] >= 0, f"offset 不能为负: {w['offset']}"
        assert w["width"] > 0, f"width 必须为正: {w['width']}"


def test_real_f17_window_sides_present(real_f17_dxf):
    """F17 楼层：至少 N/S 两侧有窗（实测 WINDOW 层有两侧分布）。"""
    dxf_path, mapper, _ = real_f17_dxf
    wins = detect_windows(dxf_path, mapper)
    sides = {w["side"] for w in wins}
    assert len(sides) >= 2, f"期望 ≥2 侧有窗，实际: {sides}"
