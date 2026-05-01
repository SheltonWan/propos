"""coordinate_mapper — DXF 世界坐标 → viewport 像素坐标的线性映射。

DXF 单位通常为毫米,Floor Map v2 viewport 取像素值(默认 1200×900)。
策略: 等比缩放 + 居中,Y 轴翻转(DXF Y 朝上 → SVG Y 朝下)。
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Tuple

Point = Tuple[float, float]


@dataclass(frozen=True)
class Viewport:
    """viewport 像素尺寸 + 边距(留白)。"""

    width: int = 1200
    height: int = 900
    padding: int = 20

    def clamp(self) -> "Viewport":
        # 防御性:确保 [100, 4000] 范围
        w = max(100, min(4000, self.width))
        h = max(100, min(4000, self.height))
        return Viewport(w, h, self.padding)


@dataclass(frozen=True)
class CoordinateMapper:
    """从 DXF 边界框 (xmin,ymin,xmax,ymax) 构造的等比映射器。"""

    src_xmin: float
    src_ymin: float
    src_xmax: float
    src_ymax: float
    viewport: Viewport
    scale: float
    offset_x: float
    offset_y: float

    @classmethod
    def from_bbox(
        cls,
        xmin: float,
        ymin: float,
        xmax: float,
        ymax: float,
        viewport: Viewport | None = None,
    ) -> "CoordinateMapper":
        vp = (viewport or Viewport()).clamp()
        if xmax <= xmin or ymax <= ymin:
            raise ValueError("非法边界框: 宽或高 ≤ 0")
        src_w = xmax - xmin
        src_h = ymax - ymin
        avail_w = vp.width - 2 * vp.padding
        avail_h = vp.height - 2 * vp.padding
        scale = min(avail_w / src_w, avail_h / src_h)
        # 居中偏移
        rendered_w = src_w * scale
        rendered_h = src_h * scale
        offset_x = vp.padding + (avail_w - rendered_w) / 2
        offset_y = vp.padding + (avail_h - rendered_h) / 2
        return cls(
            src_xmin=xmin,
            src_ymin=ymin,
            src_xmax=xmax,
            src_ymax=ymax,
            viewport=vp,
            scale=scale,
            offset_x=offset_x,
            offset_y=offset_y,
        )

    def map_point(self, p: Point) -> Point:
        """DXF 点 → viewport 像素点 (Y 翻转,保留 2 位小数)。"""
        x_dxf, y_dxf = p
        px = self.offset_x + (x_dxf - self.src_xmin) * self.scale
        # Y 翻转: DXF Y 越大 = 上方,SVG 像素 Y 越大 = 下方
        py = self.offset_y + (self.src_ymax - y_dxf) * self.scale
        return (round(px, 2), round(py, 2))

    def map_points(self, pts: Iterable[Point]) -> list[Point]:
        return [self.map_point(p) for p in pts]

    def map_length(self, length: float) -> float:
        return round(length * self.scale, 2)


def compute_bbox(points: Iterable[Point]) -> Tuple[float, float, float, float]:
    """计算 (xmin, ymin, xmax, ymax)。"""
    xs: list[float] = []
    ys: list[float] = []
    for x, y in points:
        xs.append(x)
        ys.append(y)
    if not xs:
        raise ValueError("空点集,无法计算边界框")
    return (min(xs), min(ys), max(xs), max(ys))
