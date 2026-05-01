"""共享 fixtures: 创建合成 DXF 文件供其他 detector 测试复用。"""
from __future__ import annotations

import ezdxf
import pytest


@pytest.fixture
def synthetic_dxf(tmp_path):
    """创建包含外轮廓 + 4 根柱 + 4 个窗的最小 DXF 文件。"""
    doc = ezdxf.new(dxfversion="R2010")
    msp = doc.modelspace()

    # 1) 外轮廓: 1000x800 矩形 (mm) 在 WALL 图层
    doc.layers.new(name="WALL")
    msp.add_lwpolyline(
        [(0, 0), (1000, 0), (1000, 800), (0, 800)],
        dxfattribs={"layer": "WALL"},
        close=True,
    )

    # 2) 柱: 4 根 200×200 闭合多段线在 '柱网' 图层
    doc.layers.new(name="柱网")
    column_centers = [(100, 100), (900, 100), (100, 700), (900, 700)]
    for cx, cy in column_centers:
        msp.add_lwpolyline(
            [
                (cx - 100, cy - 100),
                (cx + 100, cy - 100),
                (cx + 100, cy + 100),
                (cx - 100, cy + 100),
            ],
            dxfattribs={"layer": "柱网"},
            close=True,
        )

    # 3) 窗: 4 条 LINE 段贴近外墙四边
    doc.layers.new(name="WINDOW")
    msp.add_line((300, 800), (700, 800), dxfattribs={"layer": "WINDOW"})  # N
    msp.add_line((300, 0), (700, 0), dxfattribs={"layer": "WINDOW"})      # S
    msp.add_line((0, 200), (0, 600), dxfattribs={"layer": "WINDOW"})      # W
    msp.add_line((1000, 200), (1000, 600), dxfattribs={"layer": "WINDOW"})  # E

    path = tmp_path / "synthetic.dxf"
    doc.saveas(path)
    return str(path)
