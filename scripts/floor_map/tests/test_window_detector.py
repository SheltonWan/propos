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
