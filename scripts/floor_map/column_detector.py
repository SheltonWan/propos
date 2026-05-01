"""column_detector — 从 DXF 柱图层抽取柱位点。

策略:
    - 收集柱图层(默认 '柱网' / '柱墙填充' / '屋顶柱')上的闭合多段线 / HATCH 边界
    - 取每个闭合形状的几何中心(centroid)作为柱位点
    - 通过最小尺寸阈值过滤误识别(默认 ≥ 100mm 边长)
    - 输出 source='auto', type='column' 的候选 structure 列表

输出元素结构:
    {"type": "column", "source": "auto", "point": [x_px, y_px]}
"""
from __future__ import annotations

from typing import Iterable

import ezdxf

from .coordinate_mapper import CoordinateMapper, Point
from .layer_constants import COLUMN_LAYERS
from .outline_extractor import layer_normalize

DEFAULT_COLUMN_LAYERS = COLUMN_LAYERS


def _polygon_centroid(pts: list[Point]) -> Point:
    """简单算术中心(对柱子矩形足够;不要求严格几何中心)。"""
    if not pts:
        raise ValueError("空多边形")
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return (sum(xs) / len(xs), sum(ys) / len(ys))


def _bbox_size(pts: list[Point]) -> tuple[float, float]:
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return (max(xs) - min(xs), max(ys) - min(ys))


def detect_columns(
    dxf_path: str,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_COLUMN_LAYERS,
    min_size_mm: float = 100.0,
) -> list[dict]:
    """从 DXF 文件检测柱位。"""
    doc = ezdxf.readfile(dxf_path)
    return detect_columns_from_entities(doc.modelspace(), mapper, layers, min_size_mm)


def detect_columns_from_entities(
    entities,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_COLUMN_LAYERS,
    min_size_mm: float = 100.0,
) -> list[dict]:
    """从实体迭代器检测柱位。"""
    layer_set = {layer_normalize(name) for name in layers}
    centers_dxf: list[Point] = []

    for entity in entities:
        layer_name = layer_normalize(entity.dxf.layer)
        if not any(layer_name == ln or layer_name.endswith("|" + ln) for ln in layer_set):
            continue
        pts: list[Point] = []
        etype = entity.dxftype()
        if etype == "LWPOLYLINE" and entity.closed:
            pts = [(p[0], p[1]) for p in entity.get_points("xy")]
        elif etype == "POLYLINE" and getattr(entity, "is_closed", False):
            pts = [(v.dxf.location.x, v.dxf.location.y) for v in entity.vertices]
        elif etype == "HATCH":
            try:
                for path in entity.paths:
                    bpts = [(v[0], v[1]) for v in path.vertices()]
                    if len(bpts) >= 3:
                        pts = bpts
                        break
            except Exception:  # noqa: BLE001
                continue
        if len(pts) < 3:
            continue
        w, h = _bbox_size(pts)
        if w < min_size_mm or h < min_size_mm:
            continue
        centers_dxf.append(_polygon_centroid(pts))

    deduped: list[Point] = []
    for c in centers_dxf:
        if not any(((c[0] - d[0]) ** 2 + (c[1] - d[1]) ** 2) ** 0.5 < 50 for d in deduped):
            deduped.append(c)

    return [
        {
            "type": "column",
            "source": "auto",
            "point": list(mapper.map_point(c)),
        }
        for c in deduped
    ]
