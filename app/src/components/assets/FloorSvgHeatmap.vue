<template>
  <!--
    楼层 SVG 热区图
    渲染策略（与 flutter_app/_FloorImageViewer 对齐）：
      • props.svgPath 非空（H5 / App-plus）：fetch 真实 CAD-SVG → v-html 注入 →
        DOM querySelectorAll('[data-unit-id]') 加 CSS class + 绑 click → emit unitId
      • 否则：使用前端按业态规则生成的手绘示意 SVG，叠加透明覆盖层捕获点击
    ⚠️ uni-app Vue 3 模板编译器不会给模板内 <svg> 子元素添加 SVG namespace，
       因此一律走字符串 + v-html 的方式注入。
  -->
  <view class="svg-heatmap" :style="containerStyle">
    <!-- SVG 渲染容器（v-html 注入；DOM 操作通过 .svg-heatmap__canvas 选择器定位） -->
    <view
      class="svg-heatmap__canvas"
      :class="useRealSvg ? 'svg-heatmap__canvas--real' : 'svg-heatmap__canvas--fallback'"
      :style="canvasStyle"
      v-html="svgHtml"
    />
    <!-- 透明点击覆盖层：仅手绘模式启用，按百分比对齐房间矩形 -->
    <view v-if="!useRealSvg" class="svg-heatmap__overlay">
      <view
        v-for="room in roomRects"
        :key="room.unitId"
        :style="tapZoneStyle(room)"
        @tap.stop="onRoomTap(room.unitId)"
      />
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { buildFileProxyUrl } from '@/constants/api_paths'
import type { FloorHeatmapUnit, LayerMode, PropertyType, UnitStatus } from '@/types/assets'

// ── Props & Emits ───────────────────────────────────────────────────────────


const props = defineProps<{
  units: FloorHeatmapUnit[]
  propertyType: PropertyType
  /** 当前视图图层（出租状态 / 到期预警） */
  layer: LayerMode
  /** 当前选中的 unit_id（来自父组件双向绑定） */
  selectedId: string | null
  /**
   * 后端返回的真实 CAD-SVG 相对路径（如 `floors/{building_id}/{floor_id}.svg`）。
   * 非空时通过 `/api/files/...` 代理加载真实平面图（与 Flutter 端 _FloorImageViewer 对齐），
   * 为空时回退到手绘示意图。
   */
  svgPath?: string | null
  /** 缩放比例（默认 1.0 = 适配屏幕宽度；> 1 放大，< 1 缩小；由父组件 zoom 控制传入） */
  scale?: number
}>()

const emit = defineEmits<{
  (e: 'unit-tap', unitId: string): void
}>()

// ── 状态标签 ────────────────────────────────────────────────────────────────

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已租',
  vacant: '空置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租中',
}

// ── SVG 坐标常量 ─────────────────────────────────────────────────────────────

/** 写字楼 / 公寓 SVG 画布尺寸 */
const VW = 700
const VH = 320
/** 北侧房间带高度 */
const NORTH_ZONE_H = 90
/** 走廊高度 */
const CORRIDOR_H = 28

// 核心筒位置（写字楼）
const coreX = 252
const coreY = 1
const coreW = 196
const coreH = VH - 2
// 核心筒内电梯位置（4 部）
const elevatorXs = [263, 296, 329, 362]
// 楼梯位置（2 处）
const stairXs = [263, 353]

/** 商铺 SVG 画布尺寸 */
const RETAIL_VW = 700
const RETAIL_VH = 180

/** 公寓 SVG 画布（重用 VW×VH），走廊起始 Y */
const APT_CORRIDOR_Y = 90

/** viewBox 宽高（按业态选择） */
const vbW = computed(() => (props.propertyType === 'retail' ? RETAIL_VW : VW))
const vbH = computed(() => (props.propertyType === 'retail' ? RETAIL_VH : VH))

// ── 渲染容器尺寸 ─────────────────────────────────────────────────────────────

/** 屏幕可用宽度（自适应手机屏幕，作为 scale=1 时的基准宽度） */
const containerWidth = ref(uni.getSystemInfoSync().windowWidth)

/** 实际渲染宽度 = 屏幕基准宽度 × 缩放比例 */
const renderWidth = computed(() => Math.round(containerWidth.value * (props.scale ?? 1.0)))

const containerStyle = computed(() => {
  const w = renderWidth.value
  // 真实 SVG 已解析到 viewBox 时使用真实比例，否则回退手绘常量（加载期间的过渡状态）
  const effVbW = (useRealSvg.value && realSvgVbW.value !== null) ? realSvgVbW.value : vbW.value
  const effVbH = (useRealSvg.value && realSvgVbH.value !== null) ? realSvgVbH.value : vbH.value
  const h = Math.round((w * effVbH) / effVbW)
  return {
    position: 'relative' as const,
    alignSelf: 'flex-start' as const, // 内联样式强制靠左，避免 App-Plus scoped CSS 失效
    marginLeft: '0',
    width: `${w}px`,
    height: `${h}px`,
  }
})

const canvasStyle = computed(() => {
  const w = renderWidth.value
  const effVbW = (useRealSvg.value && realSvgVbW.value !== null) ? realSvgVbW.value : vbW.value
  const effVbH = (useRealSvg.value && realSvgVbH.value !== null) ? realSvgVbH.value : vbH.value
  const h = Math.round((w * effVbH) / effVbW)
  return {
    width: `${w}px`,
    height: `${h}px`,
  }
})

// ── 颜色映射 ─────────────────────────────────────────────────────────────────

/**
 * 按图层计算房间着色
 * 返回 { fill, stroke, opacity }
 */
function getRoomColor(
  unit: FloorHeatmapUnit,
  layer: LayerMode,
): { fill: string; stroke: string; opacity: number } {
  const status = unit.current_status

  // 非可租区域统一灰色无论何种图层
  if (status === 'non_leasable') {
    return {
      fill: 'var(--color-muted-foreground)',
      stroke: 'var(--color-border)',
      opacity: 0.18,
    }
  }
  if (status === 'renovating') {
    return {
      fill: 'var(--color-info)',
      stroke: 'var(--color-info)',
      opacity: 0.28,
    }
  }
  if (status === 'pre_lease') {
    return {
      fill: 'var(--color-warning)',
      stroke: 'var(--color-warning)',
      opacity: 0.38,
    }
  }
  if (status === 'vacant') {
    return {
      fill: 'var(--color-destructive)',
      stroke: 'var(--color-destructive)',
      opacity: 0.30,
    }
  }

  // leased / expiring_soon
  if (layer === 'expiry') {
    if (status === 'expiring_soon') {
      return {
        fill: 'var(--color-destructive)',
        stroke: 'var(--color-destructive)',
        opacity: 0.55,
      }
    }
    // leased — 计算距合同到期剩余天数
    const end = unit.contract_end_date
    if (end) {
      const days = Math.ceil((new Date(end).getTime() - Date.now()) / 86400000)
      if (days < 90) {
        return {
          fill: 'var(--color-destructive)',
          stroke: 'var(--color-destructive)',
          opacity: 0.55,
        }
      }
      if (days < 365) {
        return {
          fill: 'var(--color-warning)',
          stroke: 'var(--color-warning)',
          opacity: 0.48,
        }
      }
    }
    return {
      fill: 'var(--color-success)',
      stroke: 'var(--color-success)',
      opacity: 0.40,
    }
  }

  // status 图层（默认）
  if (status === 'expiring_soon') {
    return {
      fill: 'var(--color-warning)',
      stroke: 'var(--color-warning)',
      opacity: 0.48,
    }
  }
  return {
    fill: 'var(--color-primary)',
    stroke: 'var(--color-primary)',
    opacity: 0.38,
  }
}

// ── 房间矩形布局生成 ─────────────────────────────────────────────────────────

interface RoomRect {
  unitId: string
  label: string
  statusLabel: string
  tenantName: string | null
  fill: string
  stroke: string
  opacity: number
  status: UnitStatus
  x: number
  y: number
  w: number
  h: number
}

/**
 * 写字楼布局：南北两排房间，绕核心筒分布
 * 核心筒占 x=[252,448]，北排 y=[1,89]，南排 y=[119,319]
 */
function calcOfficeLayout(units: FloorHeatmapUnit[]): RoomRect[] {
  const rects: RoomRect[] = []
  if (!units.length) return rects

  // 核心筒左右可用区域
  const leftW = coreX - 1      // 0 ~ 251
  const rightX = coreX + coreW // 448
  const rightW = VW - rightX   // 700 - 448 = 252

  const NORTH_H = NORTH_ZONE_H - 1
  const SOUTH_Y = NORTH_ZONE_H + CORRIDOR_H
  const SOUTH_H = VH - SOUTH_Y - 1

  // 分配北侧 40%，南侧 60%
  const northCount = Math.max(1, Math.round(units.length * 0.4))
  const southCount = units.length - northCount

  const northLeft = Math.ceil(northCount / 2)
  const northRight = northCount - northLeft
  const southLeft = Math.ceil(southCount / 2)
  const southRight = southCount - southLeft

  // 北左
  for (let i = 0; i < northLeft; i++) {
    const u = units[i]
    if (!u) continue
    const w = Math.floor(leftW / northLeft)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: 1 + i * w, y: 1, w: w - 1, h: NORTH_H })
  }
  // 北右
  for (let i = 0; i < northRight; i++) {
    const u = units[northLeft + i]
    if (!u) continue
    const w = Math.floor(rightW / northRight)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: rightX + i * w, y: 1, w: w - 1, h: NORTH_H })
  }
  // 南左
  for (let i = 0; i < southLeft; i++) {
    const u = units[northCount + i]
    if (!u) continue
    const w = Math.floor(leftW / southLeft)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: 1 + i * w, y: SOUTH_Y, w: w - 1, h: SOUTH_H })
  }
  // 南右
  for (let i = 0; i < southRight; i++) {
    const u = units[northCount + southLeft + i]
    if (!u) continue
    const w = Math.floor(rightW / southRight)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: rightX + i * w, y: SOUTH_Y, w: w - 1, h: SOUTH_H })
  }
  return rects
}

/** 商铺布局：横排一行（后勤通道在顶部 32px） */
function calcRetailLayout(units: FloorHeatmapUnit[]): RoomRect[] {
  const rects: RoomRect[] = []
  if (!units.length) return rects
  const unitW = Math.floor((RETAIL_VW - 2) / units.length)
  const UNIT_Y = 33
  const UNIT_H = RETAIL_VH - 33 - 16
  units.forEach((u, i) => {
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: 1 + i * unitW, y: UNIT_Y, w: unitW - 1, h: UNIT_H })
  })
  return rects
}

/** 公寓布局：南北两排（交通核左侧 72px 除外），走廊在 y=90 处 */
function calcApartmentLayout(units: FloorHeatmapUnit[]): RoomRect[] {
  const rects: RoomRect[] = []
  if (!units.length) return rects
  const START_X = 73
  const AVAIL_W = VW - START_X - 1
  const northCount = Math.ceil(units.length / 2)
  const southCount = units.length - northCount
  const NORTH_H = APT_CORRIDOR_Y - 1
  const SOUTH_Y = APT_CORRIDOR_Y + CORRIDOR_H
  const SOUTH_H = VH - SOUTH_Y - 1

  for (let i = 0; i < northCount; i++) {
    const u = units[i]
    if (!u) continue
    const w = Math.floor(AVAIL_W / northCount)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: START_X + i * w, y: 1, w: w - 1, h: NORTH_H })
  }
  for (let i = 0; i < southCount; i++) {
    const u = units[northCount + i]
    if (!u) continue
    const w = Math.floor(AVAIL_W / southCount)
    const color = getRoomColor(u, props.layer)
    rects.push({ unitId: u.unit_id, label: u.unit_number,
      statusLabel: STATUS_LABELS[u.current_status], tenantName: u.tenant_name,
      ...color, status: u.current_status,
      x: START_X + i * w, y: SOUTH_Y, w: w - 1, h: SOUTH_H })
  }
  return rects
}

/** 按业态计算所有房间矩形位置 */
const roomRects = computed<RoomRect[]>(() => {
  const units = Array.isArray(props.units) ? props.units : []
  if (units.length === 0) return []
  const sorted = [...units].sort((a, b) =>
    a.unit_number.localeCompare(b.unit_number, 'zh-CN', { numeric: true }),
  )
  if (props.propertyType === 'retail') return calcRetailLayout(sorted)
  if (props.propertyType === 'apartment') return calcApartmentLayout(sorted)
  return calcOfficeLayout(sorted)
})

// ── 工具函数 ──────────────────────────────────────────────────────────────────

function shortName(name: string | null | undefined): string {
  if (typeof name !== 'string' || name.length === 0) return ''
  return name.length > 6 ? `${name.slice(0, 5)}\u2026` : name
}

function onRoomTap(unitId: string) {
  emit('unit-tap', unitId)
}

// ── 点击覆盖层样式（百分比坐标精确对齐 SVG 房间矩形） ──────────────────────────

function tapZoneStyle(room: RoomRect) {
  const w = vbW.value
  const h = vbH.value
  return {
    position: 'absolute' as const,
    left: `${((room.x / w) * 100).toFixed(3)}%`,
    top: `${((room.y / h) * 100).toFixed(3)}%`,
    width: `${((room.w / w) * 100).toFixed(3)}%`,
    height: `${((room.h / h) * 100).toFixed(3)}%`,
  }
}

// ── SVG 字符串生成器（innerHTML 注入，绕过 Vue 编译器的 SVG namespace 问题） ──

/** 写字楼建筑结构骨架 SVG（不含房间热区） */
function genOfficeSvgBody(): string {
  const elevatorSvg = elevatorXs.map((ex, idx) => `
    <g>
      <rect x="${ex}" y="${coreY + 16}" width="32" height="44"
        style="fill:var(--color-border);stroke:var(--color-muted-foreground);stroke-width:0.75"/>
      <line x1="${ex}" y1="${coreY + 16}" x2="${ex + 32}" y2="${coreY + 60}"
        style="stroke:var(--color-muted-foreground);stroke-width:0.75"/>
      <line x1="${ex + 32}" y1="${coreY + 16}" x2="${ex}" y2="${coreY + 60}"
        style="stroke:var(--color-muted-foreground);stroke-width:0.75"/>
      <text x="${ex + 16}" y="${coreY + 42}" text-anchor="middle"
        style="fill:var(--color-muted-foreground);font-size:7px;font-weight:600">E${idx + 1}</text>
    </g>`).join('')
  const stairSvg = stairXs.map(sx => `
    <g>
      <rect x="${sx}" y="${coreY + 64}" width="58" height="56"
        style="fill:var(--color-border);fill-opacity:0.5;stroke:var(--color-muted-foreground);stroke-width:0.75"/>
      <text x="${sx + 29}" y="${coreY + 95}" text-anchor="middle"
        style="fill:var(--color-muted-foreground);font-size:7px">\u6d88\u9632\u68af</text>
    </g>`).join('')
  const SOUTH_Y = NORTH_ZONE_H + CORRIDOR_H
  return `
  <rect width="${VW}" height="${VH}" style="fill:var(--color-muted);fill-opacity:0.5"/>
  <rect x="${coreX}" y="${coreY}" width="${coreW}" height="${coreH}"
    style="fill:var(--color-muted);stroke:var(--color-border);stroke-width:1.5"/>
  <text x="${coreX + coreW / 2}" y="${coreY + 14}" text-anchor="middle"
    style="fill:var(--color-muted-foreground);font-size:9px;font-weight:600">\u6838\u5fc3\u7b52</text>
  ${elevatorSvg}
  ${stairSvg}
  <line x1="0" y1="${NORTH_ZONE_H}" x2="${VW}" y2="${NORTH_ZONE_H}"
    style="stroke:var(--color-border);stroke-width:1"/>
  <line x1="0" y1="${SOUTH_Y}" x2="${VW}" y2="${SOUTH_Y}"
    style="stroke:var(--color-border);stroke-width:1"/>
  <rect x="0" y="0" width="${VW}" height="${VH}"
    style="fill:none;stroke:var(--color-foreground);stroke-width:2.5"/>
  <g transform="translate(${VW - 26},30)">
    <circle cx="0" cy="0" r="14"
      style="fill:var(--color-background);fill-opacity:0.8;stroke:var(--color-border);stroke-width:1"/>
    <polygon points="0,-9 3,3 0,0 -3,3" style="fill:var(--color-foreground)"/>
    <polygon points="0,9 3,-3 0,0 -3,-3" style="fill:var(--color-muted-foreground)"/>
    <text x="0" y="-14" text-anchor="middle"
      style="fill:var(--color-foreground);font-size:8px;font-weight:800">N</text>
  </g>`
}

/** 商铺建筑结构骨架 SVG */
function genRetailSvgBody(): string {
  return `
  <rect width="${RETAIL_VW}" height="${RETAIL_VH}" style="fill:var(--color-muted);fill-opacity:0.5"/>
  <rect x="0" y="0" width="${RETAIL_VW}" height="32"
    style="fill:var(--color-muted);stroke:var(--color-muted-foreground);stroke-width:0.8"/>
  <text x="${RETAIL_VW / 2}" y="20" text-anchor="middle"
    style="fill:var(--color-muted-foreground);font-size:9px;font-weight:600">\u540e\u52e4\u670d\u52a1\u901a\u9053</text>
  <line x1="0" y1="${RETAIL_VH - 14}" x2="${RETAIL_VW}" y2="${RETAIL_VH - 14}"
    style="stroke:var(--color-muted-foreground);stroke-width:1;stroke-dasharray:5 3"/>
  <text x="${RETAIL_VW / 2}" y="${RETAIL_VH - 3}" text-anchor="middle"
    style="fill:var(--color-muted-foreground);font-size:7px">\u6cbf\u8857\u6b65\u884c\u9053</text>
  <rect x="0" y="0" width="${RETAIL_VW}" height="${RETAIL_VH}"
    style="fill:none;stroke:var(--color-foreground);stroke-width:2.5"/>`
}

/** 公寓建筑结构骨架 SVG */
function genApartmentSvgBody(): string {
  const SOUTH_Y = APT_CORRIDOR_Y + CORRIDOR_H
  return `
  <rect width="${VW}" height="${VH}" style="fill:var(--color-muted);fill-opacity:0.5"/>
  <rect x="0" y="0" width="72" height="${VH}"
    style="fill:var(--color-muted);stroke:var(--color-muted-foreground);stroke-width:1.5"/>
  <text x="36" y="14" text-anchor="middle"
    style="fill:var(--color-muted-foreground);font-size:8px;font-weight:600">\u4ea4\u901a\u6838</text>
  <rect x="72" y="${APT_CORRIDOR_Y}" width="${VW - 72}" height="${CORRIDOR_H}"
    style="fill:var(--color-muted)"/>
  <text x="${72 + (VW - 72) / 2}" y="${APT_CORRIDOR_Y + CORRIDOR_H / 2 + 4}" text-anchor="middle"
    style="fill:var(--color-muted-foreground);font-size:8px">\u516c\u5171\u8d70\u5eca</text>
  <rect x="0" y="0" width="${VW}" height="${VH}"
    style="fill:none;stroke:var(--color-foreground);stroke-width:2.5"/>`
}

/** 所有房间热区矩形 SVG（含文字标注和选中态） */
function genRoomRects(rects: RoomRect[], selectedId: string | null): string {
  return rects.map((room) => {
    const isSelected = selectedId === room.unitId
    const fillOpacity = isSelected ? Math.min(room.opacity + 0.18, 0.82) : room.opacity
    const strokeColor = isSelected ? 'var(--color-primary)' : room.stroke
    const strokeWidth = isSelected ? 2.5 : 1.5
    const midX = room.x + room.w / 2
    const midY = room.y + room.h / 2
    const hatchRect = room.status === 'renovating'
      ? `<rect x="${room.x}" y="${room.y}" width="${room.w}" height="${room.h}"
          style="fill:url(#hatch);fill-opacity:0.4"/>`
      : ''
    const textContent = (room.w >= 68 && room.h >= 50) ? `
      <text x="${midX}" y="${midY - 10}" text-anchor="middle"
        style="fill:var(--color-foreground);font-size:9px;font-weight:700;font-family:ui-monospace,monospace">${room.label}</text>
      <text x="${midX}" y="${midY + 3}" text-anchor="middle"
        style="fill:var(--color-muted-foreground);font-size:8px">${room.statusLabel}</text>
      ${room.tenantName ? `<text x="${midX}" y="${midY + 15}" text-anchor="middle"
        style="fill:var(--color-foreground);font-size:7px">${shortName(room.tenantName)}</text>` : ''}` : ''
    const selectRect = isSelected
      ? `<rect x="${room.x + 2}" y="${room.y + 2}" width="${room.w - 4}" height="${room.h - 4}"
          style="fill:none;stroke:var(--color-primary);stroke-width:1;stroke-dasharray:4 3;opacity:0.8"/>`
      : ''
    return `<g data-unit-id="${room.unitId}">
      <rect x="${room.x}" y="${room.y}" width="${room.w}" height="${room.h}"
        style="fill:${room.fill};fill-opacity:${fillOpacity};stroke:${strokeColor};stroke-width:${strokeWidth}"/>
      ${hatchRect}${textContent}${selectRect}
    </g>`
  }).join('\n')
}

// ── SVG 字符串（全量，供 innerHTML 注入） ─────────────────────────────────────

/**
 * 是否启用真实 CAD-SVG 模式：
 *   • props.svgPath 非空
 *   • 且尚未发生加载错误（失败时自动回退手绘）
 */
const useRealSvg = computed(() => !!props.svgPath && !realSvgError.value)

const svgHtml = computed(() => {
  // 真实 SVG 模式：注入 preserveAspectRatio="xMinYMin meet" 防止默认 xMidYMid 居中
  if (useRealSvg.value) {
    let svg = realSvgText.value ?? ''
    if (!svg) return svg
    svg = svg.includes('preserveAspectRatio=')
      ? svg.replace(/preserveAspectRatio="[^"]*"/, 'preserveAspectRatio="xMinYMin meet"')
      : svg.replace(/<svg\b/, '<svg preserveAspectRatio="xMinYMin meet"')
    return svg
  }
  // 手绘示意模式：按业态规则机械生成 SVG 字符串
  const w = vbW.value
  const h = vbH.value
  const svgW = renderWidth.value
  const svgH = Math.round((svgW * h) / w)
  const body = props.propertyType === 'retail'
    ? genRetailSvgBody()
    : props.propertyType === 'apartment'
      ? genApartmentSvgBody()
      : genOfficeSvgBody()
  const rooms = genRoomRects(roomRects.value, props.selectedId)
  return `<svg viewBox="0 0 ${w} ${h}" width="${svgW}" height="${svgH}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <pattern id="hatch" patternUnits="userSpaceOnUse" width="8" height="8" patternTransform="rotate(45)">
      <line x1="0" y1="0" x2="0" y2="8"
        style="stroke:currentColor;stroke-width:0.9;stroke-opacity:0.35"/>
    </pattern>
  </defs>
  ${body}
  ${rooms}
</svg>`
})

// ── 真实 CAD-SVG 加载与 DOM 注入（对齐 flutter_app/_FloorImageViewer） ────────

/** fetch 拿到的真实 SVG 字符串（含 <svg> 根标签，可直接 v-html 注入） */
const realSvgText = ref<string | null>(null)
/** 真实 SVG 加载失败标记，置位后自动回退手绘 */
const realSvgError = ref(false)
/**
 * 真实 CAD-SVG 的 viewBox 宽高（从 SVG 文件解析）。
 * 用于按真实图纸比例计算画布高度，防止 xMidYMid meet 居中裁剪。
 */
const realSvgVbW = ref<number | null>(null)
const realSvgVbH = ref<number | null>(null)

/** UnitStatus → CSS class（与 scripts/postprocess_svg.py 注入的样式对齐） */
const STATUS_CSS_CLASS: Record<UnitStatus, string> = {
  leased: 'unit-leased',
  expiring_soon: 'unit-expiring-soon',
  vacant: 'unit-vacant',
  renovating: 'unit-renovating',
  non_leasable: 'unit-non-leasable',
  pre_lease: 'unit-vacant', // 预租近似空置（postprocess_svg.py 未定义独立 class）
}

const ALL_UNIT_CLASSES = [
  'unit-leased',
  'unit-vacant',
  'unit-expiring-soon',
  'unit-renovating',
  'unit-non-leasable',
]

/** 当前已绑定的事件解绑函数集合（切换 SVG 时清理，防止内存泄漏） */
let unbindHandlers: Array<() => void> = []

/**
 * 拉取真实 SVG 文本（携带 Bearer token 走 /api/files 代理）。
 *
 * 使用 `uni.request` 而非 `fetch`：
 *   • H5 端 uni.request 底层走 XHR/fetch，与业务 API 同通道（CORS 已通）
 *   • App-plus 端走原生网络栈，无 CORS 限制
 *   • 小程序通过 dataType:'其他值' 拿到字符串响应
 */
async function loadRealSvg(svgPath: string): Promise<void> {
  // #ifdef H5 || APP-PLUS
  realSvgText.value = null
  realSvgVbW.value = null
  realSvgVbH.value = null
  realSvgError.value = false
  const url = buildFileProxyUrl(svgPath)
  const token = uni.getStorageSync('access_token') || ''
  console.info('[FloorSvgHeatmap] 开始加载真实 SVG:', url)
  try {
    const result = await new Promise<string>((resolve, reject) => {
      uni.request({
        url,
        method: 'GET',
        header: {
          Accept: 'image/svg+xml,*/*',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        // 让响应保持为字符串而非 JSON 解析
        dataType: '其他' as unknown as 'json',
        responseType: 'text',
        success: (res) => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(typeof res.data === 'string' ? res.data : String(res.data))
          } else {
            reject(new Error(`HTTP ${res.statusCode}`))
          }
        },
        fail: (err) => reject(new Error(err.errMsg || 'request failed')),
      })
    })
    if (!result || result.length === 0) throw new Error('empty svg')
    // 解析 viewBox 宽高，用于画布按真实图纸比例渲染，修复 xMidYMid 居中问题
    const vbMatch = result.match(/viewBox="([^"]*)"/)
    if (vbMatch) {
      const parts = vbMatch[1].trim().split(/[\s,]+/)
      if (parts.length >= 4) {
        realSvgVbW.value = parseFloat(parts[2])
        realSvgVbH.value = parseFloat(parts[3])
      }
    }
    realSvgText.value = result
    console.info('[FloorSvgHeatmap] 真实 SVG 加载成功，长度:', result.length, '| viewBox:', realSvgVbW.value, 'x', realSvgVbH.value)
    await nextTick()
    applyUnitStatesAndClicks()
  } catch (e) {
    console.warn('[FloorSvgHeatmap] 真实 SVG 加载失败，回退手绘示意:', e)
    realSvgText.value = null
    realSvgVbW.value = null
    realSvgVbH.value = null
    realSvgError.value = true
  }
  // #endif
}

/**
 * 给真实 SVG 内 `[data-unit-id]` 元素追加状态 class + 绑定点击事件。
 *
 * 三级匹配策略（与 flutter_app/_buildInjectJs 对齐）：
 *   1. 精确匹配 `data-unit-id` 与 unit_number；
 *   2. 规范化匹配（去掉连字符/空格后比较）；
 *   3. `data-unit-number` 后缀匹配。
 *
 * 同时把已知 unit 的 `data-unit-id` 直接覆盖为 DB 的 unit_id（UUID），
 * 后续点击 handler 直接读 attribute 即可拿到 UUID 回传给父组件。
 */
function applyUnitStatesAndClicks(): void {
  // #ifdef H5 || APP-PLUS
  // 先清理旧 handler
  unbindHandlers.forEach((fn) => fn())
  unbindHandlers = []

  // 容器层只在真实模式时存在 .svg-heatmap__canvas--real
  const root = typeof document !== 'undefined'
    ? document.querySelector('.svg-heatmap__canvas--real')
    : null
  if (!root) return

  const units = Array.isArray(props.units) ? props.units : []
  const byNum: Record<string, FloorHeatmapUnit> = {}
  const byNorm: Record<string, FloorHeatmapUnit> = {}
  for (const u of units) {
    if (!u.unit_number) continue
    byNum[u.unit_number] = u
    byNorm[u.unit_number.replace(/[-\s]/g, '')] = u
  }

  const elements = root.querySelectorAll<Element>('[data-unit-id]')
  elements.forEach((el) => {
    const svgId = el.getAttribute('data-unit-id') ?? ''
    const svgNum = el.getAttribute('data-unit-number') ?? ''
    const normId = svgId.replace(/[-\s]/g, '')

    const matched: FloorHeatmapUnit | undefined =
      byNum[svgId]
        ?? byNorm[normId]
        ?? (svgNum ? units.find((u) => u.unit_number.endsWith(svgNum) || u.unit_number === svgNum) : undefined)
    if (!matched) return

    // 重置已知状态 class
    ALL_UNIT_CLASSES.forEach((cls) => el.classList.remove(cls))
    el.classList.add(STATUS_CSS_CLASS[matched.current_status])
    if (props.selectedId === matched.unit_id) {
      el.classList.add('unit-selected')
    }

    // 绑定点击：通过 click 事件直接 emit DB UUID
    const handler = (ev: Event) => {
      ev.stopPropagation()
      emit('unit-tap', matched.unit_id)
    }
    el.addEventListener('click', handler)
    unbindHandlers.push(() => el.removeEventListener('click', handler))
    // 鼠标手势提示
    if (el instanceof HTMLElement || (el as SVGElement).style) {
      ;(el as SVGElement & { style: CSSStyleDeclaration }).style.cursor = 'pointer'
    }
  })
  // #endif
}

/** 仅刷新选中态 class（不重绑事件，性能更好） */
function refreshSelectedHighlight(): void {
  // #ifdef H5 || APP-PLUS
  if (typeof document === 'undefined') return
  const root = document.querySelector('.svg-heatmap__canvas--real')
  if (!root) return
  root.querySelectorAll<Element>('[data-unit-id].unit-selected').forEach((el) => {
    el.classList.remove('unit-selected')
  })
  if (!props.selectedId) return
  const units = Array.isArray(props.units) ? props.units : []
  const target = units.find((u) => u.unit_id === props.selectedId)
  if (!target) return
  // 反查 SVG 元素：精确 / 规范化 / 后缀 三级
  const num = target.unit_number
  const norm = num.replace(/[-\s]/g, '')
  const candidates = root.querySelectorAll<Element>('[data-unit-id]')
  for (const el of Array.from(candidates)) {
    const svgId = el.getAttribute('data-unit-id') ?? ''
    const svgNum = el.getAttribute('data-unit-number') ?? ''
    const normId = svgId.replace(/[-\s]/g, '')
    if (svgId === num || normId === norm || svgNum === num || (svgNum && num.endsWith(svgNum))) {
      el.classList.add('unit-selected')
      break
    }
  }
  // #endif
}

// 监听 svgPath 变化：切换楼层时重新加载真实 SVG
watch(
  () => props.svgPath,
  (path) => {
    console.info('[FloorSvgHeatmap] svgPath 变化:', path)
    if (path) {
      loadRealSvg(path)
    } else {
      realSvgText.value = null
      realSvgVbW.value = null
      realSvgVbH.value = null
      realSvgError.value = false
      unbindHandlers.forEach((fn) => fn())
      unbindHandlers = []
    }
  },
  { immediate: true },
)

// 监听 units 变化：状态色块需要重绑（仅真实 SVG 模式）
watch(
  () => props.units,
  () => {
    if (useRealSvg.value && realSvgText.value) {
      nextTick(() => applyUnitStatesAndClicks())
    }
  },
)

// 监听 selectedId 变化：仅刷新选中态高亮
watch(
  () => props.selectedId,
  () => {
    if (useRealSvg.value && realSvgText.value) {
      nextTick(() => refreshSelectedHighlight())
    }
  },
)

onBeforeUnmount(() => {
  unbindHandlers.forEach((fn) => fn())
  unbindHandlers = []
})
</script>

<style lang="scss" scoped>
.svg-heatmap {
  // 宽度与高度均通过 :style 动态绑定
  display: block;
  position: relative;
  align-self: flex-start; // 防止在 flex 父容器（scroll-view wrapper / heatmap-area）中被居中
}

.svg-heatmap__canvas {
  display: block;
  // 真实 SVG 模式下让内部 <svg> 自适应容器
  &--real :deep(svg) {
    width: 100%;
    height: 100%;
    display: block;
  }
}

.svg-heatmap__overlay {
  position: absolute;
  inset: 0;
  // 容器本身不拦截点击，子 view 通过 @tap 处理
  pointer-events: none;
}

// 单个房间点击区域
.svg-heatmap__overlay > view {
  position: absolute;
  pointer-events: auto;
}

// ── 真实 CAD-SVG 状态色（与 scripts/postprocess_svg.py STANDARD_STYLES 对齐） ──
// 用 :deep() 穿透 scoped 限制作用到 v-html 注入的 SVG 子节点
.svg-heatmap__canvas--real {
  :deep([data-unit-id]) {
    transition: fill-opacity 0.15s ease;
    cursor: pointer;
  }
  :deep([data-unit-id]:hover) {
    fill-opacity: 0.55;
  }
  :deep(.unit-leased) {
    fill: #52c41a;
    fill-opacity: 0.35;
    stroke: #389e0d;
    stroke-width: 1;
  }
  :deep(.unit-vacant) {
    fill: #ff4d4f;
    fill-opacity: 0.35;
    stroke: #cf1322;
    stroke-width: 1;
  }
  :deep(.unit-expiring-soon) {
    fill: #faad14;
    fill-opacity: 0.35;
    stroke: #d48806;
    stroke-width: 1;
  }
  :deep(.unit-renovating) {
    fill: #4096ff;
    fill-opacity: 0.35;
    stroke: #1677ff;
    stroke-width: 1;
  }
  :deep(.unit-non-leasable) {
    fill: #8c8c8c;
    fill-opacity: 0.20;
    stroke: #595959;
    stroke-width: 1;
  }
  // 选中态：加粗描边 + 提高不透明度
  :deep(.unit-selected) {
    fill-opacity: 0.65;
    stroke-width: 2.5;
  }
}
</style>
