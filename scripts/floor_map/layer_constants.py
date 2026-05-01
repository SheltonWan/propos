"""DXF 图层名常量（detector 与 split_dxf_by_floor 共享）。

实际样本（building_a）显示业务层图层带前缀 ``A座平面图、立剖面、节点|``，
而 detector 内部的 ``layer_normalize`` + ``endswith("|" + ln)`` 已能匹配前缀，
因此此处只列尾段图层名即可。
"""
from __future__ import annotations

# 外墙 / 外轮廓 / 剖切边线（用于 outline 抽取 + split_dxf 高亮）
WALL_OUTLINE_LAYERS: tuple[str, ...] = (
    "WALL",
    "0-WALL",
    "CURTWALL",
    "外墙",
    "0muqiang",
    "muqiang",
    # CAD 中用黄色描绘的建筑外轮廓
    "0-立面(轮廓)",
    "轮廓",
    "OUTLINE",
    # AIA 标准：建筑剖切边线（被剖到的墙/柱/楼板的双线轮廓）
    "A-SECT-MCUT",
    "A-SECT-MCUT-FINE",
)

# 墙体 / 柱体实心填充图层（HATCH/SOLID）
WALL_FILL_LAYERS: tuple[str, ...] = (
    "柱墙填充",
    "COLU_HATCH",
    "WALL_HATCH",
    "墙填充",
    "柱填充",
)

# 柱网图层
# - "柱网" / "屋顶柱"：本工程中文图层
# - "COLU" / "COLU-Model"：本工程英文图层（业务层主要在这里！v1 detector 漏配导致 0% 命中）
# - "COLU_HATCH"：填充
COLUMN_LAYERS: tuple[str, ...] = (
    "柱网",
    "柱墙填充",
    "屋顶柱",
    "COLU",
    "COLU-Model",
    "COLU_HATCH",
)

# 窗户图层
WINDOW_LAYERS: tuple[str, ...] = (
    "WINDOW",
    "窗户分隔",
)
