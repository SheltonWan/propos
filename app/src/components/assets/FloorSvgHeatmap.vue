<template>
  <!--
    楼层 SVG 热区图
    渲染策略（与 flutter_app/_FloorImageViewer 对齐）：
      • props.svgPath 非空（H5 / App-plus）：fetch 真实 CAD-SVG → v-html 注入 →
        BoundingClientRect 生成 @tap 覆盖层 → emit unitId
      • 否则：使用前端按业态规则生成的手绘示意 SVG，叠加透明覆盖层捕获点击
    两种模式均使用相同的 @tap.stop 覆盖层方案，规避 scroll-view 在 App-Plus 中
    拦截 addEventListener('click') 导致事件不可靠触发的问题。
    ⚠️ uni-app Vue 3 模板编译器不会给模板内 <svg> 子元素添加 SVG namespace，
       因此一律走字符串 + v-html 的方式注入。
  -->
  <view ref="heatmapRootRef" :data-heatmap-instance="instanceId" class="svg-heatmap" :style="containerStyle">
    <!-- SVG 加载旋转指示器（对齐 Flutter CupertinoActivityIndicator：居中菊花） -->
    <view v-if="useRealSvg && realSvgLoading" class="svg-heatmap__spinner" />
    <!-- SVG 渲染容器（v-html 注入；实例唯一 ID 供 applyUnitStatesAndClicks 精确查找） -->
    <view
      v-show="!realSvgLoading"
      class="svg-heatmap__canvas"
      :class="useRealSvg ? 'svg-heatmap__canvas--real' : 'svg-heatmap__canvas--fallback'"
      :style="canvasStyle"
      v-html="svgHtml"
      @click="onCanvasClick"
    />
    <!-- 真实 SVG 触摸覆盖层（applyUnitStatesAndClicks 根据 BoundingClientRect 生成） -->
    <!-- 与手绘覆盖层使用相同 @tap.stop 方案，兼容 App-Plus scroll-view 事件机制 -->
    <view v-if="useRealSvg && realSvgTapZones.length > 0" class="svg-heatmap__overlay">
      <view
        v-for="zone in realSvgTapZones"
        :key="zone.unitId"
        class="svg-heatmap__room-tap"
        :style="zone.style"
        @tap.stop="onRoomTap(zone.unitId)"
      />
    </view>
    <!-- 透明点击覆盖层：仅手绘模式启用，按百分比对齐房间矩形 -->
    <view v-if="!useRealSvg" class="svg-heatmap__overlay">
      <view
        v-for="room in roomRects"
        :key="room.unitId"
        class="svg-heatmap__room-tap"
        :style="tapZoneStyle(room)"
        @tap.stop="onRoomTap(room.unitId)"
      />
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { fetchSvgWithCache } from '@/composables/useFloorSvgCache'
import type { FloorHeatmapUnit, LayerMode, PropertyType, UnitStatus } from '@/types/assets'

// ── 实例唯一标识（仅用于调试日志） ─────────────────────────────────────────
const instanceId = Math.random().toString(36).slice(2, 8)
let hasMounted = false
const heatmapRootRef = ref<HTMLElement | { $el?: HTMLElement } | null>(null)
let syncRetryTimer: ReturnType<typeof setTimeout> | null = null
const MAX_SYNC_RETRIES = 8

// ── 真实 SVG 触摸区域（由 applyUnitStatesAndClicks 填充） ────────────────────

interface TapZone {
  unitId: string
  style: Record<string, string>
}

const realSvgTapZones = ref<TapZone[]>([])

/**
 * App-plus 下 v-html 注入的真实 SVG DOM 不可靠获取，无法走 querySelector 路径生成点击覆盖层；
 * 改为从 SVG 文本直接正则解析 hotspot 圆点生成覆盖层（见 buildRealSvgTapZonesFromText）。
 */
let supportsInteractiveRealSvg = true

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
 *   • 当前运行端支持真实 SVG 交互（H5）
 *   • props.svgPath 非空
 *   • 且尚未发生加载错误（失败时自动回退手绘）
 */
const useRealSvg = computed(() => supportsInteractiveRealSvg && !!props.svgPath && !realSvgError.value)

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
/** 真实 SVG 正在加载中（fetch 发起 → 成功/失败） */
const realSvgLoading = ref(false)
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



/**
 * 加载真实 SVG 文本（优先命中 session 内存缓存，未命中时发起网络请求）。
 *
 * 缓存层由 composables/useFloorSvgCache.ts 统一管理：
 *   • 命中缓存 — 直接同步赋值，无网络往返，切换楼层体验接近即时
 *   • 并发去重 — 同一 svgPath 同时触发多次加载只发起一次请求
 *   • 失败时自动回退手绘示意图（realSvgError = true）
 *
 * 竞态防护：捕获调用时的 svgPath，Promise 就绪后校验是否仍为当前 prop，
 * 丢弃已过期的结果，防止快速切换楼层时旧 SVG 覆盖新状态。
 */
async function loadRealSvg(svgPath: string): Promise<void> {
  // #ifdef H5 || APP-PLUS
  realSvgText.value = null
  realSvgVbW.value = null
  realSvgVbH.value = null
  realSvgError.value = false
  realSvgLoading.value = true
  realSvgTapZones.value = []
  const token = uni.getStorageSync('access_token') || ''
  console.info('[FloorSvgHeatmap] 请求 SVG（缓存优先）:', svgPath)
  try {
    const result = await fetchSvgWithCache(svgPath, token)
    // 竞态检测：若在等待期间 svgPath prop 已变更，丢弃本次结果
    if (props.svgPath !== svgPath) {
      console.info('[FloorSvgHeatmap] SVG 已过期，丢弃:', svgPath)
      return
    }
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
    realSvgLoading.value = false
    console.info('[FloorSvgHeatmap] SVG 就绪，长度:', result.length, '| viewBox:', realSvgVbW.value, 'x', realSvgVbH.value)
    scheduleRealSvgSync()
  } catch (e) {
    console.warn('[FloorSvgHeatmap] SVG 加载失败，回退手绘示意:', e)
    realSvgText.value = null
    realSvgVbW.value = null
    realSvgVbH.value = null
    realSvgLoading.value = false
    realSvgError.value = true
    realSvgTapZones.value = []
  }
  // #endif
}

/**
 * 仅在组件已挂载后同步真实 SVG 的状态色与触摸覆盖层。
 *
 * H5 走 DOM 路径：v-html 注入完成后 querySelectorAll('[data-unit-id]') + getBoundingClientRect。
 * App-plus 走文本解析路径：v-html 在 App-plus 注入后 SVG DOM 不可稳定 query，
 * 因此从 realSvgText 中正则解析 hotspot 圆点，按 viewBox 比例生成百分比覆盖层。
 *
 * 触发背景：svgPath 的 immediate watch 会在 setup 阶段先执行；若此时 SVG 命中内存缓存，
 * `fetchSvgWithCache()` 会很快 resolve，导致旧逻辑在 DOM 尚未挂载时就调用
 * `applyUnitStatesAndClicks()`，从而出现「canvas 容器未找到」。
 */
function scheduleRealSvgSync(retryCount = 0): void {
  // #ifdef APP-PLUS
  // App-plus：直接从 SVG 文本解析 hotspot，不依赖 DOM
  if (!hasMounted || !useRealSvg.value || !realSvgText.value) return
  buildRealSvgTapZonesFromText()
  return
  // #endif
  // #ifdef H5
  if (!supportsInteractiveRealSvg || !hasMounted || !useRealSvg.value || !realSvgText.value) return
  nextTick(() => {
    const root = resolveCanvasRoot()
    if (!root) {
      if (retryCount >= MAX_SYNC_RETRIES) {
        console.warn('[FloorSvgHeatmap] scheduleRealSvgSync: 超过重试上限，instanceId =', instanceId)
        return
      }
      if (syncRetryTimer) clearTimeout(syncRetryTimer)
      syncRetryTimer = setTimeout(() => {
        syncRetryTimer = null
        scheduleRealSvgSync(retryCount + 1)
      }, 16)
      return
    }
    applyUnitStatesAndClicks(root)
    refreshSelectedHighlight(root)
  })
  // #endif
}

/**
 * App-plus 专用：直接从 realSvgText 字符串解析 [data-unit-id] 的 hotspot 圆点，
 * 转成百分比覆盖层项写入 realSvgTapZones。
 *
 * 真实 SVG 中 hotspot 的结构（见 scripts/annotate_hotzone.py）：
 *   <g class="unit-hotspot ..." data-unit-id="01-A101" data-unit-number="01">
 *     <circle cx="..." cy="..." r="..." class="unit-dot"/>
 *     <title>...</title>
 *   </g>
 *
 * 半径 r 已经是房间级别的 SVG 单位（最小 2000，r * 3 倍），足以覆盖整个房间。
 */
function buildRealSvgTapZonesFromText(): void {
  const svgText = realSvgText.value
  const vbW = realSvgVbW.value
  const vbH = realSvgVbH.value
  if (!svgText || !vbW || !vbH || vbW <= 0 || vbH <= 0) {
    realSvgTapZones.value = []
    return
  }

  const units = Array.isArray(props.units) ? props.units : []
  const byNum: Record<string, FloorHeatmapUnit> = {}
  const byNorm: Record<string, FloorHeatmapUnit> = {}
  for (const u of units) {
    if (!u.unit_number) continue
    byNum[u.unit_number] = u
    byNorm[u.unit_number.replace(/[-\s]/g, '')] = u
  }

  // 匹配 hotspot 整段：<g ... data-unit-id="..." ...> ... <circle cx=".." cy=".." r=".."/> ... </g>
  const groupRe = /<g\b[^>]*?data-unit-id="([^"]+)"[^>]*?(?:data-unit-number="([^"]*)")?[^>]*>([\s\S]*?)<\/g>/g
  const circleRe = /<circle\b[^>]*?\bcx="([\d.+-]+)"[^>]*?\bcy="([\d.+-]+)"[^>]*?\br="([\d.+-]+)"/

  const newZones: TapZone[] = []
  let m: RegExpExecArray | null
  while ((m = groupRe.exec(svgText)) !== null) {
    const svgId = m[1]
    const svgNum = m[2] ?? ''
    const inner = m[3]
    const cm = circleRe.exec(inner)
    if (!cm) continue
    const cx = parseFloat(cm[1])
    const cy = parseFloat(cm[2])
    const r = parseFloat(cm[3])
    if (!Number.isFinite(cx) || !Number.isFinite(cy) || !Number.isFinite(r)) continue

    const normId = svgId.replace(/[-\s]/g, '')
    const matched: FloorHeatmapUnit | undefined =
      byNum[svgId]
        ?? byNorm[normId]
        ?? (svgNum ? units.find((u) => u.unit_number.endsWith(svgNum) || u.unit_number === svgNum) : undefined)
    if (!matched) continue

    const left = ((cx - r) / vbW) * 100
    const top = ((cy - r) / vbH) * 100
    const width = ((2 * r) / vbW) * 100
    const height = ((2 * r) / vbH) * 100
    newZones.push({
      unitId: matched.unit_id,
      style: {
        position: 'absolute',
        left: `${left.toFixed(3)}%`,
        top: `${top.toFixed(3)}%`,
        width: `${width.toFixed(3)}%`,
        height: `${height.toFixed(3)}%`,
        borderRadius: '50%',
      },
    })
  }

  console.info('[FloorSvgHeatmap] App-plus 文本解析覆盖层 =', newZones.length)
  realSvgTapZones.value = newZones
}

function isHtmlElement(value: unknown): value is HTMLElement {
  return typeof HTMLElement !== 'undefined' && value instanceof HTMLElement
}

/**
 * 解析当前组件的宿主元素。
 *
 * uni-app 在不同运行端对模板 ref 的返回值不完全一致：
 *   • H5: 通常直接返回 HTMLElement
 *   • 部分运行端: 可能返回带 `$el` 的包装对象
 */
function resolveHostElement(): HTMLElement | null {
  const raw = heatmapRootRef.value as unknown
  if (isHtmlElement(raw)) return raw
  const maybeEl = (raw as { $el?: unknown } | null)?.$el
  return isHtmlElement(maybeEl) ? maybeEl : null
}

/**
 * 在当前组件自己的 DOM 子树中解析画布容器，避免依赖全局 `document.getElementById()`。
 */
function resolveCanvasRoot(): HTMLElement | null {
  if (typeof document !== 'undefined') {
    const hostByData = document.querySelector(`[data-heatmap-instance="${instanceId}"]`)
    if (isHtmlElement(hostByData)) {
      const canvasByData = hostByData.querySelector('.svg-heatmap__canvas')
      if (isHtmlElement(canvasByData)) return canvasByData
    }
  }
  const host = resolveHostElement()
  if (!host) return null
  const canvas = host.querySelector('.svg-heatmap__canvas')
  return isHtmlElement(canvas) ? canvas : null
}

/**
 * 给真实 SVG 内 `[data-unit-id]` 元素追加状态 class + 绑定点击事件。
 *
 * 三级匹配策略（与 flutter_app/_buildInjectJs 对齐）：
 *   1. 精确匹配 `data-unit-id` 与 unit_number；
 *   2. 规范化匹配（去掉连字符/空格后比较）；
 *   3. `data-unit-number` 后缀匹配。
 *
 * 点击事件已改由覆盖层 @tap.stop 统一处理，此函数仅负责 CSS 状态同步 + 生成真实 SVG 覆盖层触摸区域。
 */
function applyUnitStatesAndClicks(rootArg?: HTMLElement): void {
  // #ifdef H5 || APP-PLUS
  const root = rootArg ?? resolveCanvasRoot()
  if (!root) {
    console.warn('[FloorSvgHeatmap] applyUnitStates: canvas 容器未找到，instanceId =', instanceId, '| host =', !!resolveHostElement())
    return
  }

  const units = Array.isArray(props.units) ? props.units : []
  const byNum: Record<string, FloorHeatmapUnit> = {}
  const byNorm: Record<string, FloorHeatmapUnit> = {}
  for (const u of units) {
    if (!u.unit_number) continue
    byNum[u.unit_number] = u
    byNorm[u.unit_number.replace(/[-\s]/g, '')] = u
  }

  const elements = root.querySelectorAll<Element>('[data-unit-id]')
  console.info('[FloorSvgHeatmap] applyUnitStates: SVG 元素数 =', elements.length, '| units =', units.length)

  // BoundingClientRect 基准（元素定位均相对于 canvas 容器）
  const containerRect = root.getBoundingClientRect()
  const newZones: TapZone[] = []

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

    // 鼠标手势提示
    if (el instanceof HTMLElement || (el as SVGElement).style) {
      ;(el as SVGElement & { style: CSSStyleDeclaration }).style.cursor = 'pointer'
    }

    // 生成覆盖层触摸区域（BoundingClientRect 相对于 canvas 容器，与手绘覆盖层对齐）
    if (containerRect.width > 0 && containerRect.height > 0) {
      const r = el.getBoundingClientRect()
      newZones.push({
        unitId: matched.unit_id,
        style: {
          position: 'absolute',
          left: `${(((r.left - containerRect.left) / containerRect.width) * 100).toFixed(3)}%`,
          top: `${(((r.top - containerRect.top) / containerRect.height) * 100).toFixed(3)}%`,
          width: `${((r.width / containerRect.width) * 100).toFixed(3)}%`,
          height: `${((r.height / containerRect.height) * 100).toFixed(3)}%`,
        },
      })
    }
  })

  realSvgTapZones.value = newZones
  console.info('[FloorSvgHeatmap] applyUnitStates: 生成覆盖层 =', newZones.length)
  // #endif
}

/**
 * 画布点击事件委托（真实 SVG 与手绘回退模式均适用）。
 *
 * 取代逐元素 addEventListener，规避以下已知问题：
 *   • scroll-view（scroll-x + scroll-y 同时开启）在 App-Plus WebView 中接管 touchstart
 *     后，子元素 addEventListener('click') 可能不可靠触发。
 *   • document.querySelector 全局选择在多实例场景下可能命中错误元素。
 *
 * 匹配策略（与 applyUnitStatesAndClicks 对齐）：
 *   1. UUID 直接匹配  — 手绘模式 genRoomRects 已写入 unit_id；
 *   2. unit_number 精确匹配 — 真实 CAD-SVG data-unit-id 为房间标注编号；
 *   3. 规范化匹配   — 去掉连字符/空格后比较。
 */
function onCanvasClick(ev: Event): void {
  // #ifdef H5 || APP-PLUS
  let target = ev.target as Element | null
  while (target) {
    // 到达画布容器自身时停止向上查找
    if (target.classList?.contains('svg-heatmap__canvas')) break
    const attrId = (target as Element).getAttribute?.('data-unit-id')
    if (attrId) {
      const units = Array.isArray(props.units) ? props.units : []
      // 方式 1：UUID 直接匹配（手绘模式 / applyUnitStatesAndClicks 已覆写的情况）
      let matched = units.find(u => u.unit_id === attrId)
      if (!matched) {
        // 方式 2/3：编号三级匹配（真实 CAD-SVG 原始标注）
        const norm = attrId.replace(/[-\s]/g, '')
        matched = units.find(u =>
          u.unit_number === attrId ||
          u.unit_number.replace(/[-\s]/g, '') === norm,
        )
      }
      if (matched) {
        ev.stopPropagation()
        emit('unit-tap', matched.unit_id)
      }
      return
    }
    target = (target as HTMLElement).parentElement ?? null
  }
  // #endif
}

/** 仅刷新选中态 class（不重绑事件，性能更好） */
function refreshSelectedHighlight(rootArg?: HTMLElement): void {
  // #ifdef H5 || APP-PLUS
  const root = rootArg ?? resolveCanvasRoot()
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
    if (path && supportsInteractiveRealSvg) {
      loadRealSvg(path)
    } else {
      if (path && !supportsInteractiveRealSvg) {
        console.info('[FloorSvgHeatmap] APP-PLUS 不支持真实 SVG 交互，回退手绘热区:', path)
      }
      realSvgText.value = null
      realSvgVbW.value = null
      realSvgVbH.value = null
      realSvgLoading.value = false
      realSvgError.value = false
      realSvgTapZones.value = []
    }
  },
  { immediate: true },
)

onMounted(() => {
  hasMounted = true
  scheduleRealSvgSync()
})

onBeforeUnmount(() => {
  if (syncRetryTimer) {
    clearTimeout(syncRetryTimer)
    syncRetryTimer = null
  }
})

// 监听 units 变化：状态色块需要重绑（仅真实 SVG 模式）
watch(
  () => props.units,
  () => {
    if (useRealSvg.value && realSvgText.value) {
      realSvgTapZones.value = [] // 先清空，等 nextTick 重新计算
      scheduleRealSvgSync()
    }
  },
)

// 监听 selectedId 变化：仅刷新选中态高亮
watch(
  () => props.selectedId,
  () => {
    if (useRealSvg.value && realSvgText.value) {
      scheduleRealSvgSync()
    }
  },
)


</script>

<style lang="scss" scoped>
.svg-heatmap {
  // 宽度与高度均通过 :style 动态绑定
  display: block;
  position: relative;
  align-self: flex-start; // 防止在 flex 父容器（scroll-view wrapper / heatmap-area）中被居中
}

// SVG 加载旋转指示器（对齐 Flutter CupertinoActivityIndicator，App-Plus WebView 安全写法）
// transform: rotate 在 App-Plus WebView 中可用；border 环形圆弧模拟 iOS 菊花
.svg-heatmap__spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 28px;
  height: 28px;
  margin-top: -14px;
  margin-left: -14px;
  border-radius: 50%;
  // iOS 灰色底环 + 深色起始段（对齐 CupertinoActivityIndicator 默认样式）
  border: 2.5px solid #c7c7cc;
  border-top-color: #636366;
  animation: svg-spin 0.75s linear infinite;
}

@keyframes svg-spin {
  to { transform: rotate(360deg); }
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
  // 容器本身不拦截点击，子节点通过 @tap 处理
  pointer-events: none;
}

// 单个房间点击区域（手绘模式 + 真实 SVG 模式共用）
.svg-heatmap__room-tap {
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
