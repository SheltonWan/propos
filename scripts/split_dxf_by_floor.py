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

# 强制归类到专属标记颜色的图层。重要：ezdxf SVGBackend 生成的
# CSS class 名是「按出现顺序递增」（.C1, .C2, .C3 ...），不是 ACI 值。
# 所以不能预设 `.CF0` / `.CFA` 选择器，必须渲染后扫描 CSS 找到
# 结果颜色等于我们标记色的那个 class，再动态生成覆盖规则。
WALL_HIGHLIGHT_LAYERS = {
    "WALL", "CURTWALL", "外墙", "0muqiang", "muqiang",
    "0-立面(轮廓)",  # CAD 中用黄色描绘的建筑外轮廓
    "轮廓", "OUTLINE",
    # AIA 标准：建筑剖切边线（被剖到的墙/柱/楼板的双线轮廓）
    "A-SECT-MCUT", "A-SECT-MCUT-FINE",
}
# 墙体/柱体实心填充图层：双线之间的填充 HATCH/SOLID 都在这些图层上，
# 配合双线一起渲染才能呈现 CADview 中"实心黄墙"的视觉效果。
WALL_FILL_LAYERS = {
    "柱墙填充", "COLU_HATCH", "WALL_HATCH", "墙填充", "柱填充",
}
# 标记色：选生鲜颜色以便后处理唯一识别。
WALL_MARKER_RGB = (255, 0, 240)   # #ff00f0 品红 — 墙双线
WALL_MARKER_HEX = "#ff00f0"
WALL_FILL_MARKER_RGB = (0, 255, 240)  # #00fff0 青 — 墙体填充 HATCH/SOLID
WALL_FILL_MARKER_HEX = "#00fff0"
HATCH_MARKER_RGB = (240, 255, 0)  # #f0ff00 黄绿 — 其他 HATCH（保温/铺装等）
HATCH_MARKER_HEX = "#f0ff00"

# CAD 线稿中性样式：将原 DXF 图层的硬编码 RGB 颜色改为 currentColor，
# 由外层容器通过 CSS `color` 属性（Admin/uni-app）或 ColorFilter（Flutter）注入主题色。
NEUTRAL_CAD_STYLE = """
      /* CAD 线稿：颜色随外层 color 属性；线宽不随缩放改变 */
      #floor-plan * { vector-effect: non-scaling-stroke; }
"""

# 墙线覆盖样式模板（{cls} 在后处理时被替换为实际 class 名）
# 重要：建筑墙体在 CAD 中按"双线法"绘制（内外两条细线表示墙厚），
# 不能加粗成单条粗线，否则两条线会糊成一团失去墙体厚度表达。
# 颜色随主题 currentColor 注入，不改线宽，保留 ezdxf 默认的细线粗细。
WALL_OVERRIDE_TPL = """
      /* 墙双线（WALL/CURTWALL/外墙/立面轮廓）—— 全不透明描边，随主题色 */
      #floor-plan .{cls} {{
        stroke: currentColor !important;
        stroke-opacity: 1 !important;
        fill: none !important;
      }}
"""

# 墙体填充覆盖样式：透明度略高于普通 HATCH（0.35 vs 0.18），随主题色填充。
WALL_FILL_OVERRIDE_TPL = """
      /* 墙体填充 HATCH/SOLID —— 实心黄色，连接双线拼出“实墙”象征 */
      #floor-plan .{cls} {{
        fill: currentColor !important;
        fill-opacity: 0.35 !important;
        stroke: none !important;
      }}
"""

HATCH_OVERRIDE_TPL = """
      /* 柱墙/保温 HATCH —— 仅这类降透明度 */
      #floor-plan .{cls} {{
        fill: currentColor !important;
        fill-opacity: 0.18 !important;
        stroke: none !important;
      }}
"""

# 主线条覆盖样式：在没有显式 wall layer 标识的 CAD 里（绝大多数线条画在 layer-0
# 由 INSERT 宿主图层决定颜色，全被 ezdxf 聚到同一 class），通过启发式识别
# 「hits 最多的 stroke 类」并增强其视觉权重，让柱填充与之形成"实墙"锚点。
MAIN_LINE_OVERRIDE_TPL = """
      /* 主建筑线条（启发式识别）—— 加深显示，与柱填充形成视觉连接 */
      #floor-plan .{cls} {{
        stroke-opacity: 0.95 !important;
        stroke-width: 1.4 !important;
      }}
"""


def _find_main_stroke_class(svg_text: str, style_text: str) -> str:
    """启发式识别"主线条 class"。

    规则：在所有 stroke 类（fill: none 的 class）中，找 path 数量最多的那个；
    且必须显著超过第二名（hits >= 2 倍第二名），否则返回空。这样能在标准
    建筑平面图（墙线为主）里命中"主墙线 + 默认色线条"那个 class，
    在轴线/标注混杂的图上则不会乱染。
    """
    # 收集所有 stroke 类（fill: none）
    stroke_classes = []
    for m in re.finditer(r"\.(C[0-9A-F]+)\s*\{([^}]*)\}", style_text):
        cls, body = m.group(1), m.group(2)
        if "fill: none" in body and "stroke:" in body and "stroke: none" not in body:
            stroke_classes.append(cls)
    if not stroke_classes:
        return ""
    # 数每个 class 在 path 中的 hits
    hits = {}
    for cls in stroke_classes:
        hits[cls] = len(re.findall(rf'class="{cls}"', svg_text))
    sorted_cls = sorted(hits.items(), key=lambda x: -x[1])
    if not sorted_cls:
        return ""
    top_cls, top_n = sorted_cls[0]
    second_n = sorted_cls[1][1] if len(sorted_cls) > 1 else 0
    # 仅当显著最多（>= 2 倍第二名 且 >= 100 条）才认定
    if top_n >= 100 and top_n >= second_n * 2:
        return top_cls
    return ""


def _find_class_by_color(style_text: str, *, stroke_hex: str = None, fill_hex: str = None) -> str:
    """在 ezdxf 输出的 CSS 中查找 stroke/fill 为指定 hex 颜色的 class 名。

    ezdxf 生成的 class 名是递增的伪 ID（.C1, .C2, ...），不是 ACI 值；
    必须根据颜色反查才能识别出哪个 class 对应我们的标记实体。
    """
    target = (stroke_hex or fill_hex or "").lower()
    if not target:
        return ""
    for m in re.finditer(r"\.(C[0-9A-F]+)\s*\{([^}]*)\}", style_text):
        name, body = m.group(1), m.group(2).lower()
        if stroke_hex and re.search(r"stroke\s*:\s*" + re.escape(target), body):
            return name
        if fill_hex and re.search(r"fill\s*:\s*" + re.escape(target), body):
            return name
    return ""


def _neutralize_cad_colors(style_text: str) -> str:
    """将 CAD 图层样式中的 stroke/fill 硬编码颜色替换为 currentColor。

    - `stroke: #rrggbb` → `stroke: currentColor`
    - `fill: #rrggbb`   → `fill: currentColor`
    - `stroke-width: <large>` → `stroke-width: 1`（配合 vector-effect: non-scaling-stroke）

    注意：不再修改 fill-opacity——ezdxf 把 TEXT 也渲染为带 fill 的 path，
    粗暴降透明度会让所有文字一起糊掉。HATCH 实体改由 HATCH_ACI 重映射后
    通过专属 .CFA class 单独降透明度。
    """
    # stroke: #xxx → currentColor
    text = re.sub(
        r"stroke\s*:\s*#[0-9a-fA-F]{3,8}",
        "stroke: currentColor",
        style_text,
    )
    # fill: #xxx → currentColor（不动 fill-opacity）
    text = re.sub(
        r"fill\s*:\s*#[0-9a-fA-F]{3,8}",
        "fill: currentColor",
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

    # 2. 识别带标记色的 class（在中性化之前做，否则颜色被抹除）
    existing_defs = root.findall(f"{SVG}defs")
    raw_style_text = ""
    for defs in existing_defs:
        for style_el in defs.findall(f"{SVG}style"):
            if style_el.text:
                raw_style_text += "\n" + style_el.text

    wall_class = _find_class_by_color(raw_style_text, stroke_hex=WALL_MARKER_HEX)
    # 墙体填充 HATCH/SOLID：ezdxf 可能用 fill 也可能用 stroke 表达，两种都查
    wall_fill_class = (
        _find_class_by_color(raw_style_text, fill_hex=WALL_FILL_MARKER_HEX)
        or _find_class_by_color(raw_style_text, stroke_hex=WALL_FILL_MARKER_HEX)
    )
    hatch_class = _find_class_by_color(raw_style_text, fill_hex=HATCH_MARKER_HEX)

    # 启发式：识别"主线条 class"——这套 CAD 把墙双线和默认色其他线条画在一起，
    # 渲染后聚合到 hits 数量最多的 stroke 类。把它的视觉权重提升（深色 + 略粗），
    # 让黄色柱填充与之形成"实墙"的连续视觉锚点。
    # 仅当 hits 远超第二名时才认定（避免误染所有线条）。
    main_stroke_class = _find_main_stroke_class(svg_string, raw_style_text)

    # 3. 合并现有 defs/style 并中性化颜色
    merged_style_text = NEUTRAL_CAD_STYLE
    if raw_style_text:
        merged_style_text += "\n" + _neutralize_cad_colors(raw_style_text)
    for defs in existing_defs:
        root.remove(defs)
    # 追加针对识别出的 class 的覆盖规则使其优先级高于中性化后的通用规则
    if wall_fill_class:
        merged_style_text += WALL_FILL_OVERRIDE_TPL.format(cls=wall_fill_class)
    if wall_class:
        merged_style_text += WALL_OVERRIDE_TPL.format(cls=wall_class)
    if hatch_class:
        merged_style_text += HATCH_OVERRIDE_TPL.format(cls=hatch_class)
    if main_stroke_class:
        merged_style_text += MAIN_LINE_OVERRIDE_TPL.format(cls=main_stroke_class)
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

    # 把墙图层、HATCH/SOLID 重映射为标记 RGB（使用 entity.rgb / true_color，覆盖 ACI/图层色）。
    # 后处理阶段在生成的 SVG CSS 中反查该颜色对应的 class 名后，动态添加样式覆盖。
    # 重要：必须递归遍历所有 block 定义，因为外墙数据常被装进
    # "19层" / "11层节点" / "pm3" 等子 block 中，仅扫 MSP 会遗漏大量实体。
    wall_count = 0
    wall_fill_count = 0
    hatch_count = 0

    def _remap_layout(layout):
        nonlocal wall_count, wall_fill_count, hatch_count
        for e in layout:
            et = e.dxftype()
            layer = (e.dxf.layer or "").strip()
            if et in ("LINE", "LWPOLYLINE", "POLYLINE", "ARC", "CIRCLE"):
                if layer in WALL_HIGHLIGHT_LAYERS:
                    try:
                        e.rgb = WALL_MARKER_RGB
                        wall_count += 1
                    except Exception:
                        pass
            elif et in ("HATCH", "SOLID", "TRACE"):
                # 墙体/柱体填充图层 → 实心黄填充；其他 HATCH（保温、铺装、阴影）→ 通用低透明灰
                try:
                    if layer in WALL_FILL_LAYERS:
                        e.rgb = WALL_FILL_MARKER_RGB
                        wall_fill_count += 1
                    else:
                        e.rgb = HATCH_MARKER_RGB
                        hatch_count += 1
                except Exception:
                    pass

    _remap_layout(msp)
    for block in doc.blocks:
        if block.name.startswith("*"):
            continue
        _remap_layout(block)

    print(f"  墙线高亮: {wall_count} 条 → RGB={WALL_MARKER_HEX}")
    print(f"  墙体填充: {wall_fill_count} 个 → RGB={WALL_FILL_MARKER_HEX}")
    print(f"  填充归一: {hatch_count} 个 HATCH/SOLID → RGB={HATCH_MARKER_HEX}")

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
