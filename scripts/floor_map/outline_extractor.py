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
from .layer_constants import WALL_OUTLINE_LAYERS

DEFAULT_OUTLINE_LAYERS = WALL_OUTLINE_LAYERS


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


def _collect_layer_points(entities, layers: Iterable[str]) -> list[Point]:
    """从指定图层收集所有几何端点（含 LINE 端点 / LWPOLYLINE 顶点 / HATCH 边界）。

    用于 fallback：当外墙图层无闭合多段线时，外墙通常以双线 LINE 绘制，
    取所有端点的凸包即得近似外轮廓。
    """
    layer_set = {layer_normalize(name) for name in layers}
    pts: list[Point] = []
    for entity in entities:
        layer_name = layer_normalize(entity.dxf.layer)
        if not any(layer_name == ln or layer_name.endswith("|" + ln) for ln in layer_set):
            continue
        et = entity.dxftype()
        try:
            if et == "LINE":
                pts.append((entity.dxf.start.x, entity.dxf.start.y))
                pts.append((entity.dxf.end.x, entity.dxf.end.y))
            elif et == "LWPOLYLINE":
                for p in entity.get_points("xy"):
                    pts.append((p[0], p[1]))
            elif et == "POLYLINE":
                for v in entity.vertices:
                    pts.append((v.dxf.location.x, v.dxf.location.y))
            elif et == "HATCH":
                for path in entity.paths:
                    for v in path.vertices():
                        pts.append((v[0], v[1]))
        except Exception:  # noqa: BLE001
            continue
    return pts


def _convex_hull(points: list[Point]) -> list[Point]:
    """凸包（Andrew 单调链算法，无外部依赖）。"""
    pts = sorted(set((round(p[0], 4), round(p[1], 4)) for p in points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower: list[Point] = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper: list[Point] = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def extract_outline_from_entities(
    entities,
    mapper: CoordinateMapper,
    layers: Iterable[str] = DEFAULT_OUTLINE_LAYERS,
) -> dict | None:
    """从实体迭代器抽取外轮廓（供 split_dxf 在内存调用）。

    策略（多重 fallback）：
    1. 收集 ``layers`` 上的闭合 LWPOLYLINE/POLYLINE，若最大 bbox 面积 ≥ 区域参考面积的 30%
       则取该多段线作为外轮廓
    2. 否则收集 ``layers`` 上所有 LINE / LWPOLYLINE / HATCH 端点 → 凸包近似外轮廓
       （业务层外墙常为双线 LINE 绘制，无单一闭合多段线）
    3. 最终简化到 ≤ 32 顶点
    """
    entities_list = list(entities)
    closed = _collect_closed_polylines(entities_list, layers)
    selected: list[Point] | None = None

    if closed:
        closed.sort(key=_bbox_area, reverse=True)
        largest = closed[0]
        # 区域参考面积：用 mapper.viewport 作为目标尺寸，反推世界坐标的可见区域面积
        # 简化判定：若 bbox 在世界坐标 ≥ 100 mm × 100 mm 即视为有效轮廓
        bx_min = min(p[0] for p in largest)
        bx_max = max(p[0] for p in largest)
        by_min = min(p[1] for p in largest)
        by_max = max(p[1] for p in largest)
        if (bx_max - bx_min) >= 5000 and (by_max - by_min) >= 5000:
            selected = largest

    if selected is None:
        # fallback：凸包
        all_pts = _collect_layer_points(entities_list, layers)
        if len(all_pts) < 3:
            return None
        hull = _convex_hull(all_pts)
        if len(hull) < 3:
            return None
        selected = list(hull)

    simplified = simplify_to_max(selected, 32)
    mapped = mapper.map_points(simplified)
    return {
        "type": "polygon",
        "points": [list(p) for p in mapped],
    }
