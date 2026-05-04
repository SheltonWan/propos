"""一次性脚本：从完整 DXF 切出楼层区域实体，保存为小 DXF 测试 fixture。

用法：
    python -m scripts.floor_map.tests.make_fixtures

输出：
    scripts/floor_map/tests/fixtures/f17_region.dxf   (~200 KB，快速加载)

实现原理：
    1. 读取 cad_intermediate/building_a/floors/A座_F17.json 取 dxf_region
       注：F17 帧在 DXF 内有直接的 LINE/LWPOLYLINE 结构实体（COLU/WINDOW），
           可被 detector 检测；F11 帧的结构实体以 INSERT(块引用) 形式存储，
           当前 detector 不展开块，因此选 F17 作为真实数据测试用楼层。
    2. 加载完整 A座.dxf（~14s，仅此脚本运行一次）
    3. 过滤在 dxf_region ±5000mm 范围内的 LINE / LWPOLYLINE 实体
    4. 同时复制图层定义，确保新 DXF 保留原始图层名
    5. 写入 fixture 文件（后续测试直接读此文件，加载 <1s）
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import ezdxf
from ezdxf.layouts import Modelspace

# ── 路径常量 ──────────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parents[3]          # /path/to/propos
FULL_DXF = ROOT / "cad_intermediate" / "building_a" / "A座.dxf"
# F17 帧有直接 LWPOLYLINE/LINE 结构实体（COLU/WINDOW），适合 detector 单测
META_FLOOR = ROOT / "cad_intermediate" / "building_a" / "floors" / "A座_F17.json"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"
OUT_DXF = FIXTURES_DIR / "f17_region.dxf"

# 空间容差：扩展 dxf_region 5m，避免贴边实体被截断
PAD_MM: float = 5000.0


def _first_point(entity) -> tuple[float, float] | None:
    """取实体第一个坐标点，用于区域过滤（快速粗筛）。"""
    try:
        t = entity.dxftype()
        if t == "LINE":
            return (entity.dxf.start.x, entity.dxf.start.y)
        if t == "LWPOLYLINE":
            pts = list(entity.get_points("xy"))
            return (pts[0][0], pts[0][1]) if pts else None
        if t == "HATCH":
            # HATCH elevation 可能为 Vec3
            elev = entity.dxf.elevation
            return (float(elev.x), float(elev.y))
        if t == "INSERT":
            ins = entity.dxf.insert
            return (float(ins.x), float(ins.y))
    except Exception:  # noqa: BLE001
        pass
    return None


def _in_region(
    entity,
    min_x: float, min_y: float,
    max_x: float, max_y: float,
    pad: float,
) -> bool:
    pt = _first_point(entity)
    if pt is None:
        return False
    x, y = pt
    return (
        (min_x - pad) <= x <= (max_x + pad)
        and (min_y - pad) <= y <= (max_y + pad)
    )


def main() -> None:
    FIXTURES_DIR.mkdir(exist_ok=True)

    # 读取 F17 区域元数据
    meta = json.loads(META_FLOOR.read_text(encoding="utf-8"))
    r = meta["dxf_region"]
    min_x, min_y = r["min_x"], r["min_y"]
    max_x, max_y = r["max_x"], r["max_y"]
    print(f"F17 dxf_region: ({min_x:.0f},{min_y:.0f}) → ({max_x:.0f},{max_y:.0f})")

    # 加载完整 DXF（慢，仅此处一次）
    print("加载完整 DXF（约 14s）…", flush=True)
    doc = ezdxf.readfile(str(FULL_DXF))
    msp: Modelspace = doc.modelspace()

    # 过滤 F11 区域实体
    entities = [
        e for e in msp
        if _in_region(e, min_x, min_y, max_x, max_y, PAD_MM)
    ]
    print(f"F11 区域实体数：{len(entities)}")

    # 创建新 DXF，复制图层定义 + 实体
    new_doc = ezdxf.new(dxfversion="R2010")
    new_msp: Modelspace = new_doc.modelspace()

    # 复制需要的图层（仅复制 F11 实体涉及的图层）
    used_layers: set[str] = {e.dxf.layer for e in entities if hasattr(e.dxf, "layer")}
    for layer_name in used_layers:
        if layer_name not in new_doc.layers:
            try:
                src = doc.layers.get(layer_name)
                new_doc.layers.new(
                    name=layer_name,
                    dxfattribs={"color": src.dxf.color if src else 7},
                )
            except Exception:  # noqa: BLE001
                new_doc.layers.new(name=layer_name)

    # 逐实体拷贝
    copied = 0
    for entity in entities:
        try:
            t = entity.dxftype()
            if t == "LINE":
                new_msp.add_line(
                    entity.dxf.start,
                    entity.dxf.end,
                    dxfattribs={"layer": entity.dxf.layer},
                )
                copied += 1
            elif t == "LWPOLYLINE":
                pts = list(entity.get_points("xy"))
                new_msp.add_lwpolyline(
                    pts,
                    dxfattribs={"layer": entity.dxf.layer},
                    close=entity.closed,
                )
                copied += 1
        except Exception:  # noqa: BLE001
            pass

    print(f"复制实体数：{copied}")
    new_doc.saveas(str(OUT_DXF))
    size_kb = OUT_DXF.stat().st_size // 1024
    print(f"Fixture 已写入：{OUT_DXF}（{size_kb} KB）")


if __name__ == "__main__":
    main()
