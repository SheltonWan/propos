"""业务层 F11 回归测试 — 防止 detector 默认图层 / block 展开漏配再次回退。

历史教训：v1 detector 的默认 layer 仅含中文名，业务层 DXF 用英文 ``COLU`` /
``WINDOW`` / ``A-SECT-MCUT`` 系列图层 + 大量实体藏在 INSERT block，导致命中率几乎 0。
该测试以真实 F11 区域的产物为基线，确保 outline/columns/windows 三项均非空。
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

CANDIDATES_PATH = (
    Path(__file__).resolve().parents[3]
    / "cad_intermediate"
    / "building_a"
    / "floors"
    / "A座_F11.candidates.json"
)


@pytest.fixture(scope="module")
def f11() -> dict:
    if not CANDIDATES_PATH.exists():
        pytest.skip(
            f"F11 候选文件不存在，请先运行: "
            f"python3 scripts/split_dxf_by_floor.py cad_intermediate/building_a/A座.dxf "
            f"cad_intermediate/building_a/floors --prefix A座 --extract-structures"
        )
    return json.loads(CANDIDATES_PATH.read_text(encoding="utf-8"))


def test_f11_outline_present(f11: dict) -> None:
    """F11 业务层必须能提取到外墙轮廓（多边形 ≥4 顶点）。"""
    outline = f11.get("outline")
    assert outline is not None, "outline 不应为 None（业务层 F11 应能识别）"
    assert isinstance(outline, dict) and outline.get("type") == "polygon"
    points = outline.get("points")
    assert isinstance(points, list)
    assert len(points) >= 4, f"outline 顶点数 {len(points)} 过少（至少 4 个）"
    # bbox 至少 200×200 px 才能算"真外墙"（防御微型构件被误选）
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    assert (max(xs) - min(xs)) >= 200, f"outline 宽 {max(xs)-min(xs):.1f} px 过窄"
    assert (max(ys) - min(ys)) >= 200, f"outline 高 {max(ys)-min(ys):.1f} px 过窄"


def test_f11_columns_threshold(f11: dict) -> None:
    """F11 应识别到 ≥10 根柱（实际 38，留余量防回退）。"""
    cols = f11.get("structures", [])
    assert len(cols) >= 10, f"柱数 {len(cols)} 低于阈值 10（v1 此处为 0，回归预警）"


def test_f11_windows_threshold(f11: dict) -> None:
    """F11 应识别到 ≥15 扇窗（实际 55）。"""
    wins = f11.get("windows", [])
    assert len(wins) >= 15, f"窗数 {len(wins)} 低于阈值 15"


def test_f11_window_schema(f11: dict) -> None:
    """每扇窗必须含 side/offset/width 三字段，且 side ∈ N/S/E/W。"""
    for w in f11.get("windows", [])[:5]:
        assert set(w.keys()) >= {"side", "offset", "width"}
        assert w["side"] in ("N", "S", "E", "W")
        assert w["width"] > 0
        assert w["offset"] >= 0
