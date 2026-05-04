"""共享 fixtures: 创建合成 DXF 文件供其他 detector 测试复用。

合成 fixture (synthetic_dxf): 运行时动态生成的最小化 DXF，不依赖外部文件。
真实 fixture (real_f17_dxf): 从 A座.dxf 提取的 F17 楼层区域，需先运行
    python -m scripts.floor_map.tests.make_fixtures
"""
from __future__ import annotations

import json
from pathlib import Path

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


@pytest.fixture(scope="session")
def real_f17_dxf():
    """F17 楼层真实 DXF fixture（从 A座.dxf 提取的区域切片）。

    若 fixture 文件不存在则跳过测试，需先运行：
        python -m scripts.floor_map.tests.make_fixtures

    Returns:
        tuple: (dxf_path: str, mapper: CoordinateMapper, meta: dict)
            - dxf_path: f17_region.dxf 绝对路径字符串
            - mapper: 由 F17 dxf_region + viewport 构建的坐标映射器
            - meta: A座_F17.json 原始元数据字典
    """
    from scripts.floor_map.coordinate_mapper import CoordinateMapper, Viewport

    fixture_path = Path(__file__).parent / "fixtures" / "f17_region.dxf"
    if not fixture_path.exists():
        pytest.skip(
            "f17_region.dxf 不存在，请先运行: "
            "python -m scripts.floor_map.tests.make_fixtures"
        )

    # 取项目根目录（scripts/floor_map/tests/ 的三级父目录）
    root = Path(__file__).parents[3]
    meta_path = root / "cad_intermediate" / "building_a" / "floors" / "A座_F17.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8"))

    r = meta["dxf_region"]
    vp = meta["viewport"]
    mapper = CoordinateMapper.from_bbox(
        r["min_x"],
        r["min_y"],
        r["max_x"],
        r["max_y"],
        viewport=Viewport(width=vp["width"], height=vp["height"]),
    )
    return str(fixture_path), mapper, meta
