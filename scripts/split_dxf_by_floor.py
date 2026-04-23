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
) -> List[Tuple[str, List[str], BoundingBox2d]]:
    """根据标题位置计算每张平面图的 Y 区域。

    Returns:
        List of (label, floor_keys, BoundingBox2d)
        label: 用于文件名的稳定 ID，如 "F6-F8-F10" / "屋顶"
    """
    if not titles:
        return []

    # 按 Y 升序排列
    titles_sorted = sorted(titles, key=lambda t: t[2])

    regions = []
    n = len(titles_sorted)
    msp_min_x = msp_extents.extmin.x
    msp_max_x = msp_extents.extmax.x

    for i, (text, x, y, h, keys) in enumerate(titles_sorted):
        # 区域 Y 下界
        if i == 0:
            # 最低标题：向下延伸到 Model 边界，但加缓冲
            y_min = y - 30000
        else:
            prev_y = titles_sorted[i - 1][2]
            y_min = (prev_y + y) / 2

        # 区域 Y 上界
        if i == n - 1:
            y_max = y + 50000
        else:
            next_y = titles_sorted[i + 1][2]
            y_max = (y + next_y) / 2

        label = "-".join(keys)
        # X 范围限制在 Model Space 内（标题 X 周围 ±50000，避免抓到立剖面）
        x_buffer = 30000
        x_min = max(msp_min_x, x - x_buffer)
        x_max = min(msp_max_x, x + x_buffer)
        bb = BoundingBox2d([Vec2(x_min, y_min), Vec2(x_max, y_max)])
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
) -> bool:
    """将指定区域内的实体渲染为独立 SVG。

    entity_centers: dict[id(entity)] = (cx, cy)，预先计算好以避免重复计算
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

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    Path(output_path).write_text(svg_string, encoding="utf-8")
    print(
        f"  [{label}] 实体={len(in_region):>5d}  "
        f"尺寸={target_w:>6.1f}x{target_h:>6.1f}mm  "
        f"大小={len(svg_string)//1024:>4d}KB  -> {output_path}"
    )
    return True


def main():
    parser = argparse.ArgumentParser(description="按楼层切分 DXF 为 N 个独立 SVG")
    parser.add_argument("input", help="输入 DXF 文件路径")
    parser.add_argument("output_dir", help="输出 SVG 目录")
    parser.add_argument("--prefix", default="floor", help='输出文件名前缀，默认 "floor"')
    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"错误: 输入文件不存在 - {args.input}", file=sys.stderr)
        sys.exit(1)

    print(f"读取 DXF: {args.input}")
    doc = ezdxf.readfile(args.input)
    msp = doc.modelspace()

    # 计算 Model Space 总体 extents
    print("计算 Model Space 包围盒...")
    msp_bb = bbox.extents(msp)
    if not msp_bb.has_data:
        print("错误: Model Space 无可计算包围盒", file=sys.stderr)
        sys.exit(1)
    print(f"  Model 范围: {msp_bb.extmin} ~ {msp_bb.extmax}")

    # 找楼层标题
    print("扫描楼层标题...")
    titles = find_floor_titles(msp)
    print(f"  找到 {len(titles)} 条标题")
    for text, x, y, h, keys in sorted(titles, key=lambda t: -t[2]):
        print(f"    {text!r:<40s}  Y={y:>11.1f}  -> {keys}")

    if not titles:
        print("错误: 未找到任何楼层标题（含 'X层平面图' 的文字）", file=sys.stderr)
        sys.exit(1)

    # 计算楼层区域
    msp_2d = BoundingBox2d([
        Vec2(msp_bb.extmin.x, msp_bb.extmin.y),
        Vec2(msp_bb.extmax.x, msp_bb.extmax.y),
    ])
    regions = compute_floor_regions(titles, msp_2d)
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
    success = 0
    for label, keys, region in regions:
        out_file = out_dir / f"{args.prefix}_{label}.svg"
        if render_region_to_svg(doc, msp, region, str(out_file), label, entity_centers):
            success += 1

    print(f"\n完成: 成功渲染 {success}/{len(regions)} 个楼层")
    print(f"输出目录: {out_dir}")


if __name__ == "__main__":
    main()
