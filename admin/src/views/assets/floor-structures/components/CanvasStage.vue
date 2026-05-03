<template>
  <div
    class="canvas-container"
    tabindex="0"
    @wheel="canvas.onWheel"
    @pointerdown="canvas.onPointerDown"
    @pointermove="canvas.onPointerMove"
    @pointerup="canvas.onPointerUp"
    @pointerleave="canvas.onPointerUp"
    @keydown="canvas.onKeydown"
  >
    <svg
      v-if="store.draft"
      ref="svgRef"
      class="stage"
      :viewBox="`0 0 ${vp.width} ${vp.height}`"
      :style="{ transform: cssTransform }"
      preserveAspectRatio="xMidYMid meet"
    >
      <!-- 公共 defs -->
      <defs>
        <pattern id="floor-grid" :width="100" :height="100" patternUnits="userSpaceOnUse">
          <path :d="`M 100 0 L 0 0 0 100`" fill="none" stroke="var(--floor-grid)" stroke-width="1" />
        </pattern>
        <!-- 楼梯斜线填充 -->
        <pattern id="floor-hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
          <line x1="0" y1="0" x2="0" y2="8" stroke="var(--floor-outline-stroke)" stroke-width="1" stroke-opacity="0.4" />
        </pattern>
      </defs>
      <rect :width="vp.width" :height="vp.height" fill="url(#floor-grid)" />

      <!-- Layer 1: outline 外轮廓 -->
      <rect
        v-if="outline.type === 'rect' && outline.rect"
        :x="outline.rect.x"
        :y="outline.rect.y"
        :width="outline.rect.w"
        :height="outline.rect.h"
        fill="var(--floor-outline-bg)"
        stroke="var(--floor-outline-stroke)"
        stroke-width="2"
      />
      <polygon
        v-else-if="outline.type === 'polygon' && outline.points"
        :points="(outline.points as [number, number][]).map((p) => p.join(',')).join(' ')"
        fill="var(--floor-outline-bg)"
        stroke="var(--floor-outline-stroke)"
        stroke-width="2"
      />

      <!-- Layer 2: structures -->
      <g v-for="(s, i) in store.draft.structures" :key="i">
        <template v-if="!isColumn(s)">
          <!-- 结构底色矩形 -->
          <rect
            :data-structure-index="i"
            :x="s.rect.x"
            :y="s.rect.y"
            :width="s.rect.w"
            :height="s.rect.h"
            :fill="STRUCTURE_TYPE_COLORS[s.type]"
            :stroke="i === store.selectedIndex ? 'var(--floor-selected-stroke)' : 'var(--floor-outline-stroke)'"
            :stroke-width="i === store.selectedIndex ? 2 : 1"
          />
          <!-- 楼梯：斜线填充纹理 -->
          <rect
            v-if="s.type === 'stair'"
            :x="s.rect.x" :y="s.rect.y" :width="s.rect.w" :height="s.rect.h"
            fill="url(#floor-hatch)" pointer-events="none"
          />
          <!-- 电梯：对角叉线 + 编号 -->
          <template v-if="s.type === 'elevator'">
            <line :x1="s.rect.x" :y1="s.rect.y" :x2="s.rect.x+s.rect.w" :y2="s.rect.y+s.rect.h"
              stroke="var(--floor-outline-stroke)" stroke-width="0.75" pointer-events="none"/>
            <line :x1="s.rect.x+s.rect.w" :y1="s.rect.y" :x2="s.rect.x" :y2="s.rect.y+s.rect.h"
              stroke="var(--floor-outline-stroke)" stroke-width="0.75" pointer-events="none"/>
            <text v-if="s.code"
              :x="s.rect.x + s.rect.w/2" :y="s.rect.y + s.rect.h/2"
              text-anchor="middle" dominant-baseline="middle" font-size="10" font-weight="600"
              fill="var(--el-text-color-secondary)" pointer-events="none">{{ s.code }}</text>
          </template>
          <!-- 结构类型标签（足够大时显示） -->
          <text
            v-if="s.rect.w >= 40 && s.rect.h >= 30 && s.type !== 'elevator'"
            :x="s.rect.x + s.rect.w / 2"
            :y="s.rect.y + s.rect.h / 2"
            text-anchor="middle"
            dominant-baseline="middle"
            font-size="10"
            fill="var(--el-text-color-secondary)"
            pointer-events="none"
          >{{ s.label ?? STRUCTURE_TYPE_LABELS[s.type] }}</text>
        </template>
        <!-- 柱位：10×10 方块（与 FloorPlan.tsx 一致） -->
        <template v-else>
          <rect
            :data-structure-index="i"
            :x="s.point[0] - 5"
            :y="s.point[1] - 5"
            width="10"
            height="10"
            :fill="STRUCTURE_TYPE_COLORS.column"
            :stroke="i === store.selectedIndex ? 'var(--floor-selected-stroke)' : 'none'"
            :stroke-width="i === store.selectedIndex ? 2 : 0"
          />
        </template>
      </g>

      <!-- Layer 3: windows -->
      <line
        v-for="(w, i) in store.draft.windows ?? []"
        :key="`w-${i}`"
        :x1="windowX1(w)"
        :y1="windowY1(w)"
        :x2="windowX2(w)"
        :y2="windowY2(w)"
        stroke="var(--floor-window)"
        stroke-width="4"
        stroke-linecap="round"
      />

      <!-- Layer 4: 选中高亮虚线 -->
      <rect
        v-if="selectedRect"
        :x="selectedRect.x - 2"
        :y="selectedRect.y - 2"
        :width="selectedRect.w + 4"
        :height="selectedRect.h + 4"
        fill="none"
        stroke="var(--floor-selected-stroke)"
        stroke-width="1"
        stroke-dasharray="4 4"
        pointer-events="none"
      />

      <!-- Layer 5: 框选预览 -->
      <rect
        v-if="canvas.drawPreview.value"
        :x="canvas.drawPreview.value.x"
        :y="canvas.drawPreview.value.y"
        :width="canvas.drawPreview.value.w"
        :height="canvas.drawPreview.value.h"
        fill="none"
        stroke="var(--floor-selected-stroke)"
        stroke-width="1"
        stroke-dasharray="6 3"
      />

      <!-- Layer 6: 北指针（仿 FloorPlan.tsx 罗盘样式） -->
      <g :transform="`translate(${northPos.x}, ${northPos.y})`">
        <circle cx="0" cy="0" r="16" fill="var(--el-bg-color)" stroke="var(--floor-outline-stroke)" stroke-width="1"/>
        <polygon points="0,-11 3.5,4 0,1 -3.5,4" fill="var(--el-text-color-primary)"/>
        <polygon points="0,11 3.5,-4 0,-1 -3.5,-4" fill="var(--el-text-color-secondary)"/>
        <text x="0" y="-17" text-anchor="middle" font-size="9" font-weight="800"
          fill="var(--el-text-color-primary)">N</text>
      </g>
    </svg>

    <div v-else class="placeholder">
      <el-empty description="尚未加载楼层数据" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount, ref, watchEffect } from 'vue'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import { isColumn } from '@/types/floorMap'
import type { WindowSegment, Rect } from '@/types/floorMap'
import { STRUCTURE_TYPE_COLORS } from '@/constants/ui_constants'
import { useCanvasInteraction } from '../composables/useCanvasInteraction'

/** 结构类型中文标签（无 label 时的兜底显示） */
const STRUCTURE_TYPE_LABELS: Record<string, string> = {
  core: '核心筒', elevator: '电梯', stair: '楼梯',
  restroom: '卫生间', shaft: '管井', corridor: '走廊', lobby: '大堂', equipment: '设备间',
}

const store = useFloorStructuresStore()
const svgRef = ref<SVGSVGElement | null>(null)
const canvas = useCanvasInteraction({ store, svgRef })
const cssTransform = canvas.cssTransform

defineExpose({ setMode: canvas.setMode, mode: canvas.mode })

const vp = computed(() => store.draft?.viewport ?? { width: 1200, height: 900 })
const outline = computed(() => store.draft?.outline ?? { type: 'rect' as const, rect: { x: 0, y: 0, w: 0, h: 0 } })

const selectedRect = computed<Rect | null>(() => {
  const idx = store.selectedIndex
  if (idx === null || !store.draft) return null
  const s = store.draft.structures[idx]
  if (!s) return null
  if (isColumn(s)) {
    return { x: s.point[0] - 6, y: s.point[1] - 6, w: 12, h: 12 }
  }
  return s.rect
})

// ── outline 包围盒（用于将窗段锚定到轮廓边缘）──
// window_detector.py 的 offset 是相对于 viewport padding 边（rect_left/rect_top = 20）的距离
// 渲染时需将 offset 加回 padding，并将 N/S/E/W 的垂直/水平位置对齐到 outline 实际边缘
const VP_PADDING = 20  // 与 coordinate_mapper.py Viewport.padding 保持一致
const outlineBbox = computed(() => {
  const o = store.draft?.outline
  if (o?.type === 'rect' && o.rect) {
    return { minX: o.rect.x, minY: o.rect.y, maxX: o.rect.x + o.rect.w, maxY: o.rect.y + o.rect.h }
  }
  if (o?.type === 'polygon' && o.points?.length) {
    const xs = o.points.map((p: [number, number]) => p[0])
    const ys = o.points.map((p: [number, number]) => p[1])
    return { minX: Math.min(...xs), minY: Math.min(...ys), maxX: Math.max(...xs), maxY: Math.max(...ys) }
  }
  return { minX: 0, minY: 0, maxX: vp.value.width, maxY: vp.value.height }
})

// ── 北指针位置：优先取 draft.north，否则放在 outline 右上角内侧 ──
const northPos = computed(() => {
  const n = store.draft?.north
  if (n?.x != null && n?.y != null) return { x: n.x, y: n.y }
  return { x: outlineBbox.value.maxX - 28, y: outlineBbox.value.minY + 28 }
})

// ── 窗洞坐标推导（与 detector 输出语义保持一致：offset 沿所属边） ──
function windowX1(w: WindowSegment): number {
  if (w.side === 'N' || w.side === 'S') return w.offset + VP_PADDING
  if (w.side === 'W') return outlineBbox.value.minX
  return outlineBbox.value.maxX
}
function windowX2(w: WindowSegment): number {
  if (w.side === 'N' || w.side === 'S') return w.offset + VP_PADDING + w.width
  if (w.side === 'W') return outlineBbox.value.minX
  return outlineBbox.value.maxX
}
function windowY1(w: WindowSegment): number {
  if (w.side === 'N') return outlineBbox.value.minY
  if (w.side === 'S') return outlineBbox.value.maxY
  return w.offset + VP_PADDING
}
function windowY2(w: WindowSegment): number {
  if (w.side === 'N') return outlineBbox.value.minY
  if (w.side === 'S') return outlineBbox.value.maxY
  return w.offset + VP_PADDING + w.width
}

// 自动聚焦容器以接收键盘事件
const containerRef = ref<HTMLElement | null>(null)
onMounted(() => {
  const el = svgRef.value?.parentElement
  el?.focus()
})

// 监听全局键盘（容器未聚焦时也能撤销/重做）
function onGlobalKey(e: KeyboardEvent): void {
  canvas.onKeydown(e)
}
onMounted(() => window.addEventListener('keydown', onGlobalKey))
onBeforeUnmount(() => window.removeEventListener('keydown', onGlobalKey))

// 兼容 vue-tsc：消除未使用变量
watchEffect(() => void containerRef.value)
</script>

<style scoped>
.canvas-container {
  flex: 1;
  position: relative;
  overflow: hidden;
  background: var(--el-fill-color-lighter);
  outline: none;
}
.stage {
  display: block;
  width: 100%;
  height: 100%;
  transform-origin: 0 0;
}
.placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}
</style>
