# Floor Structure Detector 命中率报告 v3

> 版本：v3 (修复后)  
> 数据源：`cad_intermediate/building_a/A座.dxf` → 24 楼层区域  
> 工具链：`scripts/split_dxf_by_floor.py --extract-structures`  
> 涉及代码：`scripts/floor_map/{outline_extractor,column_detector,window_detector,layer_constants}.py`

## 1. 修复要点

| 编号 | 根因 | 修复 |
|------|------|------|
| R1 | detector 默认图层仅含中文 (`柱网`/`窗户分隔`)；业务层 DXF 实际使用 `COLU` / `COLU-Model` / `COLU_HATCH` / `WINDOW` / `A-SECT-MCUT(-FINE)` 等英文图层 | 新增 `scripts/floor_map/layer_constants.py` 集中管理 5 组图层名集合；3 个 detector 全部从该常量导入 |
| R2 | Stage 7 `_stage7_extract_candidates` 仅迭代 MSP 顶层实体；业务层大量 wall/column/window 几何隐藏在 INSERT block 中 → 命中率几乎为 0 | 新增 `_expand()` 递归调用 `entity.virtual_entities()` 展开 INSERT；新增 `_entity_anchor()` 给虚拟实体重算锚点 |
| R3 | `outline_extractor` 仅取"最大闭合多段线"；业务层外墙以双线 LINE 绘制无单一闭合多段线 → 误选构件级微型多边形 (2.76×2.76 px) | 新增 fallback：闭合多段线 bbox 不足 5000mm 时退化为 outline+fill 图层所有几何端点的凸包（Andrew 单调链算法，零依赖） |
| R4 | `split_dxf_by_floor.py` 的 `WALL_HIGHLIGHT_LAYERS` / `WALL_FILL_LAYERS` 硬编码且与 detector 各自独立 | 改为从 `floor_map.layer_constants` 导入，单一事实来源 |
| R5 | 缺失业务层回归 fixture | 新增 `tests/test_business_layer_f11.py`（4 个断言），固定 outline/columns/windows 阈值，防止再次回退 |

## 2. 命中率对比

### 业务层（F* 系列）

| 项目 | v2 命中率 | v3 命中率 | 提升 |
|------|----------|----------|------|
| outline | 0/10 (0%) | **10/10 (100%)** | +100pp |
| columns | 0/10 (0%) | **10/10 (100%)** | +100pp |
| windows | 1/18 (5.6%)* | **10/10 (100%)** | +94pp |

\* v2 阶段把"区域"重复计入；v3 实测仅 10 个业务区域

### 全部 12 个区域明细

| 区域 | outline | columns | windows |
|------|---------|---------|---------|
| F6-F8-F10 | ✓ | 27 | 53 |
| F7-F9 | ✓ | 27 | 53 |
| F11 | ✓ | 38 | 55 |
| F12-F14 | ✓ | 23 | 53 |
| F13-F15 | ✓ | 23 | 53 |
| F16 | ✓ | 23 | 29 |
| F17 | ✓ | 23 | 47 |
| F18 | ✓ | 40 | 29 |
| F19-F21-F23 | ✓ | 23 | 29 |
| F20-F22 | ✓ | 23 | 29 |
| 屋顶 | ✓ | 30 | 57 |
| 屋顶构架 | ✓ | 0 | 0 |

## 3. 单元测试

```
$ python -m pytest scripts/floor_map/tests/ -q
23 passed, 7 warnings in 0.07s
```

新增测试：`test_business_layer_f11.py`
- `test_f11_outline_present`：outline 非空、bbox ≥200×200 px
- `test_f11_columns_threshold`：columns ≥10（实际 38）
- `test_f11_windows_threshold`：windows ≥15（实际 55）
- `test_f11_window_schema`：side ∈ {N,S,E,W}, offset≥0, width>0

## 4. 验收标准对照

| 指标 | 阈值 | 实际 | 结论 |
|------|------|------|------|
| 业务层 outline 命中率 | ≥80% | 100% | ✓ |
| 业务层 columns 命中率 | ≥80% | 100% | ✓ |
| 业务层 windows 命中率 | ≥70% | 100% | ✓ |
| F11 outline bbox | ≥200×200 px | 696×384 px | ✓ |
| F11 columns | ≥10 | 38 | ✓ |
| F11 windows | ≥15 | 55 | ✓ |

## 5. 后续建议（非阻塞）

1. 当前 outline fallback 用凸包，对凹形楼层（如 L 形）会包含外墙之外的空地。后续若需精确多边形，可引入 `shapely.concave_hull`（已确认 shapely 2.1.2 在 venv）。
2. 「屋顶构架」区域 columns/windows = 0 是预期（仅含构架线条），但若未来需要识别构架立柱可单独配置图层。
3. `_entity_anchor()` 对 HATCH 实体只取首个边界点，复杂 HATCH 区域归属可能不准；不影响当前业务层指标。

## 6. 关键文件清单

| 路径 | 变更类型 |
|------|---------|
| `scripts/floor_map/layer_constants.py` | 新增 |
| `scripts/floor_map/outline_extractor.py` | 加 fallback 凸包 |
| `scripts/floor_map/column_detector.py` | 默认图层切到常量 |
| `scripts/floor_map/window_detector.py` | 默认图层切到常量 |
| `scripts/split_dxf_by_floor.py` | INSERT 展开 + 共享常量 |
| `scripts/floor_map/tests/test_business_layer_f11.py` | 新增回归 fixture |
