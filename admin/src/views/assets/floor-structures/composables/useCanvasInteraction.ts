/**
 * 楼层结构标注 Canvas 交互逻辑
 * 抽离 pointer/keyboard/wheel 事件，CanvasStage 只负责渲染
 */
import { computed, reactive, ref } from 'vue'
import type { Ref } from 'vue'
import type { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import type { Rect, StructureOrColumn } from '@/types/floorMap'
import { isColumn } from '@/types/floorMap'

export type CanvasMode = 'select' | 'draw' | 'pan'

interface UseCanvasInteractionOptions {
  store: ReturnType<typeof useFloorStructuresStore>
  svgRef: Ref<SVGSVGElement | null>
}

const SCALE_MIN = 0.5
const SCALE_MAX = 3
const SCALE_STEP = 0.1

export function useCanvasInteraction({ store, svgRef }: UseCanvasInteractionOptions) {
  const mode = ref<CanvasMode>('select')
  const transform = reactive({ scale: 1, translateX: 0, translateY: 0 })
  const drawPreview = ref<Rect | null>(null)

  // 拖拽状态
  const isPointerDown = ref(false)
  const dragKind = ref<'none' | 'pan' | 'move' | 'draw'>('none')
  const dragStart = reactive({ x: 0, y: 0 })
  const moveStartRect = ref<Rect | null>(null)
  const moveStartPoint = ref<[number, number] | null>(null)

  /** 屏幕坐标 → SVG viewBox 坐标 */
  function _toSvgPoint(clientX: number, clientY: number): { x: number; y: number } | null {
    const svg = svgRef.value
    if (!svg) return null
    const pt = svg.createSVGPoint()
    pt.x = clientX
    pt.y = clientY
    const ctm = svg.getScreenCTM()
    if (!ctm) return null
    const inv = ctm.inverse()
    const local = pt.matrixTransform(inv)
    return { x: local.x, y: local.y }
  }

  function setMode(m: CanvasMode): void {
    mode.value = m
    drawPreview.value = null
  }

  function zoomBy(delta: number, anchor?: { x: number; y: number }): void {
    const next = Math.min(SCALE_MAX, Math.max(SCALE_MIN, transform.scale + delta))
    if (next === transform.scale) return
    if (anchor) {
      // 以锚点为中心缩放
      const ratio = next / transform.scale
      transform.translateX = anchor.x - (anchor.x - transform.translateX) * ratio
      transform.translateY = anchor.y - (anchor.y - transform.translateY) * ratio
    }
    transform.scale = next
  }

  function resetView(): void {
    transform.scale = 1
    transform.translateX = 0
    transform.translateY = 0
  }

  function onWheel(e: WheelEvent): void {
    e.preventDefault()
    const delta = e.deltaY < 0 ? SCALE_STEP : -SCALE_STEP
    zoomBy(delta, { x: e.offsetX, y: e.offsetY })
  }

  function onPointerDown(e: PointerEvent): void {
    if (!svgRef.value) return
    const target = e.target as Element
    const idxAttr = target.getAttribute('data-structure-index')
    isPointerDown.value = true
    const local = _toSvgPoint(e.clientX, e.clientY)
    if (!local) return
    dragStart.x = local.x
    dragStart.y = local.y

    if (mode.value === 'pan' || e.shiftKey) {
      dragKind.value = 'pan'
      return
    }
    if (mode.value === 'draw') {
      dragKind.value = 'draw'
      drawPreview.value = { x: local.x, y: local.y, w: 0, h: 0 }
      return
    }
    if (idxAttr !== null) {
      const idx = Number(idxAttr)
      store.selectStructure(idx)
      const cur = store.draft?.structures[idx]
      if (cur) {
        dragKind.value = 'move'
        if (isColumn(cur)) {
          moveStartPoint.value = [...cur.point] as [number, number]
        } else {
          moveStartRect.value = { ...cur.rect }
        }
      }
      return
    }
    // 点击空白：取消选中
    store.selectStructure(null)
    dragKind.value = 'none'
  }

  function onPointerMove(e: PointerEvent): void {
    if (!isPointerDown.value || dragKind.value === 'none') return
    const local = _toSvgPoint(e.clientX, e.clientY)
    if (!local) return
    const dx = local.x - dragStart.x
    const dy = local.y - dragStart.y

    if (dragKind.value === 'pan') {
      transform.translateX += e.movementX
      transform.translateY += e.movementY
      return
    }
    if (dragKind.value === 'draw' && drawPreview.value) {
      drawPreview.value = {
        x: Math.min(dragStart.x, local.x),
        y: Math.min(dragStart.y, local.y),
        w: Math.abs(dx),
        h: Math.abs(dy),
      }
      return
    }
    if (dragKind.value === 'move' && store.selectedIndex !== null && store.draft) {
      const idx = store.selectedIndex
      const cur = store.draft.structures[idx]
      if (!cur) return
      if (isColumn(cur) && moveStartPoint.value) {
        const [sx, sy] = moveStartPoint.value
        // 直接在 draft 上挪动，不入栈
        ;(cur as { point: [number, number] }).point = [sx + dx, sy + dy]
      } else if (!isColumn(cur) && moveStartRect.value) {
        cur.rect = {
          x: moveStartRect.value.x + dx,
          y: moveStartRect.value.y + dy,
          w: moveStartRect.value.w,
          h: moveStartRect.value.h,
        }
      }
    }
  }

  function onPointerUp(): void {
    if (!isPointerDown.value) return
    isPointerDown.value = false

    if (dragKind.value === 'draw' && drawPreview.value) {
      if (drawPreview.value.w >= 4 && drawPreview.value.h >= 4) {
        store.addRectStructure({ ...drawPreview.value })
      }
      drawPreview.value = null
      setMode('select')
    } else if (dragKind.value === 'move' && store.selectedIndex !== null) {
      // mouseup 时一次性入栈
      const idx = store.selectedIndex
      const cur = store.draft?.structures[idx]
      if (cur) store.updateStructure(idx, cur as Partial<StructureOrColumn>)
    }

    dragKind.value = 'none'
    moveStartRect.value = null
    moveStartPoint.value = null
  }

  function onKeydown(e: KeyboardEvent): void {
    if (!store.draft) return
    const tag = (e.target as HTMLElement | null)?.tagName?.toLowerCase()
    if (tag === 'input' || tag === 'textarea' || tag === 'select') return

    const cmd = e.ctrlKey || e.metaKey

    if (cmd && e.key.toLowerCase() === 'z') {
      e.preventDefault()
      if (e.shiftKey) store.redo()
      else store.undo()
      return
    }
    if (e.key === 'Delete' || e.key === 'Backspace') {
      if (store.selectedIndex !== null) {
        e.preventDefault()
        store.removeStructure(store.selectedIndex)
      }
      return
    }
    if (e.key === 'n' || e.key === 'N') {
      setMode('draw')
      return
    }
    if (e.key === 'Escape') {
      setMode('select')
      store.selectStructure(null)
      return
    }
    // 方向键移动选中结构
    if (store.selectedIndex !== null) {
      const step = e.shiftKey ? 10 : 1
      let dx = 0
      let dy = 0
      if (e.key === 'ArrowLeft') dx = -step
      else if (e.key === 'ArrowRight') dx = step
      else if (e.key === 'ArrowUp') dy = -step
      else if (e.key === 'ArrowDown') dy = step
      else return
      e.preventDefault()
      const cur = store.draft.structures[store.selectedIndex]
      if (!cur) return
      if (isColumn(cur)) {
        const [px, py] = cur.point
        store.updateStructure(store.selectedIndex, { point: [px + dx, py + dy] } as Partial<StructureOrColumn>)
      } else {
        store.updateStructure(store.selectedIndex, {
          rect: { ...cur.rect, x: cur.rect.x + dx, y: cur.rect.y + dy },
        } as Partial<StructureOrColumn>)
      }
    }
  }

  const cssTransform = computed(
    () =>
      `translate(${transform.translateX}px, ${transform.translateY}px) scale(${transform.scale})`,
  )

  return {
    mode,
    transform,
    cssTransform,
    drawPreview,
    setMode,
    zoomBy,
    resetView,
    onWheel,
    onPointerDown,
    onPointerMove,
    onPointerUp,
    onKeydown,
  }
}
