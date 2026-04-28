#!/usr/bin/env python3
"""DXF 房间识别与 SVG 热区标注工具 (v2)。

策略（v2）：
  不尝试寻找封闭面积多边形（该 DXF 无独立房间轮廓图层），改为：
  1. 扫描 MSP INSERT（layer='房号'），用 virtual_entities() 展开，
     取 CIRCLE（圆心=房间标注位置）+ 就近 TEXT（房号如 01/02）。
  2. 扫描 MSP INSERT（layer='房间名称'），展开取 TEXT（如"产业研发用房"）。
  3. 解析 MSP 直接 TEXT（内容匹配面积格式"XX.XXm"，h≈350）作为面积标注。
  4. 按楼层 dxf_region 过滤，构建房间列表。
  5. DXF 坐标 → SVG 坐标（利用 JSON viewport + dxf_region 做线性映射）。
  6. 将热区 <g> 注入 SVG 的 <g id="unit-hotspots">，并更新 JSON units 数组。

使用方式：
    python3 scripts/annotate_hotzone.py \\
        cad_intermediate/building_a/A座.dxf \\
        cad_intermediate/building_a/floors \\
        --prefix A座

    # 仅标注指定楼层
    python3 scripts/annotate_hotzone.py \\
        cad_intermediate/building_a/A座.dxf \\
        cad_intermediate/building_a/floors \\
        --prefix A座 --floor F11
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# 依赖检测
# ---------------------------------------------------------------------------
try:
    import ezdxf
except ImportError:
    sys.exit("[错误] 未安装 ezdxf，请运行：pip install ezdxf")

try:
    from lxml import etree
except ImportError:
    sys.exit("[错误] 未安装 lxml，请运行：pip install lxml")

# ---------------------------------------------------------------------------
# 常量
# ---------------------------------------------------------------------------

# 房间编号图层（INSERT → CIRCLE + TEXT，编号如 01/02/03）
ROOM_NO_LAYER = "房号"
# 房间功能名称图层（INSERT → TEXT，如 "产业研发用房"）
ROOM_NAME_LAYER = "房间名称"

# 关联容差：最近距离阈值（DXF 单位 mm）
MATCH_DIST_THRESHOLD = 8_000   # 8m，足够跨过一个走廊找到对面标注

# 面积标注 TEXT 高度（h≈350 mm）
AREA_TEXT_HEIGHT_APPROX = 350.0
AREA_TEXT_HEIGHT_TOL = 100.0   # ±100mm 容差
# 面积标注正则：匹配 "52.01m" 或 "878.41m" 等格式（含整数如 "800m"）
AREA_TEXT_RE = re.compile(r"^(\d+[\.,]\d+)m$")

# SVG 热区圆半径倍数（相对于 DXF 坐标系中圆圈的实际半径）
HOTSPOT_RADIUS_FACTOR = 3.0
# 热区最小 SVG 半径（当比例尺极小时的保底值）
HOTSPOT_MIN_RADIUS_SVG = 2_000

# SVG 命名空间
SVG_NS = "http://www.w3.org/2000/svg"
SVG = f"{{{SVG_NS}}}"


# ---------------------------------------------------------------------------
# 坐标变换
# ---------------------------------------------------------------------------

def make_transform(region: dict, viewport: dict):
    """返回 (dxf_x, dxf_y) → (svg_x, svg_y) 的变换函数及 x/y 比例因子。

    SVG 坐标原点在左上角，Y 轴向下；DXF Y 轴向上，故做翻转。
    scale_x = viewport.width  / (region.max_x - region.min_x)
    scale_y = viewport.height / (region.max_y - region.min_y)
    """
    rx = region["max_x"] - region["min_x"]
    ry = region["max_y"] - region["min_y"]
    vw = float(viewport["width"])
    vh = float(viewport["height"])
    scale_x = vw / rx if rx > 0 else 1.0
    scale_y = vh / ry if ry > 0 else 1.0

    def transform(dxf_x: float, dxf_y: float) -> tuple[float, float]:
        svg_x = (dxf_x - region["min_x"]) * scale_x
        svg_y = (region["max_y"] - dxf_y) * scale_y
        return svg_x, svg_y

    return transform, scale_x, scale_y


# ---------------------------------------------------------------------------
# 区域判断
# ---------------------------------------------------------------------------

def _is_in_region(x: float, y: float, region: dict, tolerance: float = 200.0) -> bool:
    """判断 DXF 坐标 (x, y) 是否在楼层区域内（含容差）。"""
    return (
        region["min_x"] - tolerance <= x <= region["max_x"] + tolerance
        and region["min_y"] - tolerance <= y <= region["max_y"] + tolerance
    )


# ---------------------------------------------------------------------------
# INSERT 块展开工具函数
# ---------------------------------------------------------------------------

def _expand_insert_circles_and_texts(
    insert_entity,
) -> tuple[list[tuple[float, float, float]], list[tuple[float, float, str]]]:
    """展开 INSERT 的 virtual_entities，分别收集 CIRCLE 和 TEXT 实体。

    Returns:
        circles: [(cx, cy, radius), ...]
        texts:   [(tx, ty, text_str), ...]
    """
    circles: list[tuple[float, float, float]] = []
    texts: list[tuple[float, float, str]] = []
    try:
        for ve in insert_entity.virtual_entities():
            if ve.dxftype() == "CIRCLE":
                try:
                    circles.append((
                        float(ve.dxf.center.x),
                        float(ve.dxf.center.y),
                        float(ve.dxf.radius),
                    ))
                except Exception:
                    pass
            elif ve.dxftype() in ("TEXT", "MTEXT"):
                try:
                    txt = (
                        ve.dxf.text if ve.dxftype() == "TEXT" else ve.text
                    ).strip()
                    if txt:
                        texts.append((
                            float(ve.dxf.insert.x),
                            float(ve.dxf.insert.y),
                            txt,
                        ))
                except Exception:
                    pass
    except Exception:
        pass
    return circles, texts


def _expand_insert_texts_only(
    insert_entity,
) -> list[tuple[float, float, str]]:
    """展开 INSERT 的 virtual_entities，只收集 TEXT/MTEXT 实体。"""
    texts: list[tuple[float, float, str]] = []
    try:
        for ve in insert_entity.virtual_entities():
            if ve.dxftype() not in ("TEXT", "MTEXT"):
                continue
            try:
                txt = (
                    ve.dxf.text if ve.dxftype() == "TEXT" else ve.text
                ).strip()
                if txt:
                    texts.append((
                        float(ve.dxf.insert.x),
                        float(ve.dxf.insert.y),
                        txt,
                    ))
            except Exception:
                pass
    except Exception:
        pass
    return texts


def _nearest_text(
    cx: float,
    cy: float,
    texts: list[tuple[float, float, str]],
    threshold: float = MATCH_DIST_THRESHOLD,
) -> Optional[str]:
    """从 texts 列表中找到离 (cx, cy) 最近且距离不超过 threshold 的文字。"""
    best_txt: Optional[str] = None
    best_d = threshold
    for tx, ty, txt in texts:
        d = math.hypot(tx - cx, ty - cy)
        if d < best_d:
            best_d = d
            best_txt = txt
    return best_txt


# ---------------------------------------------------------------------------
# 面积标注提取（MSP 直接 TEXT）
# ---------------------------------------------------------------------------

def _collect_area_labels(msp, region: dict) -> list[tuple[float, float, float]]:
    """从 MSP 直接 TEXT 中提取面积标注。

    匹配格式形如 "52.01m"（h≈350）的 TEXT，解析为浮点 m² 值。
    Returns: [(tx, ty, area_m2), ...]
    """
    results: list[tuple[float, float, float]] = []
    for entity in msp:
        if entity.dxftype() != "TEXT":
            continue
        try:
            txt = entity.dxf.text.strip()
        except Exception:
            continue
        m = AREA_TEXT_RE.match(txt)
        if not m:
            continue
        try:
            h = float(entity.dxf.height)
        except Exception:
            h = 0.0
        if abs(h - AREA_TEXT_HEIGHT_APPROX) > AREA_TEXT_HEIGHT_TOL:
            continue
        try:
            tx = float(entity.dxf.insert.x)
            ty = float(entity.dxf.insert.y)
        except Exception:
            continue
        if not _is_in_region(tx, ty, region):
            continue
        area = float(m.group(1).replace(",", "."))
        results.append((tx, ty, area))
    return results


# ---------------------------------------------------------------------------
# 核心提取：按楼层区域提取所有房间
# ---------------------------------------------------------------------------

def extract_rooms(msp, region: dict) -> list[dict]:
    """提取指定楼层区域内的所有房间信息。

    数据来源：
    - 房号图层 INSERT → CIRCLE（位置）+ TEXT（房号字符串，如 "01"/"02"）
    - 房间名称图层 INSERT → TEXT（房间类型名称，如 "产业研发用房"）
    - MSP 直接 TEXT（面积格式）→ area_m2

    Returns:
        每项为 dict，键：cx/cy/dxf_r/room_no/room_name/area_m2
    """
    # ---- Step 1: 房号图层 INSERT → CIRCLE + TEXT ----
    rooms: list[dict] = []

    for entity in msp:
        if entity.dxftype() != "INSERT":
            continue
        if entity.dxf.layer != ROOM_NO_LAYER:
            continue

        circles, texts = _expand_insert_circles_and_texts(entity)
        if not circles:
            continue

        floor_circles = [
            (cx, cy, r) for cx, cy, r in circles
            if _is_in_region(cx, cy, region)
        ]
        if not floor_circles:
            continue

        for cx, cy, r in floor_circles:
            room_no = _nearest_text(cx, cy, texts) or ""
            rooms.append({
                "cx": cx,
                "cy": cy,
                "dxf_r": r,
                "room_no": room_no,
                "room_name": "",
                "area_m2": None,
            })

    if not rooms:
        return []

    # ---- Step 2: 房间名称图层 INSERT → TEXT ----
    name_texts: list[tuple[float, float, str]] = []
    for entity in msp:
        if entity.dxftype() != "INSERT":
            continue
        if entity.dxf.layer != ROOM_NAME_LAYER:
            continue
        for tx, ty, txt in _expand_insert_texts_only(entity):
            if _is_in_region(tx, ty, region):
                name_texts.append((tx, ty, txt))

    # 同时收集 MSP 直接 TEXT（layer=房间名称，非面积格式，非上标"2"）
    for entity in msp:
        if entity.dxftype() != "TEXT":
            continue
        if entity.dxf.layer != ROOM_NAME_LAYER:
            continue
        try:
            txt = entity.dxf.text.strip()
            if not txt or AREA_TEXT_RE.match(txt) or txt == "2":
                continue
            tx = float(entity.dxf.insert.x)
            ty = float(entity.dxf.insert.y)
            if _is_in_region(tx, ty, region):
                name_texts.append((tx, ty, txt))
        except Exception:
            pass

    for room in rooms:
        name = _nearest_text(room["cx"], room["cy"], name_texts)
        if name:
            room["room_name"] = name

    # ---- Step 3: 面积标注，关联到最近的圆圈 ----
    area_labels = _collect_area_labels(msp, region)
    for room in rooms:
        best_area: Optional[float] = None
        best_d = MATCH_DIST_THRESHOLD
        for tx, ty, area in area_labels:
            d = math.hypot(tx - room["cx"], ty - room["cy"])
            if d < best_d:
                best_d = d
                best_area = area
        room["area_m2"] = best_area

    # 按房号排序（空字符串排末尾）
    rooms.sort(key=lambda r: (not r["room_no"], r["room_no"]))
    return rooms


# ---------------------------------------------------------------------------
# SVG 写入
# ---------------------------------------------------------------------------

def inject_hotspots_to_svg(
    svg_path: Path,
    rooms: list[dict],
    region: dict,
    viewport: dict,
    floor_prefix: str = "",
) -> int:
    """将房间热区圆圈写入 SVG 的 unit-hotspots 层。

    每个热区生成：
        <g class="unit-hotspot unit-vacant" data-unit-id="..." ...>
          <circle cx="..." cy="..." r="..." class="unit-dot"/>
          <title>01 - 产业研发用房 (52.01m²)</title>
        </g>

    返回写入的房间数量。
    """
    tree = etree.parse(str(svg_path))
    root = tree.getroot()

    hotspots_g = root.find(f".//{SVG}g[@id='unit-hotspots']")
    if hotspots_g is None:
        print(f"  [警告] {svg_path.name} 中未找到 <g id='unit-hotspots'>，跳过")
        return 0

    # 清空现有内容
    for child in list(hotspots_g):
        hotspots_g.remove(child)
    hotspots_g.text = "\n  "

    transform, scale_x, scale_y = make_transform(region, viewport)
    avg_scale = (scale_x + scale_y) / 2.0

    count = 0
    for room in rooms:
        svg_cx, svg_cy = transform(room["cx"], room["cy"])
        hotspot_r = max(
            HOTSPOT_MIN_RADIUS_SVG,
            room["dxf_r"] * avg_scale * HOTSPOT_RADIUS_FACTOR,
        )
        no = room["room_no"].strip()
        if no and floor_prefix:
            unit_id = f"{floor_prefix}-{no}"
        elif no:
            unit_id = no
        else:
            unit_id = f"R{count + 1:03d}"

        attrib: dict[str, str] = {
            "class": "unit-hotspot unit-vacant",
            "data-unit-id": unit_id,
        }
        if room["room_name"]:
            attrib["data-room-name"] = room["room_name"]
        if room["area_m2"] is not None:
            attrib["data-area-sqm"] = str(room["area_m2"])

        g_el = etree.SubElement(hotspots_g, f"{SVG}g", attrib=attrib)
        g_el.text = "\n    "

        # 可见热区圆圈
        circ = etree.SubElement(
            g_el,
            f"{SVG}circle",
            attrib={
                "cx": str(round(svg_cx)),
                "cy": str(round(svg_cy)),
                "r":  str(round(hotspot_r)),
                "class": "unit-dot",
            },
        )
        circ.tail = "\n    "

        # tooltip 文字
        title_el = etree.SubElement(g_el, f"{SVG}title")
        parts: list[str] = []
        if no:
            parts.append(no)
        if room["room_name"]:
            parts.append(room["room_name"])
        if room["area_m2"] is not None:
            parts.append(f"{room['area_m2']}m\u00b2")
        title_el.text = " - ".join(parts) if parts else unit_id
        title_el.tail = "\n  "
        g_el.tail = "\n  "
        count += 1

    hotspots_g.append(etree.Comment(f" 已标注：{count} 个单元 "))

    tree.write(
        str(svg_path),
        xml_declaration=True,
        encoding="utf-8",
        pretty_print=True,
    )
    return count


# ---------------------------------------------------------------------------
# JSON 更新
# ---------------------------------------------------------------------------

def update_json_units(
    json_path: Path,
    rooms: list[dict],
    region: dict,
    viewport: dict,
    floor_prefix: str = "",
) -> None:
    """更新 JSON 骨架中的 units 数组。"""
    data = json.loads(json_path.read_text(encoding="utf-8"))
    transform, scale_x, scale_y = make_transform(region, viewport)
    avg_scale = (scale_x + scale_y) / 2.0

    units = []
    for idx, room in enumerate(rooms):
        no = room["room_no"].strip()
        if no and floor_prefix:
            unit_id = f"{floor_prefix}-{no}"
        elif no:
            unit_id = no
        else:
            unit_id = f"R{idx + 1:03d}"

        svg_cx, svg_cy = transform(room["cx"], room["cy"])
        hotspot_r = max(
            HOTSPOT_MIN_RADIUS_SVG,
            room["dxf_r"] * avg_scale * HOTSPOT_RADIUS_FACTOR,
        )

        units.append({
            "unit_id": unit_id,
            "room_no": no,
            "room_name": room["room_name"],
            "area_m2": room["area_m2"],
            "hotspot": {
                "type": "circle",
                "cx": round(svg_cx),
                "cy": round(svg_cy),
                "r":  round(hotspot_r),
            },
            "status": "vacant",  # 默认空置，前端根据租务数据覆盖
        })

    data["units"] = units
    json_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


# ---------------------------------------------------------------------------
# 楼层处理入口
# ---------------------------------------------------------------------------

def _load_floor_meta(json_path: Path) -> Optional[tuple[dict, dict]]:
    """读取楼层 JSON，返回 (dxf_region, viewport) 或 None。"""
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"  [错误] 读取 {json_path.name} 失败：{e}")
        return None

    region = data.get("dxf_region")
    viewport = data.get("viewport")
    if not region:
        print(f"  [警告] {json_path.name} 不含 dxf_region，请重新运行 split_dxf_by_floor.py")
        return None
    if not viewport:
        print(f"  [警告] {json_path.name} 不含 viewport")
        return None
    return region, viewport


def _floor_label_to_prefix(floor_label: str) -> str:
    """将楼层标签转为房号前缀，如 'F11' → '11'，'F6-F8-F10' → '060810'。"""
    nums = re.findall(r"\d+", floor_label)
    if len(nums) == 1:
        return nums[0]
    if nums:
        return "".join(f"{int(n):02d}" for n in nums)
    return floor_label


def process_floor(
    msp,
    json_path: Path,
    svg_path: Path,
) -> int:
    """处理单个楼层的热区标注，返回标注的房间数量。"""
    floor_label = json_path.stem.split("_", 1)[-1] if "_" in json_path.stem else json_path.stem

    result = _load_floor_meta(json_path)
    if result is None:
        return 0
    region, viewport = result

    print(f"  [{floor_label}] 提取房间标注点...")
    rooms = extract_rooms(msp, region)
    if not rooms:
        print(f"  [{floor_label}] 未找到房号标注圆圈，跳过")
        return 0

    floor_prefix = _floor_label_to_prefix(floor_label)
    print(f"  [{floor_label}] 找到 {len(rooms)} 个房间，写入 SVG + JSON...")
    count = inject_hotspots_to_svg(svg_path, rooms, region, viewport, floor_prefix)
    update_json_units(json_path, rooms, region, viewport, floor_prefix)
    print(f"  [{floor_label}] 完成：{count} 个房间热区 → {svg_path.name}")
    return count


# ---------------------------------------------------------------------------
# CLI 入口
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="DXF 房间识别与 SVG 热区标注工具 (v2)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("dxf_file", help="DXF 源文件路径")
    parser.add_argument(
        "floors_dir",
        help="楼层 SVG/JSON 所在目录（split_dxf_by_floor.py 的输出目录）",
    )
    parser.add_argument(
        "--prefix",
        default="",
        help="楼层文件名前缀，如 A座（用于筛选 <prefix>_*.json 文件）",
    )
    parser.add_argument(
        "--floor",
        default="",
        help="仅处理指定楼层标签，如 F11（留空则处理所有楼层）",
    )
    args = parser.parse_args()

    dxf_path = Path(args.dxf_file)
    floors_dir = Path(args.floors_dir)

    if not dxf_path.exists():
        sys.exit(f"[错误] DXF 文件不存在：{dxf_path}")
    if not floors_dir.is_dir():
        sys.exit(f"[错误] 楼层目录不存在：{floors_dir}")

    prefix = args.prefix
    floor_filter = args.floor.strip()

    if prefix:
        json_files = sorted(floors_dir.glob(f"{prefix}_*.json"))
    else:
        json_files = sorted(floors_dir.glob("*.json"))

    if floor_filter:
        json_files = [
            f for f in json_files
            if f.stem.endswith(f"_{floor_filter}") or f.stem == floor_filter
        ]

    if not json_files:
        sys.exit(
            f"[错误] 在 {floors_dir} 中未找到匹配的 JSON 文件"
            f"（prefix={prefix!r}, floor={floor_filter!r}）"
        )

    missing_svg = [f for f in json_files if not f.with_suffix(".svg").exists()]
    if missing_svg:
        print(f"[警告] 以下 JSON 的 SVG 不存在，跳过：{[f.name for f in missing_svg]}")
        json_files = [f for f in json_files if f.with_suffix(".svg").exists()]

    print(f"\n=== annotate_hotzone.py (v2) ===")
    print(f"DXF  : {dxf_path}")
    print(f"楼层 : {floors_dir}  ({len(json_files)} 个楼层)")
    print(f"加载 DXF...")

    try:
        doc = ezdxf.readfile(str(dxf_path))
    except Exception as e:
        sys.exit(f"[错误] 读取 DXF 失败：{e}")

    msp = doc.modelspace()

    total_rooms = 0
    for json_path in json_files:
        svg_path = json_path.with_suffix(".svg")
        n = process_floor(msp, json_path, svg_path)
        total_rooms += n

    print(f"\n=== 标注完成，共 {total_rooms} 个房间热区 ===")


if __name__ == "__main__":
    main()
