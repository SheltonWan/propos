"""floor_map — DXF → Floor Map v2 候选结构抽取包。

模块结构:
    coordinate_mapper.py  DXF 世界坐标 → viewport 像素坐标转换
    outline_extractor.py  楼层外轮廓提取(最大闭合多段线)
    column_detector.py    柱子检测(矩形填充几何中心)
    window_detector.py    窗户检测(WINDOW 图层线段映射到外墙四边)
    structure_detector.py 编排器: 输出 schema_version=2.0 的候选 JSON

公共 API: extract_candidates(dxf_path, layer_config=None) -> dict
"""
from .structure_detector import extract_candidates  # noqa: F401
