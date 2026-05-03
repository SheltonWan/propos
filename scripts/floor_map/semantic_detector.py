"""语义结构检测器 — 多策略并行：INSERT 块名、TEXT 关键词、图层名模糊匹配、STAIR 几何聚类。

当 DXF 不遵循 AIA 标准图层命名时，通过语义分析补充检测电梯、楼梯、卫生间、核心筒等结构。
四条策略互为补充，最终统一去重。

输出元素结构（与 column_detector 相同的 structures 格式）::

    {"type": "elevator|stair|restroom|core|equipment|lobby|corridor",
     "source": "auto",
     "label": "<来源描述>",   # 可选
     "rect":  [x, y, w, h]}  # 视口坐标（px）

"""
from __future__ import annotations

import math
import re
from typing import Iterable

import ezdxf

from .coordinate_mapper import CoordinateMapper
from .outline_extractor import layer_normalize

# ---------------------------------------------------------------------------
# 关键词映射（中文 + 英文，不区分大小写，优先匹配靠前的类型）
# ---------------------------------------------------------------------------

KEYWORD_MAP: dict[str, list[str]] = {
    "elevator": [
        "电梯", "elev", "elevator", "lift",
        "消防电梯", "客梯", "货梯", "扶梯",
    ],
    "stair": [
        "楼梯", "stair", "梯间", "楼梯间",
        "疏散楼梯", "消防楼梯",
    ],
    "restroom": [
        "卫生间", "厕所", "男卫", "女卫", "洗手间",
        "wc", "toilet", "restroom",
    ],
    "core": [
        "核心筒", "core", "核心",
    ],
    "equipment": [
        "设备间", "机房", "mech", "equip",
        "人防", "弱电", "强电",
    ],
    "lobby": [
        "大堂", "门厅", "前厅", "lobby",
    ],
    "corridor": [
        "走廊", "走道", "corridor",
    ],
}

# 图层名正则匹配模式（不区分大小写）
# 注意：r"elev" 不能过宽 —— AIA 标准 DIM_ELEV 是高程标注图层而非电梯，需要排除 dim_ 前缀
LAYER_PATTERN_MAP: dict[str, list[str]] = {
    "elevator": [r"(?<!dim_)\belev\b", r"\blift\b", r"电梯"],
    "stair":    [r"\bstair\b", r"楼梯"],
    "restroom": [r"\btoilet\b", r"\bwc\b", r"卫生间"],
    "core":     [r"\bcore\b", r"核心筒"],
    "equipment":[r"\bmech\b", r"\bequip\b", r"设备间"],
}

# 楼梯图层名白名单
STAIR_LAYERS: tuple[str, ...] = ("STAIR", "楼梯", "stair")

# 楼梯踏步聚类距离阈值（DXF 世界单位，通常 mm）
_STAIR_CLUSTER_DIST = 5_000.0


# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------

def _match_keywords(text: str) -> str | None:
    """在 text 中搜索关键词（不区分大小写），返回首个匹配的结构类型。"""
    low = text.lower()
    for struct_type, keywords in KEYWORD_MAP.items():
        for kw in keywords:
            if kw in low:
                return struct_type
    return None


def _bbox_to_rect(
    x0: float, y0: float, x1: float, y1: float, mapper: CoordinateMapper
) -> list[float]:
    """DXF 世界坐标包围盒 → 视口坐标 [x, y, w, h]。"""
    p0 = mapper.map_point((x0, y0))
    p1 = mapper.map_point((x1, y1))
    x = min(p0[0], p1[0])
    y = min(p0[1], p1[1])
    w = abs(p1[0] - p0[0])
    h = abs(p1[1] - p0[1])
    return [round(x, 1), round(y, 1), round(w, 1), round(h, 1)]


def _default_rect_at(
    cx: float, cy: float, struct_type: str, mapper: CoordinateMapper
) -> list[float]:
    """以 (cx, cy) 为中心，按结构类型默认尺寸生成视口矩形。

    默认尺寸使用视口可用区域的百分比，与 DXF 坐标系的单位/比例无关，
    确保即使在跨度极大（整栋楼立面图）的 DXF 中也能生成可见矩形。
    """
    vp = mapper.viewport
    usable_w = vp.width - 2 * vp.padding
    usable_h = vp.height - 2 * vp.padding
    # 各结构类型对应的视口占比目标（宽%, 高%）
    _TARGET_PCT: dict[str, tuple[float, float]] = {
        "elevator":  (0.04, 0.06),
        "stair":     (0.06, 0.09),
        "restroom":  (0.05, 0.05),
        "core":      (0.15, 0.20),
        "equipment": (0.05, 0.06),
        "lobby":     (0.18, 0.25),
        "corridor":  (0.05, 0.15),
    }
    wpct, hpct = _TARGET_PCT.get(struct_type, (0.05, 0.05))
    w_px = usable_w * wpct
    h_px = usable_h * hpct
    cx_px, cy_px = mapper.map_point((cx, cy))
    return [
        round(cx_px - w_px / 2, 1),
        round(cy_px - h_px / 2, 1),
        round(w_px, 1),
        round(h_px, 1),
    ]


def _collect_entity_pts(entity) -> list[tuple[float, float]]:
    """提取单个实体的所有代表性坐标点。失败时返回空列表。"""
    pts: list[tuple[float, float]] = []
    try:
        etype = entity.dxftype()
        if etype == "LINE":
            pts = [
                (entity.dxf.start.x, entity.dxf.start.y),
                (entity.dxf.end.x, entity.dxf.end.y),
            ]
        elif etype == "LWPOLYLINE":
            pts = [(p[0], p[1]) for p in entity.get_points("xy")]
        elif etype == "CIRCLE":
            cx, cy, r = entity.dxf.center.x, entity.dxf.center.y, entity.dxf.radius
            pts = [(cx - r, cy), (cx + r, cy), (cx, cy - r), (cx, cy + r)]
        elif etype == "INSERT":
            pts = [(entity.dxf.insert.x, entity.dxf.insert.y)]
    except Exception:  # noqa: BLE001
        pass
    return pts


# ---------------------------------------------------------------------------
# 策略 1：INSERT 块名语义匹配
# ---------------------------------------------------------------------------

def _get_block_bbox(doc, block_name: str) -> tuple[float, float, float, float] | None:
    """获取块定义内实体的包围盒（局部坐标）。找不到或过小时返回 None。"""
    if doc is None or block_name not in doc.blocks:
        return None
    pts: list[tuple[float, float]] = []
    for e in doc.blocks[block_name]:
        pts.extend(_collect_entity_pts(e))
    if not pts:
        return None
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    w = max(xs) - min(xs)
    h = max(ys) - min(ys)
    # 过滤纯标注符号（< 100mm）
    if w < 100 or h < 100:
        return None
    return (min(xs), min(ys), max(xs), max(ys))


def _detect_from_inserts(
    entity_list: list, doc, mapper: CoordinateMapper
) -> list[dict]:
    """策略 1：INSERT 块名关键词匹配。"""
    results: list[dict] = []
    for entity in entity_list:
        if entity.dxftype() != "INSERT":
            continue
        block_name: str = entity.dxf.name
        struct_type = _match_keywords(block_name)
        if not struct_type:
            continue
        try:
            ix, iy = entity.dxf.insert.x, entity.dxf.insert.y
        except Exception:  # noqa: BLE001
            continue

        # 尝试从块定义获取精确包围盒
        block_bbox = _get_block_bbox(doc, block_name)
        if block_bbox:
            bx0, by0, bx1, by1 = block_bbox
            rect = _bbox_to_rect(ix + bx0, iy + by0, ix + bx1, iy + by1, mapper)
        else:
            rect = _default_rect_at(ix, iy, struct_type, mapper)

        # 块定义坐标范围极小（< 20px）时退回默认尺寸，避免锚点类块误导
        if rect[2] < 20 or rect[3] < 20:
            rect = _default_rect_at(ix, iy, struct_type, mapper)
        # 过滤仍然过小的（视口 < 5px）
        if rect[2] < 5 or rect[3] < 5:
            continue

        results.append({
            "type": struct_type,
            "source": "auto",
            "label": block_name,
            "rect": rect,
        })
    return results


# ---------------------------------------------------------------------------
# 策略 2：TEXT / MTEXT 关键词语义匹配
# ---------------------------------------------------------------------------

def _find_enclosing_poly(
    tx: float,
    ty: float,
    entity_list: list,
    max_dist: float = 50_000.0,
) -> tuple[float, float, float, float] | None:
    """在实体列表中寻找包含点 (tx,ty) 的面积最小的闭合 LWPOLYLINE。"""
    best: tuple[float, float, float, float] | None = None
    best_area = float("inf")
    for e in entity_list:
        if e.dxftype() != "LWPOLYLINE" or not e.closed:
            continue
        try:
            pts = [(p[0], p[1]) for p in e.get_points("xy")]
        except Exception:  # noqa: BLE001
            continue
        if len(pts) < 3:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        # 快速 AABB 包含检测（允许小误差）
        margin = max_dist if not (x0 <= tx <= x1 and y0 <= ty <= y1) else 0
        if margin > max_dist:
            continue
        # 对于 AABB 之外的点：测量最近边距
        if margin > 0:
            dist = max(x0 - tx, tx - x1, y0 - ty, ty - y1, 0.0)
            if dist > max_dist:
                continue
        area = (x1 - x0) * (y1 - y0)
        if 0 < area < best_area:
            best = (x0, y0, x1, y1)
            best_area = area
    return best


def _detect_from_text(entity_list: list, mapper: CoordinateMapper) -> list[dict]:
    """策略 2：TEXT / MTEXT / ATTDEF 关键词匹配 + 包围框查找。"""
    results: list[dict] = []
    for entity in entity_list:
        etype = entity.dxftype()
        if etype not in ("TEXT", "MTEXT", "ATTDEF"):
            continue
        try:
            raw = entity.text if etype == "MTEXT" else entity.dxf.text
            text = raw.strip()
        except Exception:  # noqa: BLE001
            continue
        if not text:
            continue

        struct_type = _match_keywords(text)
        if not struct_type:
            continue

        try:
            insert = entity.dxf.insert
            tx, ty = insert.x, insert.y
        except Exception:  # noqa: BLE001
            continue

        # 先尝试找包围多边形（搜索所有闭合 LWPOLYLINE）
        enclosing = _find_enclosing_poly(tx, ty, entity_list)
        if enclosing:
            rect = _bbox_to_rect(*enclosing, mapper)
        else:
            rect = _default_rect_at(tx, ty, struct_type, mapper)

        if rect[2] < 5 or rect[3] < 5:
            continue

        results.append({
            "type": struct_type,
            "source": "auto",
            "label": text,
            "rect": rect,
        })
    return results


# ---------------------------------------------------------------------------
# 策略 3：图层名模糊匹配（正则）
# ---------------------------------------------------------------------------

def _detect_from_layer_names(entity_list: list, mapper: CoordinateMapper) -> list[dict]:
    """策略 3：图层名含语义关键词时，提取该图层实体包围盒。"""
    # 按图层名收集所有坐标点
    layer_pts: dict[str, list[tuple[float, float]]] = {}
    for entity in entity_list:
        try:
            ln = entity.dxf.layer
        except Exception:  # noqa: BLE001
            continue
        pts = _collect_entity_pts(entity)
        if pts:
            layer_pts.setdefault(ln, []).extend(pts)

    results: list[dict] = []
    for layer_name, pts in layer_pts.items():
        low = layer_name.lower()
        struct_type: str | None = None
        for stype, patterns in LAYER_PATTERN_MAP.items():
            if any(re.search(pat, low) for pat in patterns):
                struct_type = stype
                break
        if not struct_type or len(pts) < 2:
            continue

        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        rect = _bbox_to_rect(min(xs), min(ys), max(xs), max(ys), mapper)
        if rect[2] < 5 or rect[3] < 5:
            continue
        # 过滤极端长宽比（>20:1）的噪声条带（如维度线、指引线等）
        aspect = max(rect[2], rect[3]) / max(min(rect[2], rect[3]), 1)
        if aspect > 20:
            continue

        results.append({
            "type": struct_type,
            "source": "auto",
            "label": layer_name,
            "rect": rect,
        })
    return results


# ---------------------------------------------------------------------------
# 策略 4：STAIR 图层几何聚类
# ---------------------------------------------------------------------------

def _greedy_cluster(
    pts: list[tuple[float, float]], threshold: float
) -> list[list[tuple[float, float]]]:
    """贪心聚类：将点分配到最近簇（质心距离 ≤ threshold），否则新建簇。"""
    clusters: list[list[tuple[float, float]]] = []
    for pt in pts:
        best_i, best_d = -1, float("inf")
        for i, cluster in enumerate(clusters):
            cx = sum(p[0] for p in cluster) / len(cluster)
            cy = sum(p[1] for p in cluster) / len(cluster)
            d = math.hypot(pt[0] - cx, pt[1] - cy)
            if d < best_d:
                best_i, best_d = i, d
        if best_d <= threshold:
            clusters[best_i].append(pt)
        else:
            clusters.append([pt])
    return clusters


def _detect_stairs_from_layer(entity_list: list, mapper: CoordinateMapper) -> list[dict]:
    """策略 4：从 STAIR 图层 LWPOLYLINE/LINE 几何体聚类检测楼梯间。"""
    stair_set = {layer_normalize(ln) for ln in STAIR_LAYERS}
    all_pts: list[tuple[float, float]] = []

    for entity in entity_list:
        try:
            ln = layer_normalize(entity.dxf.layer)
        except Exception:  # noqa: BLE001
            continue
        if ln not in stair_set:
            continue
        etype = entity.dxftype()
        try:
            if etype == "LWPOLYLINE":
                all_pts.extend((p[0], p[1]) for p in entity.get_points("xy"))
            elif etype == "LINE":
                all_pts.append((entity.dxf.start.x, entity.dxf.start.y))
                all_pts.append((entity.dxf.end.x, entity.dxf.end.y))
        except Exception:  # noqa: BLE001
            continue

    if not all_pts:
        return []

    clusters = _greedy_cluster(all_pts, _STAIR_CLUSTER_DIST)
    results: list[dict] = []
    for cluster in clusters:
        if len(cluster) < 4:  # 点太少不成面
            continue
        xs = [p[0] for p in cluster]
        ys = [p[1] for p in cluster]
        rect = _bbox_to_rect(min(xs), min(ys), max(xs), max(ys), mapper)
        # 楼梯踏步线条很细——视口尺寸 < 20px 时退回到视口比例默认矩形
        if rect[2] < 20 or rect[3] < 20:
            cx = sum(xs) / len(xs)
            cy = sum(ys) / len(ys)
            rect = _default_rect_at(cx, cy, "stair", mapper)
        if rect[2] < 5 or rect[3] < 5:
            continue
        results.append({
            "type": "stair",
            "source": "auto",
            "rect": rect,
        })
    return results


# ---------------------------------------------------------------------------
# 去重
# ---------------------------------------------------------------------------

def _rect_center(rect: list[float]) -> tuple[float, float]:
    return (rect[0] + rect[2] / 2, rect[1] + rect[3] / 2)


def _dedup(structs: list[dict], dist_px: float = 20.0) -> list[dict]:
    """去除同类型且视口中心距 < dist_px 的重复结构（保留先出现的）。"""
    deduped: list[dict] = []
    for s in structs:
        if "rect" not in s:
            deduped.append(s)
            continue
        cx, cy = _rect_center(s["rect"])
        dup = False
        for d in deduped:
            if d.get("type") != s.get("type") or "rect" not in d:
                continue
            dx, dy = _rect_center(d["rect"])
            if math.hypot(cx - dx, cy - dy) < dist_px:
                dup = True
                break
        if not dup:
            deduped.append(s)
    return deduped


# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------

def detect_structures(dxf_path: str, mapper: CoordinateMapper) -> list[dict]:
    """从 DXF 文件运行全部语义检测策略，返回 structure 候选列表。"""
    doc = ezdxf.readfile(dxf_path)
    entity_list = list(doc.modelspace())
    return detect_structures_from_entities(entity_list, mapper, doc=doc)


def detect_structures_from_entities(
    entities,
    mapper: CoordinateMapper,
    doc=None,
) -> list[dict]:
    """从实体迭代器运行全部语义检测策略。

    Args:
        entities: modelspace 实体可迭代对象（如已有列表可直接传入）。
        mapper:   坐标映射器。
        doc:      ezdxf.Drawing 对象（可选），提供块定义以便精确计算 INSERT 包围盒。
    """
    # 确保可多次迭代
    entity_list: list = list(entities) if not isinstance(entities, list) else entities

    results: list[dict] = []
    results.extend(_detect_from_inserts(entity_list, doc, mapper))  # 策略 1
    results.extend(_detect_from_text(entity_list, mapper))           # 策略 2
    results.extend(_detect_from_layer_names(entity_list, mapper))    # 策略 3
    results.extend(_detect_stairs_from_layer(entity_list, mapper))   # 策略 4

    return _dedup(results)
