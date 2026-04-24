#!/usr/bin/env python3
"""
scripts/split_dxf_by_floor.py
按楼层切分 DXF Model Space，每张平面图输出一个独立 SVG。

工作原理：
  1. 在 Model Space 中扫描楼层标题文字（含 "X层平面图"），按 Y 排序
  2. 推算每张平面图的 Y 包围盒（上下两个标题的中点为分界）
  3. 对每个区域，用 ezdxf Frontend.draw_entities(filter_func=...) 仅渲染区域内实体
  4. 用每张图的实际 BoundingBox 作为 SVG 纸面尺寸输出

输出文件命名（合并图按"_"连接）：
  A座_F6-F8-F10.svg
  A座_F7-F9.svg
  A座_F11.svg
  A座_屋顶.svg
  ...

用法：
  python scripts/split_dxf_by_floor.py <input.dxf> <output_dir> [--prefix A座]

示例：
  python scripts/split_dxf_by_floor.py \
    cad_intermediate/building_a/A座.dxf \
    cad_intermediate/building_a/floors \
    --prefix A座
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Tuple

import ezdxf
from ezdxf import bbox
from ezdxf.addons.drawing import Frontend, RenderContext
from ezdxf.addons.drawing import layout as drawing_layout
from ezdxf.addons.drawing.svg import SVGBackend
from ezdxf.math import BoundingBox2d, Vec2, Vec3
from lxml import etree

# SVG 命名空间（ezdxf SVGBackend 输出使用默认 SVG 命名空间）
SVG_NS = "http://www.w3.org/2000/svg"
SVG = f"{{{SVG_NS}}}"

# 热区标准样式，严格对齐 docs/backend/SVG_HOTZONE_SPEC.md 第 2.2 节
# 注：Flutter 端使用 flutter_svg 不解析 CSS class，实际单元着色由上层 CustomPaint 覆盖层完成；
#     此处样式主要服务于 Web Admin / uni-app 直接内嵌 SVG 的渲染场景。
HOTZONE_STATUS_STYLE = """
      /* 单元热区状态色块 — 由前端运行时根据 unit.current_status 切换 class */
      .unit-leased        { fill: #4CAF50; fill-opacity: 0.35; stroke: #388E3C; stroke-width: 1; }
      .unit-vacant        { fill: #F44336; fill-opacity: 0.35; stroke: #D32F2F; stroke-width: 1; }
      .unit-expiring-soon { fill: #FF9800; fill-opacity: 0.35; stroke: #F57C00; stroke-width: 1; }
      .unit-renovating    { fill: #2196F3; fill-opacity: 0.35; stroke: #1976D2; stroke-width: 1; }
      .unit-non-leasable  { fill: #9E9E9E; fill-opacity: 0.20; stroke: #757575; stroke-width: 1; }
      [data-unit-id]:hover { fill-opacity: 0.55; cursor: pointer; }
"""

# 强制归类到专属 ACI 颜色的墙图层（渲染前会把这些图层的 LINE/LWPOLYLINE
# dxf.color 覆写为 WALL_ACI，使 ezdxf SVGBackend 把它们放进独立 CSS class）。
# 选 240 (hex F0) 避免与现有 C1..C23 冲突。
WALL_HIGHLIGHT_LAYERS = {"WALL", "CURTWALL", "外墙", "0muqiang", "muqiang"}
WALL_ACI = 240  # → ezdxf class "CF0"

# CAD 线稿中性样式：将原 DXF 图层的硬编码 RGB 颜色改为 currentColor，
# 由外层容器通过 CSS `color` 属性（Admin/uni-app）或 ColorFilter（Flutter）注入主题色。
NEUTRAL_CAD_STYLE = """
      /* CAD 线稿：颜色随外层 color 属性；线宽不随缩放改变 */
      #floor-plan * { vector-effect: non-scaling-stroke; }
      /* 填充类路径（柱墙 hatch、fill）统一用低透明度，避免吞没背景 */
      #floor-plan path[fill]:not([fill="none"]) {
        fill: currentColor;
        fill-opacity: 0.18;
      }
      /* 墙线（WALL/CURTWALL/外墙 图层）加粗强调 —— 覆盖中性化后的 stroke-width:1 */
      #floor-plan .CF0 {
        stroke: currentColor !important;
        stroke-width: 2.2 !important;
        stroke-opacity: 1 !important;
        fill: none !important;
      }
"""


def _neutralize_cad_colors(style_text: str) -> str:
    """将 CAD 图层样式中的 stroke/fill 硬编码颜色替换为 currentColor。

    - `stroke: #rrggbb` → `stroke: currentColor`
    - `fill: #rrggbb`   → `fill: currentColor; fill-opacity: 0.18`
      （避免柱墙填充在深色主题下吞没整个平面图）
    - `stroke-width: <large>` → `stroke-width: 1`（配合 vector-effect: non-scaling-stroke）
    """
    # stroke: #xxx → currentColor
    text = re.sub(
        r"stroke\s*:\s*#[0-9a-fA-F]{3,8}",
        "stroke: currentColor",
        style_text,
    )
    # fill: #xxx → currentColor + 低透明度（填充类 class 会额外带 fill-opacity: 1.000，
    # 这里保留；下面再统一覆盖 fill-opacity）
    text = re.sub(
        r"fill\s*:\s*#[0-9a-fA-F]{3,8}",
        "fill: currentColor",
        text,
    )
    # 把 fill-opacity: 1.000 统一降到 0.18（仅对 fill 非 none 的 class 生效；
    # stroke-only 的 class 本身 fill: none，此替换对它们无害）
    text = re.sub(
        r"fill-opacity\s*:\s*1(?:\.0+)?",
        "fill-opacity: 0.18",
        text,
    )
    # stroke-width 归一化
    text = re.sub(r"stroke-width\s*:\s*\d+(?:\.\d+)?", "stroke-width: 1", text)
    return text


def _inject_hotzone_spec(
    svg_string: str,
    building_id: str,
    floor_label: str,
) -> Tuple[str, dict]:
    """后处理 ezdxf SVG 输出，使其符合 SVG_HOTZONE_SPEC v1.0。

    执行以下变换：
    1. 清除 SVG 根上的 width/height 属性（避免 mm 固定尺寸），仅保留 viewBox
    2. 合并所有 <defs><style> 片段，把 CAD 颜色中性化，并追加热区标准样式
    3. 把除 <defs> 之外的所有直接子节点包裹进 <g id="floor-plan" pointer-events="none">
    4. 追加空的 <g id="unit-hotspots"> 层，供后续热区标注工具填充

    Returns:
        (处理后的 SVG 字符串, floor_map.json 骨架 dict)
    """
    root = etree.fromstring(svg_string.encode("utf-8"))

    # 读取 viewBox（ezdxf 输出形如 "0 0 902894 1000000"）
    viewbox = root.get("viewBox", "0 0 1200 800")
    parts = viewbox.split()
    vb_w = int(float(parts[2])) if len(parts) >= 3 else 1200
    vb_h = int(float(parts[3])) if len(parts) >= 4 else 800

    # 1. 移除 width/height，让 SVG 自适应容器尺寸
    root.attrib.pop("width", None)
    root.attrib.pop("height", None)

    # 2. 合并现有 defs/style 并中性化颜色
    existing_defs = root.findall(f"{SVG}defs")
    merged_style_text = NEUTRAL_CAD_STYLE
    for defs in existing_defs:
        for style_el in defs.findall(f"{SVG}style"):
            if style_el.text:
                merged_style_text += "\n" + _neutralize_cad_colors(style_el.text)
        root.remove(defs)
    # 追加热区标准样式
    merged_style_text += HOTZONE_STATUS_STYLE

    # 3. 把剩余子节点收集起来，稍后放进 floor-plan group
    #    同时移除 ezdxf 默认生成的"纸面背景" <rect fill="#000000"/>，
    #    让底色完全由前端主题 CSS（stage.background）决定。
    remaining_children = list(root)
    for child in remaining_children:
        if (
            child.tag == f"{SVG}rect"
            and child.get("x") == "0"
            and child.get("y") == "0"
            and (child.get("fill") or "").lower() in ("#000000", "#fff", "#ffffff", "black", "white")
        ):
            root.remove(child)
            remaining_children.remove(child)
            continue
        root.remove(child)

    # 重建顺序：defs -> floor-plan -> unit-hotspots
    new_defs = etree.SubElement(root, f"{SVG}defs")
    style_el = etree.SubElement(new_defs, f"{SVG}style")
    style_el.text = merged_style_text

    floor_plan_g = etree.SubElement(
        root,
        f"{SVG}g",
        attrib={"id": "floor-plan", "pointer-events": "none"},
    )
    for child in remaining_children:
        floor_plan_g.append(child)

    hotspots_g = etree.SubElement(
        root,
        f"{SVG}g",
        attrib={"id": "unit-hotspots"},
    )
    # 占位注释，便于肉眼识别未标注状态
    hotspots_g.append(etree.Comment(" 待标注：0 个单元（见 scripts/annotate_hotzone.py） "))

    processed = etree.tostring(
        root,
        xml_declaration=True,
        encoding="utf-8",
        pretty_print=True,
    ).decode("utf-8")

    skeleton = {
        "floor_id": None,  # 待绑定数据库 floor_id UUID
        "building_id": building_id,
        "floor_label": floor_label,
        "svg_version": None,  # 上传时由后端填充
        "viewport": {"width": vb_w, "height": vb_h},
        "units": [],
    }
    return processed, skeleton

# 楼层标题正则：匹配 "A座6层平面图" / "A座6、8、10层平面图" / "A座屋顶平面图" / "A座屋顶构架平面图"
TITLE_RE = re.compile(
    r"^(?P<prefix>[A-Z]?座?)?\s*"
    r"(?P<floors>"
    r"(?:\d+(?:\s*[、,]\s*\d+)*\s*层)"  # 6层 / 6、8、10层
    r"|(?:屋顶(?:构架)?)"  # 屋顶 / 屋顶构架
    r")"
    r"\s*平面图\s*$"
)

# 楼层标识符正则（用于提取 6、8、10 这样的数字）
FLOOR_NUM_RE = re.compile(r"\d+")


def find_title_frames(msp) -> List[BoundingBox2d]:
    """扫描 DXF 中的图框（双矩形外框）。

    本项目 A 座 DXF 中，每张平面图都被一对矩形（layer=TK，4 顶点闭合多段线）包裹：
      - 外框尺寸 ~84100 × 59400
      - 内框尺寸 ~80600 × 57400

    该函数只取外框，作为裁切边界。若后续遇到其他楼栋规格不同，可在此调整容差。
    """
    frames = []
    for e in msp:
        if e.dxf.layer != "TK" or e.dxftype() != "LWPOLYLINE":
            continue
        pts = [(p[0], p[1]) for p in e.get_points()]
        if len(pts) != 4 or not e.closed:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        w = max(xs) - min(xs)
        h = max(ys) - min(ys)
        # 外框尺寸匹配（±5% 容差）
        if 80000 <= w <= 88000 and 57000 <= h <= 62000:
            frames.append(BoundingBox2d([
                Vec2(min(xs), min(ys)),
                Vec2(max(xs), max(ys)),
            ]))
    return frames


def find_floor_titles(msp) -> List[Tuple[str, float, float, float, List[str]]]:
    """扫描楼层标题。

    Returns:
        List of (raw_text, x, y, height, floor_keys)
        floor_keys: 用于命名，如 ['F6', 'F8', 'F10'] 或 ['屋顶']
    """
    titles = []
    for e in msp:
        if e.dxftype() not in ("TEXT", "MTEXT"):
            continue
        text = e.dxf.get("text", "") if e.dxftype() == "TEXT" else e.text
        if not text:
            continue
        text = text.strip()
        if len(text) > 30:
            continue
        m = TITLE_RE.match(text)
        if not m:
            continue
        floors_part = m.group("floors")
        try:
            h = float(e.dxf.height)
        except Exception:
            h = 0.0
        # 仅保留较大字号的标题（过滤标注里的小字"21,23层此梁..."）
        if h < 400:
            continue

        if "屋顶" in floors_part:
            keys = ["屋顶构架"] if "构架" in floors_part else ["屋顶"]
        else:
            nums = FLOOR_NUM_RE.findall(floors_part)
            keys = [f"F{n}" for n in nums]

        titles.append((text, e.dxf.insert.x, e.dxf.insert.y, h, keys))
    return titles


def compute_floor_regions(
    titles: List[Tuple[str, float, float, float, List[str]]],
    msp_extents: BoundingBox2d,
    frames: List[BoundingBox2d],
) -> List[Tuple[str, List[str], BoundingBox2d]]:
    """根据标题位置 + 图框精确计算每张平面图的裁切区域。

    优先策略：把每个标题匹配到包含它的 TK 图框，以图框为精确区域。
    降级策略：若没有任何图框（例如其他楼栋 DXF 不遵循此约定），
    退回到原先"上下标题 Y 中点分界 + 全 X 范围"的粗切方式。

    Returns:
        List of (label, floor_keys, BoundingBox2d)
    """
    if not titles:
        return []

    # === 主路径：用图框裁切 ===
    if frames:
        regions = []
        used_frames = set()
        for text, x, y, h, keys in titles:
            # 找包含该标题点的图框
            matched = None
            for idx, fr in enumerate(frames):
                if idx in used_frames:
                    continue
                if fr.extmin.x <= x <= fr.extmax.x and fr.extmin.y <= y <= fr.extmax.y:
                    matched = (idx, fr)
                    break
            if matched is None:
                print(f"  警告: 标题 {text!r} (Y={y:.0f}) 未匹配到任何图框，跳过")
                continue
            idx, fr = matched
            used_frames.add(idx)
            label = "-".join(keys)
            regions.append((label, keys, fr))
        return regions

    # === 降级路径：无图框时按 Y 分带 ===
    print("  注意: 未检测到 TK 图框，改用 Y 分带降级裁切")
    titles_sorted = sorted(titles, key=lambda t: t[2])
    regions = []
    n = len(titles_sorted)
    msp_min_x = msp_extents.extmin.x
    msp_max_x = msp_extents.extmax.x
    for i, (text, x, y, h, keys) in enumerate(titles_sorted):
        if i == 0:
            y_min = y - 30000
        else:
            y_min = (titles_sorted[i - 1][2] + y) / 2
        if i == n - 1:
            y_max = y + 50000
        else:
            y_max = (y + titles_sorted[i + 1][2]) / 2
        label = "-".join(keys)
        bb = BoundingBox2d([Vec2(msp_min_x, y_min), Vec2(msp_max_x, y_max)])
        regions.append((label, keys, bb))
    return regions


def entity_in_region(entity, region: BoundingBox2d) -> bool:
    """判断实体是否在区域内（用包围盒中心点判定）。"""
    try:
        eb = bbox.extents([entity])
        if not eb.has_data:
            return False
        center = eb.center
        return region.inside(Vec3(center.x, center.y, 0))
    except Exception:
        return False


def render_region_to_svg(
    doc,
    msp,
    region: BoundingBox2d,
    output_path: str,
    label: str,
    entity_centers: dict,
    building_id: str,
) -> bool:
    """将指定区域内的实体渲染为独立 SVG（含 SVG_HOTZONE_SPEC 后处理 + JSON 骨架）。

    entity_centers: dict[id(entity)] = (cx, cy)，预先计算好以避免重复计算
    building_id: 用于 floor_map.json 骨架的 building 标识（可为占位，后续由标注工具替换）
    """
    ctx = RenderContext(doc)
    backend = SVGBackend()
    frontend = Frontend(ctx, backend)

    # 收集落在区域内的实体（用预计算的中心点）
    in_region = []
    region_min = region.extmin
    region_max = region.extmax
    for e in msp:
        center = entity_centers.get(id(e))
        if center is None:
            continue
        cx, cy = center
        if region_min.x <= cx <= region_max.x and region_min.y <= cy <= region_max.y:
            in_region.append(e)

    if not in_region:
        print(f"  [{label}] 区域内无实体，跳过")
        return False

    frontend.draw_entities(in_region)

    # 计算实际包围盒（区域内的真实 extents），按比例算纸面尺寸
    actual_bb = bbox.extents(in_region)
    if not actual_bb.has_data:
        print(f"  [{label}] 无法计算包围盒，跳过")
        return False

    sz = actual_bb.size
    # 把 DXF 单位（mm）按 1:1 mapping 到 SVG mm；最大宽 2000mm（以免文件过大）
    target_w = min(2000.0, sz.x / 10)  # CAD 单位假定为 mm，缩 10 倍输出
    target_h = target_w * (sz.y / sz.x) if sz.x > 0 else target_w

    page = drawing_layout.Page(
        width=target_w,
        height=target_h,
        units=drawing_layout.Units.mm,
    )
    settings = drawing_layout.Settings(fit_page=True)
    svg_string = backend.get_string(page, settings=settings)

    # === SVG_HOTZONE_SPEC v1.0 后处理 ===
    # 生效规则：
    #   - 线稿颜色 currentColor 化（供前端主题注入）
    #   - 加入 floor-plan / unit-hotspots 分层
    #   - 注入 .unit-* 状态 class 标准样式
    processed_svg, json_skeleton = _inject_hotzone_spec(
        svg_string,
        building_id=building_id,
        floor_label=label,
    )

    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(processed_svg, encoding="utf-8")

    # 同目录输出同名 .json 骨架，供后续 annotate_hotzone.py / extract_floor_map.py 填充
    json_path = out.with_suffix(".json")
    json_path.write_text(
        json.dumps(json_skeleton, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(
        f"  [{label}] 实体={len(in_region):>5d}  "
        f"viewBox={json_skeleton['viewport']['width']}x{json_skeleton['viewport']['height']}  "
        f"大小={len(processed_svg)//1024:>4d}KB  -> {output_path}"
    )
    return True


def main():
    parser = argparse.ArgumentParser(description="按楼层切分 DXF 为 N 个独立 SVG")
    parser.add_argument("input", help="输入 DXF 文件路径")
    parser.add_argument("output_dir", help="输出 SVG 目录")
    parser.add_argument("--prefix", default="floor", help='输出文件名前缀，默认 "floor"')
    parser.add_argument(
        "--building-id",
        default=None,
        help="floor_map.json 骨架的 building_id 占位值；省略时使用 --prefix",
    )
    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"错误: 输入文件不存在 - {args.input}", file=sys.stderr)
        sys.exit(1)

    print(f"读取 DXF: {args.input}")
    doc = ezdxf.readfile(args.input)
    msp = doc.modelspace()

    # 把墙图层实体颜色重映射到 WALL_ACI，使墙线在 SVG 中形成独立 CSS class（.CF0），
    # 便于后续样式加粗；不改变图层定义本身，仅覆写实体 dxf.color。
    wall_count = 0
    for e in msp:
        if e.dxftype() not in ("LINE", "LWPOLYLINE", "POLYLINE", "ARC", "CIRCLE"):
            continue
        layer = (e.dxf.layer or "").strip()
        if layer in WALL_HIGHLIGHT_LAYERS:
            try:
                e.dxf.color = WALL_ACI
                wall_count += 1
            except Exception:
                pass
    print(f"  墙线高亮: 已重映射 {wall_count} 条实体到 ACI={WALL_ACI} (class .CF0)")

    # 计算 Model Space 总体 extents
    print("计算 Model Space 包围盒...")
    msp_bb = bbox.extents(msp)
    if not msp_bb.has_data:
        print("错误: Model Space 无可计算包围盒", file=sys.stderr)
        sys.exit(1)
    print(f"  Model 范围: {msp_bb.extmin} ~ {msp_bb.extmax}")

    # 找楼层标题 + 图框
    print("扫描楼层标题...")
    titles = find_floor_titles(msp)
    print(f"  找到 {len(titles)} 条标题")
    for text, x, y, h, keys in sorted(titles, key=lambda t: -t[2]):
        print(f"    {text!r:<40s}  Y={y:>11.1f}  -> {keys}")

    print("扫描 TK 图框...")
    frames = find_title_frames(msp)
    print(f"  找到 {len(frames)} 个图框")

    if not titles:
        print("错误: 未找到任何楼层标题（含 'X层平面图' 的文字）", file=sys.stderr)
        sys.exit(1)

    # 计算楼层区域
    msp_2d = BoundingBox2d([
        Vec2(msp_bb.extmin.x, msp_bb.extmin.y),
        Vec2(msp_bb.extmax.x, msp_bb.extmax.y),
    ])
    regions = compute_floor_regions(titles, msp_2d, frames)
    print(f"\n共 {len(regions)} 个楼层区域")

    # 一次性预计算所有实体的中心点（避免每个区域都重算）
    print("预计算所有实体中心点（用于区域归属判定）...")
    entity_centers = {}
    cache = bbox.Cache()
    skipped = 0
    for e in msp:
        try:
            eb = bbox.extents([e], cache=cache)
            if eb.has_data:
                c = eb.center
                entity_centers[id(e)] = (c.x, c.y)
            else:
                skipped += 1
        except Exception:
            skipped += 1
    print(f"  完成: {len(entity_centers)} 个实体可定位，{skipped} 个跳过")

    print("\n开始渲染...")
    # 渲染每个区域
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    building_id = args.building_id or args.prefix
    success = 0
    for label, keys, region in regions:
        out_file = out_dir / f"{args.prefix}_{label}.svg"
        if render_region_to_svg(
            doc, msp, region, str(out_file), label, entity_centers, building_id
        ):
            success += 1

    print(f"\n完成: 成功渲染 {success}/{len(regions)} 个楼层")
    print(f"输出目录: {out_dir}")


if __name__ == "__main__":
    main()
