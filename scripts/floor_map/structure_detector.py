"""structure_detector — 编排器:从 DXF 抽取候选结构并组装为 Floor Map v2 JSON。

输出符合 docs/backend/schemas/floor_map.v2.schema.json 的 candidates 子集:
    {
        "schema_version": "2.0",
        "viewport": {"width": 1200, "height": 900},
        "outline": {...} | None,
        "structures": [...],     # source='auto' 的柱/楼梯/电梯等
        "windows": [...]         # 不含 source 字段
    }

注意:本编排器仅产出柱(column)与窗(window)的候选,以及外轮廓(outline);
其他结构类型(core/elevator/stair/restroom/equipment/corridor)需在后续迭代中
逐步添加图层规则。当前优先保证可用性,先解决能从 DXF 直接拿到的几何特征。
"""
from __future__ import annotations

import ezdxf

from .column_detector import detect_columns, detect_columns_from_entities
from .coordinate_mapper import CoordinateMapper, Viewport, compute_bbox
from .outline_extractor import extract_outline, extract_outline_from_entities
from .window_detector import detect_windows, detect_windows_from_entities


def _msp_bbox(dxf_path: str) -> tuple[float, float, float, float]:
    """计算 modelspace 内所有可见实体的边界框。"""
    doc = ezdxf.readfile(dxf_path)
    msp = doc.modelspace()
    points: list[tuple[float, float]] = []
    for entity in msp:
        try:
            etype = entity.dxftype()
            if etype == "LINE":
                points.append((entity.dxf.start.x, entity.dxf.start.y))
                points.append((entity.dxf.end.x, entity.dxf.end.y))
            elif etype == "LWPOLYLINE":
                points.extend([(p[0], p[1]) for p in entity.get_points("xy")])
            elif etype == "POLYLINE":
                points.extend(
                    [(v.dxf.location.x, v.dxf.location.y) for v in entity.vertices]
                )
            elif etype == "CIRCLE":
                cx, cy, r = entity.dxf.center.x, entity.dxf.center.y, entity.dxf.radius
                points.extend([(cx - r, cy - r), (cx + r, cy + r)])
        except Exception:  # noqa: BLE001 — 容错跳过
            continue
    if not points:
        raise ValueError("DXF 中未找到任何可定位实体")
    return compute_bbox(points)


def extract_candidates(
    dxf_path: str,
    viewport: Viewport | None = None,
) -> dict:
    """从 DXF 文件抽取候选结构,返回 Floor Map v2 候选 JSON。"""
    bbox = _msp_bbox(dxf_path)
    mapper = CoordinateMapper.from_bbox(*bbox, viewport=viewport)

    outline = extract_outline(dxf_path, mapper)
    columns = detect_columns(dxf_path, mapper)
    windows = detect_windows(dxf_path, mapper)

    return _assemble(mapper, outline, columns, windows)


def extract_candidates_from_entities(
    entities: list,
    bbox: tuple[float, float, float, float],
    viewport: Viewport | None = None,
) -> dict:
    """从内存实体列表抽取候选结构（供 split_dxf_by_floor.py 调用）。

    调用方负责提供已过滤的实体列表与其包围盒。
    """
    if bbox[2] <= bbox[0] or bbox[3] <= bbox[1]:
        raise ValueError("非法包围盒")
    mapper = CoordinateMapper.from_bbox(*bbox, viewport=viewport)
    outline = extract_outline_from_entities(entities, mapper)
    columns = detect_columns_from_entities(entities, mapper)
    windows = detect_windows_from_entities(entities, mapper)
    return _assemble(mapper, outline, columns, windows)


def _assemble(mapper: CoordinateMapper, outline, columns, windows) -> dict:
    return {
        "schema_version": "2.0",
        "viewport": {
            "width": mapper.viewport.width,
            "height": mapper.viewport.height,
        },
        "outline": outline,
        "structures": columns,
        "windows": windows,
    }
