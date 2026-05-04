#!/usr/bin/env python3
from __future__ import annotations
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


def _setup_cjk_font_synonyms() -> None:
    """将常见 Windows 中文字体名映射到 Docker 中已安装的文泉驿微米黑（wqy-microhei.ttc）。

    DXF 平面图通常引用 simsun.ttc / simhei.ttf 等 Windows 专有字体；这些字体在
    Linux slim 镜像中不存在，ezdxf 会回退到 DejaVu（无 CJK 字形），中文显示为空框。
    通过 add_synonyms 将常见中文字体名（文件名形式 + 无扩展名 family 形式）重定向到
    已安装的 wqy-microhei.ttc，使平面图中文标注能在 Docker 容器内正常渲染。

    注：本地开发环境未安装 WQY 字体时此函数静默跳过，不影响主流程。
    """
    try:
        from ezdxf.fonts import fonts as _ezdxf_fonts
        mgr = _ezdxf_fonts.font_manager
        WQY_FILE = "wqy-microhei.ttc"
        # 首次运行新容器时字体缓存可能尚未包含 WQY，触发重建以扫描系统字体目录
        if not mgr.has_font(WQY_FILE):
            _ezdxf_fonts.build_system_font_cache()
        if not mgr.has_font(WQY_FILE):
            return  # WQY 未安装（本地开发环境），跳过
        # 文件名形式（DXF STYLE 表中引用 .ttf/.ttc 文件名的情况）
        _filename_aliases = (
            "simsun.ttc", "simsun.ttf",          # 宋体
            "simhei.ttf",                         # 黑体
            "simfang.ttf", "simfang_gb2312.ttf",  # 仿宋
            "simkai.ttf",                         # 楷体
            "msyh.ttf", "msyhbd.ttc", "msyhl.ttc",  # 微软雅黑系列
            "dengb.ttf", "dengl.ttf",             # 等线
            "方正仿宋_gbk.ttf", "方正黑体_gbk.ttf",  # 方正系列
        )
        # Family / 无扩展名形式（DXF STYLE 表中仅写字体族名的情况）
        _family_aliases = (
            "SimSun", "SimHei", "FangSong", "KaiTi",
            "Microsoft YaHei", "Microsoft JhengHei",
            "DengXian", "YouYuan", "NSimSun",
            "宋体", "黑体", "仿宋", "楷体",  # 中文名（极少数旧格式 DXF）
        )
        for alias in _filename_aliases + _family_aliases:
            mgr.add_synonyms({WQY_FILE: alias}, reverse=False)
    except Exception:
        pass  # 字体同义词配置失败不中断主流程，ezdxf 仍会尽力回退


_setup_cjk_font_synonyms()
from ezdxf.math import BoundingBox, BoundingBox2d, Vec2, Vec3
from lxml import etree

# ── CJK 字体补丁常量与函数 ──────────────────────────────────────────────────────
# MTEXT 内联字体代码正则：匹配 \f<fontname>.shx[|...]; 格式
# 中文 CAD MTEXT 中常见格式示例：{\fhztxt.shx|b0|i0|c134|p48;汉字文本}
_MTEXT_SHX_RE = re.compile(r'\\f([^|;{}\s]+\.(?:shx|shp))(\|[^;]*)?;', re.IGNORECASE)
_WQY_FILE = "wqy-microhei.ttc"


def _patch_doc_styles_for_cjk(doc) -> None:
    """将 DXF STYLE 表中 SHX+BigFont 组合替换为 WQY TTF，修复中文字符无法渲染的根本问题。

    中文 CAD 标准配置：
      font    = "simplex.shx"  (ASCII 基础字体)
      bigfont = "gbcbig.shx"  / "hztxt.shx"  (中文大字体，存放汉字字形)

    ezdxf 1.4.x 的 get_entity_font_face() 只读 style.dxf.font，**完全忽略 bigfont**，
    导致 SHX BigFont 中的全部汉字字形无法渲染，文本在 SVG 中输出为空白路径。

    修复策略：bigfont 字段非空 → 判定为中文文字样式
      → font 替换为 WQY TTF，清空 bigfont
      → ezdxf 渲染层改为用 WQY 的 Unicode 字形描出 SVG filled paths。

    本地开发环境未安装 WQY 时静默跳过，不影响主流程。
    """
    try:
        from ezdxf.fonts import fonts as _ffonts
        if not _ffonts.font_manager.has_font(_WQY_FILE):
            return
    except Exception:
        return

    patched = 0
    for style in doc.styles:
        bigfont = style.dxf.get("bigfont", "")
        if bigfont and bigfont.strip():
            style.dxf.font = _WQY_FILE
            style.dxf.bigfont = ""
            patched += 1
    if patched:
        print(f"  [CJK字体] {patched} 个 SHX+BigFont 样式 → {_WQY_FILE}")


def _patch_mtext_shx_fonts(msp) -> None:
    """修补 MTEXT 实体中内联 \\f 字体代码，将 SHX 字体替换为 WQY TTF。

    MTEXT 支持内联格式控制码覆盖当前样式的字体，例如：
      {\\fhztxt.shx|b0|i0|c134|p48;汉字文本}
    此时 STYLE 表中的字体替换不生效，必须同时修补文本内容本身。

    处理后变为：{\\fwqy-microhei.ttc|b0|i0|c134|p48;汉字文本}
    保留 |b0|i0|... 参数段，仅替换字体文件名部分。
    """
    try:
        from ezdxf.fonts import fonts as _ffonts
        if not _ffonts.font_manager.has_font(_WQY_FILE):
            return
    except Exception:
        return

    patched = 0
    for e in msp:
        if e.dxftype() != "MTEXT":
            continue
        raw_text = e.text
        if not raw_text or not _MTEXT_SHX_RE.search(raw_text):
            continue
        e.text = _MTEXT_SHX_RE.sub(
            lambda m: f'\\\\f{_WQY_FILE}' + (m.group(2) or '') + ';',
            raw_text,
        )
        patched += 1
    if patched:
        print(f"  [CJK字体] {patched} 个 MTEXT 内联 SHX 字体代码 → {_WQY_FILE}")

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
# 图层名常量从 floor_map.layer_constants 导入，保证与 detector 一致。
sys.path.insert(0, str(Path(__file__).resolve().parent))
from floor_map.layer_constants import (  # noqa: E402
    WALL_OUTLINE_LAYERS as _WALL_OUTLINE_LAYERS,
    WALL_FILL_LAYERS as _WALL_FILL_LAYERS,
)

WALL_HIGHLIGHT_LAYERS = set(_WALL_OUTLINE_LAYERS)
WALL_FILL_LAYERS = set(_WALL_FILL_LAYERS)
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

# ──────────────────────────────────────────────────────────────────────────────
# 标注图层过滤：渲染时默认排除，保留纯建筑线稿与热区标注
# 包含内容：轴号、尺寸标注（线+数字）、引线、公共文字、图框文字、房间编号/面积
# 可通过 --show-annotations 恢复显示，--hide-layers A,B,C 追加自定义图层
# ──────────────────────────────────────────────────────────────────────────────
ANNOTATION_LAYERS: frozenset = frozenset({
    # "AXIS",          # 轴线（定位线）
    # "AXIS_TEXT",     # 轴号圆圈/文字
    # "PUB_DIM",         #墙外标尺
    # "节点",          # 大样/节点引出符号图块
    
    "dote",             #安全柱线 
    "DIM",           # 通用尺寸
    "DIM_LEAD",      # 引线
    "DIM_SYMB",      # 标注符号（箭头/斜杠）
    "DIM_IDEN",      # 构件标识
    
    "PUB_HATCH",
    "PUB_TEXT",      # 公共说明文字
    "PUB_TITLE",     # 标题块
    "房间名称",       # 房间用途名称（"产业研发用房" 等）
    "房号",          # 房间编号圆圈图块
    "门窗编号",       # 门窗编号
    "门窗编号（回迁图纸）",
    "0-文字（防火门)",# 防火门标注文字
    
    "结构梁板",
    "幕墙编号",       # 幕墙节点编号
    "结构梁问题",     # 结构梁批注   

    #外框
    # "TK",
    # "0",
    # "0-立面(轮廓)",   # 立面轮廓线（块内含图纸说明文字）
    # "A-ANNO-TEXT",   # AIA 注释文字
    # "DIM_ELEV",      # 标高符号 + 数字（↑↓ 标高标注）

    # 轴网
    "轴线",
    "轴号",

    # 尺寸标注
    "DIMENSION",
    "S-ANNO-DIMS",   # AIA 标准：结构/建筑尺寸
    "A-ANNO-DIMS",
    # 文字/注释
    "DOTE",          # 文字注释（部分 CAD 惯例）
    "TEXT",          # 通用文字图层
    "公共文字",
    # 房间信息标注
    "NUM",           # 编号（英文惯例）
    "SPACE",         # 房间名称/面积标签（英文惯例）
    # 专项编号标注
    
    "S-TEXT",
    # 图框/标题栏（TK 图层含外框 LWPOLYLINE + "X层平面图"文字；
    # 外框用于楼层区域切割（find_title_frames），但该步骤在渲染前已完成，
    # 渲染时可安全排除，不影响分层逻辑）
    
    "0-电子签名",     # 电子签章图块图层
    "修改2016.01.22", # 变更记录图层
    "修改2016.03.17",
    "修改2015.10.15",
    "修改2015.11.04",
    
    "TITLE",
    # 剖切/大样符号
    "A-ANNO-SYMB",
    "SYMB",
    "DETAIL_SYMB",

    # 空调/设备标注
    "KT",            # 空调设备块（含 'K'/'A/C' 及尺寸标注）
    # 含文字的标注性图层（INSERT outer_layer 不在建筑线稿范围）
    "详细标注",       # 详细说明文字
    "0-面积框线",     # 面积框线说明
    
    "修改2018.01.25", # 变更记录图层（与其他修改云线一致）
    # 结构梁板内嵌文字图层（块定义使用，图层可见性方案覆盖）

    "B-TXT",          # 结构梁文字
    "FLOOR_UP_TEXT",  # 楼板配筋文字
    "FLOOR_DE_DIM",                         
    "FLOOR_REIN",                            
    "FLOOR_UP_REIN",     
    "BEAM_DE_TEXT",   # 梁详图文字
    "0-文字（管井）",  # 管井文字
    "G_model_dimn150",# 梁尺寸文字               
})

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
    actual_bb=None,
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

    # 存储楼层 DXF 实际包围盒，供 annotate_hotzone.py 做坐标变换用
    dxf_region = None
    if actual_bb is not None and actual_bb.has_data:
        dxf_region = {
            "min_x": float(actual_bb.extmin.x),
            "min_y": float(actual_bb.extmin.y),
            "max_x": float(actual_bb.extmax.x),
            "max_y": float(actual_bb.extmax.y),
        }
    skeleton = {
        "floor_id": None,  # 待绑定数据库 floor_id UUID
        "building_id": building_id,
        "floor_label": floor_label,
        "svg_version": None,  # 上传时由后端填充
        "viewport": {"width": vb_w, "height": vb_h},
        "dxf_region": dxf_region,
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
    hide_layers: frozenset = None,
) -> bool:
    """将指定区域内的实体渲染为独立 SVG（含 SVG_HOTZONE_SPEC 后处理 + JSON 骨架）。

    entity_centers: dict[id(entity)] = (cx, cy)，预先计算好以避免重复计算
    building_id: 用于 floor_map.json 骨架的 building 标识（可为占位，后续由标注工具替换）
    hide_layers: 渲染时排除的图层名称集合（None 则不过滤）
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

    # 按图层过滤标注/尺寸类实体（第一层：直接位于 MSP 中的实体）
    if hide_layers:
        before = len(in_region)
        in_region = [e for e in in_region if e.dxf.layer not in hide_layers]
        hidden = before - len(in_region)
        if hidden:
            print(f"  [{label}] 隐藏标注实体: {hidden} 个（图层过滤）")

    if not in_region:
        print(f"  [{label}] 区域内无实体，跳过")
        return False

    # 第二层：通过 ezdxf 图层可见性禁用，使渲染器在进入 INSERT 块内部时
    # 同样跳过属于这些图层的子实体（文字、标注等）。
    # 渲染完成后立即恢复，避免对同进程其他调用产生副作用。
    turned_off = []
    if hide_layers:
        for lyr_name in hide_layers:
            try:
                lyr = doc.layers.get(lyr_name)
                if lyr.is_on():
                    lyr.off()
                    turned_off.append(lyr)
            except Exception:
                pass  # 图层不存在于 DXF 中，跳过

    frontend.draw_entities(in_region)

    # 恢复图层可见性
    for lyr in turned_off:
        lyr.on()

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
        actual_bb=actual_bb,
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
    parser.add_argument(
        "--show-annotations",
        action="store_true",
        default=False,
        help="保留标注/尺寸/图框图层（默认已隐藏，仅渲染建筑线稿）",
    )
    parser.add_argument(
        "--hide-layers",
        default="",
        help="额外追加要隐藏的图层名，逗号分隔（与默认 ANNOTATION_LAYERS 合并）",
    )
    # ─── Stage 7：候选结构抽取 ───────────────────────────────
    parser.add_argument(
        "--extract-structures",
        action="store_true",
        default=False,
        help="启用 Floor Map v2 候选结构抽取，输出 <prefix>_<label>.candidates.json",
    )
    parser.add_argument(
        "--db-url",
        default="",
        help="PostgreSQL 连接串；提供后候选结构同时 UPSERT 到 floor_maps 表",
    )
    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"错误: 输入文件不存在 - {args.input}", file=sys.stderr)
        sys.exit(1)

    print(f"读取 DXF: {args.input}")
    doc = ezdxf.readfile(args.input)
    msp = doc.modelspace()

    # 修复中文字体：SHX+BigFont → WQY TTF（必须在 RenderContext 创建前完成）
    print("修复中文字体引用...")
    _patch_doc_styles_for_cjk(doc)
    _patch_mtext_shx_fonts(msp)

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
    # 逐条容错：Proxy 实体中 ARC/CIRCLE 非均匀缩放会抛 ProxyGraphicError，跳过即可
    print("计算 Model Space 包围盒...")
    _bb_cache = bbox.Cache()
    _bb_skipped = 0
    msp_bb = BoundingBox()
    for _e in msp:
        try:
            _eb = bbox.extents([_e], cache=_bb_cache)
            if _eb.has_data:
                msp_bb.extend([_eb.extmin, _eb.extmax])
        except Exception:
            _bb_skipped += 1
    if _bb_skipped:
        print(f"  包围盒计算：跳过 {_bb_skipped} 个问题实体（Proxy/非均匀缩放）")
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
    # 组装图层隐藏集合
    if args.show_annotations:
        hide_layers = None
        print("标注图层：全部保留（--show-annotations）")
    else:
        extra = {lyr.strip() for lyr in args.hide_layers.split(",") if lyr.strip()}
        hide_layers = ANNOTATION_LAYERS | extra
        print(f"标注图层：隐藏 {len(hide_layers)} 个（使用 --show-annotations 可恢复）")

    # 渲染每个区域
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    building_id = args.building_id or args.prefix
    success = 0
    for label, keys, region in regions:
        out_file = out_dir / f"{args.prefix}_{label}.svg"
        if render_region_to_svg(
            doc, msp, region, str(out_file), label, entity_centers, building_id,
            hide_layers=hide_layers,
        ):
            success += 1
            # ── Stage 7：候选结构抽取（仅 --extract-structures 开启时） ──
            if args.extract_structures:
                _stage7_extract_candidates(
                    msp=msp,
                    region=region,
                    label=label,
                    out_dir=out_dir,
                    prefix=args.prefix,
                    entity_centers=entity_centers,
                    db_url=args.db_url,
                    doc=doc,
                )

    print(f"\n完成: 成功渲染 {success}/{len(regions)} 个楼层")
    print(f"输出目录: {out_dir}")


def _entity_anchor(entity) -> tuple[float, float] | None:  # noqa: PYI016
    """估算实体锚点（用于区域归属判定）。

    展开 INSERT 后的虚拟实体未在 ``entity_centers`` 缓存中，
    用首个顶点 / start 点 / center 即可满足"落在哪个 region"的判定精度。
    """
    et = entity.dxftype()
    try:
        if et == "LINE":
            return (entity.dxf.start.x, entity.dxf.start.y)
        if et in ("CIRCLE", "ARC"):
            return (entity.dxf.center.x, entity.dxf.center.y)
        if et == "LWPOLYLINE":
            for p in entity.get_points("xy"):
                return (p[0], p[1])
        if et == "POLYLINE":
            for v in entity.vertices:
                return (v.dxf.location.x, v.dxf.location.y)
        if et in ("HATCH", "SOLID", "TRACE"):
            # HATCH 边界第一个点
            try:
                for path in entity.paths:
                    for v in path.vertices():
                        return (v[0], v[1])
            except Exception:  # noqa: BLE001
                return None
        if et == "TEXT" or et == "MTEXT":
            return (entity.dxf.insert.x, entity.dxf.insert.y)
    except Exception:  # noqa: BLE001
        return None
    return None


def _stage7_extract_candidates(
    msp,
    region,
    label: str,
    out_dir: Path,
    prefix: str,
    entity_centers: dict,
    db_url: str,
    doc=None,
) -> None:
    """Stage 7：对单个楼层区域抽取候选结构，并写入 JSON（可选 DB）。"""
    try:
        # 确保以脚本方式运行时也能找到同目录下的 floor_map 包
        _scripts_dir = str(Path(__file__).resolve().parent)
        if _scripts_dir not in sys.path:
            sys.path.insert(0, _scripts_dir)
        from floor_map.structure_detector import (  # noqa: WPS433
            extract_candidates_from_entities,
        )
    except ImportError as e:
        print(f"  [{label}] Stage 7: 跳过抽取（floor_map 包未安装: {e}）")
        return

    # 收集区域内实体 + 计算 bbox
    # 重要：业务层 wall/column/window 实体大量装在 INSERT block 中（与 _remap_layout 同样的现象），
    # 仅迭代 msp 顶层只能拿到屋顶/构架等少量直绘实体，导致业务层 detector 命中率几乎为 0。
    # 此处对 INSERT 调用 virtual_entities() 递归展开（一层 + 嵌套 INSERT 由 ezdxf 自动处理）。
    region_min = region.extmin
    region_max = region.extmax
    in_region = []

    def _expand(entity):
        """展开 INSERT 为虚拟实体（保留 layer / dxftype / 几何坐标）。"""
        if entity.dxftype() == "INSERT":
            try:
                for ve in entity.virtual_entities():
                    yield from _expand(ve)
            except Exception:  # noqa: BLE001
                # 损坏的 block 引用静默跳过
                return
        else:
            yield entity

    for top in msp:
        for e in _expand(top):
            # 顶层实体已有 entity_centers 缓存可用，但展开后的虚拟实体没有 → 现算 center
            if e is top:
                center = entity_centers.get(id(e))
            else:
                center = None
            if center is None:
                # 用实体几何重新估算 center（仅取首个顶点 / start 点足够做区域归属）
                center = _entity_anchor(e)
                if center is None:
                    continue
            cx, cy = center
            if region_min.x <= cx <= region_max.x and region_min.y <= cy <= region_max.y:
                in_region.append(e)
    if not in_region:
        return

    # bbox 取区域本身（避免逐实体重算包围盒耗时）
    bbox_t = (region_min.x, region_min.y, region_max.x, region_max.y)

    # 补充原始顶层 INSERT 实体（未展开），供语义检测 Strategy 1 用块名匹配。
    # 展开后的虚拟实体已丢失 INSERT 块名，Strategy 1 需要原始 INSERT 对象 + doc。
    if doc is not None:
        for top in msp:
            if top.dxftype() == "INSERT":
                center = entity_centers.get(id(top))
                if center is None:
                    center = _entity_anchor(top)
                if center is not None:
                    cx, cy = center
                    if region_min.x <= cx <= region_max.x and region_min.y <= cy <= region_max.y:
                        in_region.append(top)

    try:
        candidates = extract_candidates_from_entities(in_region, bbox_t, doc=doc)
    except Exception as ex:  # noqa: BLE001
        print(f"  [{label}] Stage 7 抽取失败: {ex}")
        return

    out_json = out_dir / f"{prefix}_{label}.candidates.json"
    out_json.write_text(
        json.dumps(candidates, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(
        f"  [{label}] Stage 7: outline={'✓' if candidates['outline'] else '✗'} "
        f"columns={sum(1 for s in candidates['structures'] if s.get('type') == 'column')} "
        f"semantic={sum(1 for s in candidates['structures'] if s.get('type') != 'column')} "
        f"windows={len(candidates['windows'])} "
        f"→ {out_json.name}"
    )

    if db_url:
        _stage7_upsert_db(db_url, label, candidates)


def _stage7_upsert_db(db_url: str, label: str, candidates: dict) -> None:
    """将候选结构 UPSERT 到 floor_maps 表。需 floor_id 映射（按 label 查 floors.floor_name）。

    floor_name 格式兼容两种惯例：
    - 脚本生成格式：'F6'（DXF 层名解析，前缀 F + 数字）
    - seed SQL 格式：'6F'（数字 + 后缀 F）
    匹配优先级：① 精确 label ② 互换格式（F6↔6F） ③ 楼层号（floor_number）
    """
    import re  # noqa: PLC0415

    try:
        import psycopg  # type: ignore
    except ImportError:
        print(f"  [{label}] Stage 7 DB 同步跳过：未安装 psycopg")
        return

    # 构造备选 floor_name 列表（消除 F6 vs 6F 格式差异）
    alt_names: list[str] = [label]
    # F6 → 6F
    m = re.match(r'^F(\d+)$', label)
    if m:
        alt_names.append(m.group(1) + 'F')
    # 6F → F6
    m2 = re.match(r'^(\d+)F$', label)
    if m2:
        alt_names.append('F' + m2.group(1))
    # 合并楼层如 F6-F8 → 取首段楼层号也加入备选
    m3 = re.match(r'^F(\d+)-', label)
    if m3:
        alt_names.append(m3.group(1) + 'F')
    # 去重保序
    seen: set[str] = set()
    alt_names = [x for x in alt_names if not (x in seen or seen.add(x))]  # type: ignore[func-returns-value]

    try:
        with psycopg.connect(db_url) as conn:
            with conn.cursor() as cur:
                # ① 按 floor_name 多格式匹配
                placeholders = ','.join(['%s'] * len(alt_names))
                cur.execute(
                    f"SELECT id FROM floors WHERE floor_name = ANY(ARRAY[{placeholders}]) LIMIT 1",  # noqa: S608
                    alt_names,
                )
                row = cur.fetchone()

                # ② 降级：按 floor_number 匹配（取 label 中首个数字）
                if not row:
                    num_match = re.search(r'(\d+)', label)
                    if num_match:
                        cur.execute(
                            "SELECT id FROM floors WHERE floor_number = %s LIMIT 1",
                            (int(num_match.group(1)),),
                        )
                        row = cur.fetchone()

                if not row:
                    print(f"  [{label}] Stage 7 DB: floors 中未找到匹配（尝试了 {alt_names}），跳过")
                    return
                floor_id = row[0]
                cur.execute(
                    """
                    INSERT INTO floor_maps (floor_id, candidates, candidates_extracted_at)
                    VALUES (%s, %s::jsonb, NOW())
                    ON CONFLICT (floor_id) DO UPDATE SET
                        candidates = EXCLUDED.candidates,
                        candidates_extracted_at = NOW()
                    """,
                    (floor_id, json.dumps(candidates, ensure_ascii=False)),
                )
            conn.commit()
        print(f"  [{label}] Stage 7 DB: 已 UPSERT 到 floor_maps (floor_id={floor_id})")
    except Exception as ex:  # noqa: BLE001
        print(f"  [{label}] Stage 7 DB UPSERT 失败: {ex}")


if __name__ == "__main__":
    main()
