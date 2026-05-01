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
      <!-- Layer 0: 背景网格 -->
      <defs>
        <pattern id="floor-grid" :width="100" :height="100" patternUnits="userSpaceOnUse">
          <path :d="`M 100 0 L 0 0 0 100`" fill="none" stroke="var(--floor-grid)" stroke-width="1" />
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
          <text
            v-if="s.label"
            :x="s.rect.x + s.rect.w / 2"
            :y="s.rect.y + s.rect.h / 2"
            text-anchor="middle"
            dominant-baseline="middle"
            font-size="12"
            fill="var(--el-text-color-primary)"
            pointer-events="none"
          >{{ s.label }}</text>
        </template>
        <template v-else>
          <circle
            :data-structure-index="i"
            :cx="s.point[0]"
            :cy="s.point[1]"
            r="5"
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

// ── 窗洞坐标推导（与 detector 输出语义保持一致：offset 沿所属边） ──
function windowX1(w: WindowSegment): number {
  if (w.side === 'N' || w.side === 'S') return w.offset
  if (w.side === 'W') return 0
  return vp.value.width
}
function windowX2(w: WindowSegment): number {
  if (w.side === 'N' || w.side === 'S') return w.offset + w.width
  if (w.side === 'W') return 0
  return vp.value.width
}
function windowY1(w: WindowSegment): number {
  if (w.side === 'N') return 0
  if (w.side === 'S') return vp.value.height
  return w.offset
}
function windowY2(w: WindowSegment): number {
  if (w.side === 'N') return 0
  if (w.side === 'S') return vp.value.height
  return w.offset + w.width
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
