"""outline_extractor — 提取楼层外轮廓。

策略:
    1. 在外墙图层(默认 WALL/0-WALL/CURTWALL/0muqiang)中收集所有 LWPOLYLINE / POLYLINE
    2. 若存在闭合多段线,选包围盒面积最大的作为外轮廓
    3. 否则取所有线段并集后的凸包(降级方案)
    4. 简化:点数 > 32 则用 Douglas-Peucker 抽样到 ≤ 32

输出:
    {"type": "polygon", "points": [[x,y], ...]} 或 {"type": "rect", "rect": {...}}
"""
from __future__ import annotations

from typing import Iterable

import ezdxf

from .coordinate_mapper import CoordinateMapper, Point, compute_bbox

DEFAULT_OUTLINE_LAYERS = (
    "WALL",
    "0-WALL",
    "CURTWALL",
    "0muqiang",
)


def _collect_closed_polylines(
    entities, layers: Iterable[str]
) -> list[list[Point]]:
    """从实体迭代器中收集指定图层的闭合多段线点列表。"""
    layer_set = {layer_normalize(name) for name in layers}
    polylines: list[list[Point]] = []
    for entity in entities:
        layer_name = layer_normalize(entity.dxf.layer)
        if not any(layer_name == ln or layer_name.endswith("|" + ln) for ln in layer_set):
            continue
        pts: list[Point] = []
        if entity.dxftype() == "LWPOLYLINE":
            if not entity.closed:
                continue
            pts = [(p[0], p[1]) for p in entity.get_points("xy")]
        elif entity.dxftype() == "POLYLINE":
            if not entity.is_closed:
                continue
            pts = [(v.dxf.location.x, v.dxf.location.y) for v in entity.vertices]
        if len(pts) >= 3:
            polylines.append(pts)
    return polylines


def layer_normalize(name: str) -> str:
    """图层名归一化(去前缀分隔符等)。"""
    return name.strip()


def _bbox_area(pts: list[Point]) -> float:
    if not pts:
        return 0.0
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return (max(xs) - min(xs)) * (max(ys) - min(ys))


def _douglas_peucker(points: list[Point], epsilon: float) -> list[Point]:
    """简化轮廓到不超过 max_points 个点。"""
    if len(points) < 3:
        return points

    def perpendicular_distance(pt: Point, start: Point, end: Point) -> float:
        x0, y0 = pt
        x1, y1 = start
        x2, y2 = end
        dx = x2 - x1
        dy = y2 - y1
        if dx == 0 and dy == 0:
            return ((x0 - x1) ** 2 + (y0 - y1) ** 2) ** 0.5
        t = ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy)
        proj_x = x1 + t * dx
        proj_y = y1 + t * dy
        return ((x0 - proj_x) ** 2 + (y0 - proj_y) ** 2) ** 0.5

    dmax = 0.0
    index = 0
    for i in range(1, len(points) - 1):
        d = perpendicular_distance(points[i], points[0], points[-1])
        if d > dmax:
            index = i
            dmax = d
    if dmax > epsilon:
        left = _douglas_peucker(points[: index + 1], epsilon)
        right = _douglas_peucker(points[index:], epsilon)
        return left[:-1] + right
    return [points[0], points[-1]]


def simplify_to_max(points: list[Point], max_points: int = 32) -> list[Point]:
    """将点序列简化到 ≤ max_points;通过递增 epsilon 二分。"""
    if len(points) <= max_points:
        return points
    bbox = compute_bbox(points)
    diag = ((bbox[2] - bbox[0]) ** 2 + (bbox[3] - bbox[1]) ** 2) ** 0.5
    lo, hi = 0.0, diag
    result = points
    for _ in range(20):
        mid = (lo + hi) / 2
        simplified = _douglas_peucker(points, mid)
        if len(simplified) <= max_points:
            result = simplified
            hi = mid
        else:
            lo = mid
    return result


def extract_outline(
    dxf_path: str,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_OUTLINE_LAYERS,
) -> dict | None:
    """从 DXF 文件抽取外轮廓。"""
    doc = ezdxf.readfile(dxf_path)
    return extract_outline_from_entities(doc.modelspace(), mapper, layers)


def extract_outline_from_entities(
    entities,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_OUTLINE_LAYERS,
) -> dict | None:
    """从实体迭代器抽取外轮廓（供 split_dxf 在内存调用）。"""
    closed = _collect_closed_polylines(entities, layers)
    if not closed:
        return None
    closed.sort(key=_bbox_area, reverse=True)
    largest = closed[0]
    simplified = simplify_to_max(largest, 32)
    mapped = mapper.map_points(simplified)
    return {
        "type": "polygon",
        "points": [list(p) for p in mapped],
    }
