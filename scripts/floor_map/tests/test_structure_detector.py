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
