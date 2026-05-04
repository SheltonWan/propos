"""structure_detector(编排器)单元测试。"""
from __future__ import annotations

from scripts.floor_map.structure_detector import extract_candidates


def test_extract_candidates_full_pipeline(synthetic_dxf):
    result = extract_candidates(synthetic_dxf)
    assert result["schema_version"] == "2.0"
    assert result["viewport"]["width"] == 1200
    assert result["viewport"]["height"] == 900
    assert result["outline"] is not None
    assert result["outline"]["type"] == "polygon"
    assert len(result["structures"]) == 4
    assert all(s["type"] == "column" for s in result["structures"])
    assert all(s["source"] == "auto" for s in result["structures"])
    assert len(result["windows"]) == 4
    for w in result["windows"]:
        assert "source" not in w


def test_extract_candidates_missing_dxf(tmp_path):
    import pytest
    with pytest.raises(Exception):  # noqa: B017
        extract_candidates(str(tmp_path / "nonexistent.dxf"))


# ── 真实数据测试（依赖 f17_region.dxf fixture）─────────────────────────────────

def test_real_f17_full_pipeline(real_f17_dxf):
    """F17 楼层端到端：extract_candidates_from_entities 返回合法结果。

    使用 F17 JSON 中的 dxf_region 作为坐标基准（viewport 使用默认 1200×900），
    验证整个 pipeline（outline + columns + windows）均成功运行。

    注：A座_F17.json 的 viewport 字段（1000000×706300）是 DXF 图纸尺寸而非像素尺寸；
    CoordinateMapper.Viewport.clamp() 会将其截断到 [100, 4000]，
    因此此测试不断言与 JSON 中的原始尺寸一致。
    """
    import ezdxf
    from scripts.floor_map.structure_detector import extract_candidates_from_entities

    dxf_path, _, meta = real_f17_dxf
    r = meta["dxf_region"]

    doc = ezdxf.readfile(dxf_path)
    entities = list(doc.modelspace())
    bbox = (r["min_x"], r["min_y"], r["max_x"], r["max_y"])

    result = extract_candidates_from_entities(entities, bbox, doc=doc)

    assert result["schema_version"] == "2.0"
    assert result["outline"] is not None, "F17 未检测到外轮廓"
    assert len(result["structures"]) >= 15, (
        f"期望 ≥15 根柱，实际: {len(result['structures'])}"
    )
    assert len(result["windows"]) >= 15, (
        f"期望 ≥15 扇窗，实际: {len(result['windows'])}"
    )
    # viewport 字段存在且为正整数
    vp = result["viewport"]
    assert vp["width"] > 0
    assert vp["height"] > 0
