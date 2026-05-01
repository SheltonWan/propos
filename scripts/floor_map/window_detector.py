"""window_detector — 从 DXF WINDOW 图层抽取窗户线段并归类到外墙四边。

策略:
    - 收集 WINDOW / 窗户分隔 等图层的 LINE / LWPOLYLINE 段
    - 对每段:
        * 计算长度(<8mm 在像素层面后会被服务层拒绝)
        * 计算中点
        * 与外墙 bbox 四边距离比较,归到最近一边: N(top)/S(bottom)/E(right)/W(left)
        * offset = 中点投影到该边起点的距离(像素), width = 段长度(像素)

输出元素结构(注意:schema 严格,不含 source 字段):
    {"side": "N|S|E|W", "offset": <px>, "width": <px>}
"""
from __future__ import annotations

import math
from typing import Iterable

import ezdxf

from .coordinate_mapper import CoordinateMapper, Point
from .layer_constants import WINDOW_LAYERS
from .outline_extractor import layer_normalize

DEFAULT_WINDOW_LAYERS = WINDOW_LAYERS


def _segment_length(p1: Point, p2: Point) -> float:
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])


def _midpoint(p1: Point, p2: Point) -> Point:
    return ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)


def detect_windows(
    dxf_path: str,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_WINDOW_LAYERS,
    min_length_mm: float = 200.0,
) -> list[dict]:
    """从 DXF 文件检测窗户。"""
    doc = ezdxf.readfile(dxf_path)
    return detect_windows_from_entities(doc.modelspace(), mapper, layers, min_length_mm)


def detect_windows_from_entities(
    entities,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_WINDOW_LAYERS,
    min_length_mm: float = 200.0,
) -> list[dict]:
    """从实体迭代器检测窗户。"""
    layer_set = {layer_normalize(name) for name in layers}

    raw_segments: list[tuple[Point, Point]] = []
    for entity in entities:
        layer_name = layer_normalize(entity.dxf.layer)
        if not any(layer_name == ln or layer_name.endswith("|" + ln) for ln in layer_set):
            continue
        etype = entity.dxftype()
        if etype == "LINE":
            p1 = (entity.dxf.start.x, entity.dxf.start.y)
            p2 = (entity.dxf.end.x, entity.dxf.end.y)
            if _segment_length(p1, p2) >= min_length_mm:
                raw_segments.append((p1, p2))
        elif etype == "LWPOLYLINE":
            pts = [(p[0], p[1]) for p in entity.get_points("xy")]
            for a, b in zip(pts, pts[1:]):
                if _segment_length(a, b) >= min_length_mm:
                    raw_segments.append((a, b))

    vp = mapper.viewport
    rect_left = vp.padding
    rect_right = vp.width - vp.padding
    rect_top = vp.padding
    rect_bottom = vp.height - vp.padding

    windows: list[dict] = []
    for a, b in raw_segments:
        pa = mapper.map_point(a)
        pb = mapper.map_point(b)
        length_px = _segment_length(pa, pb)
        if length_px < 8:
            continue
        mx, my = _midpoint(pa, pb)
        dist_to = {
            "N": abs(my - rect_top),
            "S": abs(my - rect_bottom),
            "W": abs(mx - rect_left),
            "E": abs(mx - rect_right),
        }
        side = min(dist_to, key=dist_to.get)
        if side in ("N", "S"):
            x_min = min(pa[0], pb[0])
            offset = max(0.0, x_min - rect_left)
            edge_len = rect_right - rect_left
        else:
            y_min = min(pa[1], pb[1])
            offset = max(0.0, y_min - rect_top)
            edge_len = rect_bottom - rect_top
        if offset + length_px > edge_len:
            length_px = max(8.0, edge_len - offset)
        windows.append(
            {
                "side": side,
                "offset": round(offset, 2),
                "width": round(length_px, 2),
            }
        )
    return windows
