/**
 * 楼层结构标注 Pinia Store（Setup 风格）
 *
 * 状态：
 *   - candidates: GET candidates 返回（仅 source=auto）
 *   - confirmed:  GET confirmed 返回（人工审核后的最近版本）
 *   - draft:      当前编辑草稿（深拷贝）
 *   - baselineSnapshot: 最近一次 load 完成时的 draft 快照（reset 用）
 *   - ifMatch:    乐观锁版本号（来自 ETag 响应头）
 *   - history:    撤销/重做栈，深度 ≤ 20
 *
 * 错误处理统一：catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }
 */
import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { ApiError } from '@/types/api'
import type {
  FloorMapV2,
  StructureOrColumn,
  StructureType,
  WindowSegment,
} from '@/types/floorMap'
import { isColumn } from '@/types/floorMap'
import { FLOOR_STRUCTURE_HISTORY_LIMIT } from '@/constants/ui_constants'
import {
  getCandidates,
  getConfirmedStructures,
  patchRenderMode,
  putStructures,
} from '@/api/modules/floorStructures'

const ELEVATOR_CODE_RE = /^[A-Z]\d{1,3}$/

/** 深拷贝（结构均为可序列化 JSON 数据） */
function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T
}

/**
 * 校验 FloorMapV2 完整性（与后端 floor_service.dart 保持一致）
 * 返回错误文案；通过校验返回 null
 */
export function validate(map: FloorMapV2): string | null {
  if (!map.viewport) return 'viewport 缺失'
  if (!map.outline) return 'outline 缺失'
  if (map.outline.type === 'rect' && !map.outline.rect) return 'outline.rect 缺失'
  if (map.outline.type === 'polygon') {
    const pts = map.outline.points ?? []
    if (pts.length < 3 || pts.length > 32) return 'outline.points 长度须在 3~32 之间'
  }
  if (map.structures.length > 200) return '结构数量超过 200'
  if ((map.windows?.length ?? 0) > 100) return '窗洞数量超过 100'

  const vw = map.viewport.width
  const vh = map.viewport.height

  for (const s of map.structures) {
    if (s.source !== 'manual') return '保存时所有 structure source 必须为 manual'
    if (isColumn(s)) {
      if (!Array.isArray(s.point) || s.point.length !== 2) return 'column.point 非法'
      const [px, py] = s.point
      if (px < 0 || py < 0 || px > vw || py > vh) return 'column 坐标超出 viewport'
      continue
    }
    if (s.rect.w <= 0 || s.rect.h <= 0) return '矩形尺寸非法'
    if (s.rect.x < 0 || s.rect.y < 0 || s.rect.x + s.rect.w > vw || s.rect.y + s.rect.h > vh) {
      return '矩形超出 viewport'
    }
    if (s.type === 'elevator' && (!s.code || !ELEVATOR_CODE_RE.test(s.code))) {
      return '电梯编号必须形如 E1/E12'
    }
    if (s.type === 'restroom' && !s.gender) return '卫生间必须选择性别'
    if (s.label && s.label.length > 32) return 'label 长度不得超过 32'
  }

  if (map.north) {
    const { x, y, rotation_deg } = map.north
    if (x < 0 || y < 0 || x > vw || y > vh) return '指北针坐标超出 viewport'
    if (rotation_deg !== undefined && (rotation_deg < -180 || rotation_deg > 180)) {
      return '指北针 rotation_deg 必须在 [-180, 180]'
    }
  }

  for (const w of map.windows ?? []) {
    if (w.width < 8) return '窗洞最小宽度为 8'
    if (w.offset < 0) return '窗洞 offset 不能为负'
    const sideLen = w.side === 'N' || w.side === 'S' ? vw : vh
    if (w.offset + w.width > sideLen) return '窗洞超出所属边长度'
  }
  return null
}

/** 将 candidates 中所有 structure source 强制为 manual（供首次审核使用） */
function normalizeForDraft(map: FloorMapV2): FloorMapV2 {
  const cloned = deepClone(map)
  cloned.structures = cloned.structures.map((s) => ({
    ...s,
    source: 'manual' as const,
    confidence: undefined,
  }))
  return cloned
}

export const useFloorStructuresStore = defineStore('floorStructures', () => {
  const candidates = ref<FloorMapV2 | null>(null)
  const confirmed = ref<FloorMapV2 | null>(null)
  const draft = ref<FloorMapV2 | null>(null)
  const baselineSnapshot = ref<FloorMapV2 | null>(null)
  const ifMatch = ref<string | null>(null)
  const renderMode = ref<'vector' | 'semantic'>('vector')
  const loading = ref(false)
  const saving = ref(false)
  const error = ref<string | null>(null)
  const dirty = ref(false)
  const selectedIndex = ref<number | null>(null)

  const history = ref<FloorMapV2[]>([])
  const historyIndex = ref(-1)

  // ── 派生状态 ──────────────────────────────────────
  const validationError = computed<string | null>(() =>
    draft.value ? validate(draft.value) : null,
  )
  const canSave = computed<boolean>(
    () => !validationError.value && !saving.value && dirty.value,
  )
  const canUndo = computed<boolean>(() => historyIndex.value > 0)
  const canRedo = computed<boolean>(() => historyIndex.value < history.value.length - 1)

  // ── 内部工具 ──────────────────────────────────────
  function _pushHistory(): void {
    if (!draft.value) return
    // 截断 redo 分支
    if (historyIndex.value < history.value.length - 1) {
      history.value = history.value.slice(0, historyIndex.value + 1)
    }
    history.value.push(deepClone(draft.value))
    if (history.value.length > FLOOR_STRUCTURE_HISTORY_LIMIT) {
      history.value.shift()
    }
    historyIndex.value = history.value.length - 1
  }

  function _resetHistory(): void {
    history.value = draft.value ? [deepClone(draft.value)] : []
    historyIndex.value = history.value.length - 1
  }

  function _setError(e: unknown): void {
    error.value = e instanceof ApiError ? e.message : '操作失败，请重试'
  }

  // ── Actions ───────────────────────────────────────
  /**
   * 加载候选 + 已确认结构
   * draft = confirmed（非空）?? normalizedCandidates；ifMatch 取 confirmed 响应头 ETag
   *
   * 注：后端对尚未保存过的楼层返回 200 + 空壳（viewport/outline 均为 null）。
   * 此时应回退到 candidates，否则画布会以空数据渲染导致显示空白。
   */
  async function load(floorId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [cand, conf] = await Promise.allSettled([
        getCandidates(floorId),
        getConfirmedStructures(floorId),
      ])

      candidates.value = cand.status === 'fulfilled' ? cand.value : null

      // 判断 confirmed 是否为有效数据（非空壳）
      const confData = conf.status === 'fulfilled' ? conf.value.data : null
      const hasConfirmed = confData !== null && confData.viewport !== null && confData.outline !== null

      if (hasConfirmed && confData) {
        confirmed.value = confData
        ifMatch.value = conf.status === 'fulfilled' ? (conf.value.headers['etag'] ?? null) : null
        renderMode.value = confData.render_mode ?? 'vector'
        draft.value = deepClone(confData)
      } else if (candidates.value) {
        confirmed.value = null
        ifMatch.value = null
        // 候选 source=auto，进入草稿前需归一化为 manual（保存契约要求）
        draft.value = normalizeForDraft(candidates.value)
        // candidates JSON 可能缺少 render_mode，回退默认值
        renderMode.value = draft.value.render_mode ?? 'vector'
      } else if (conf.status === 'rejected') {
        // getConfirmedStructures 失败（楼层不存在或后端错误）：报错并显示空状态
        _setError(conf.reason)
        draft.value = null
      } else {
        // candidates 尚未生成（抽取流水线未运行），且无已保存的 structures。
        // 以空白画布启动，允许用户从零开始手动标注，无需等待 Python 抽取结果。
        const DEFAULT_W = 1200
        const DEFAULT_H = 900
        draft.value = {
          schema_version: '2.0',
          render_mode: 'vector',
          viewport: { width: DEFAULT_W, height: DEFAULT_H },
          outline: { type: 'rect', rect: { x: 0, y: 0, w: DEFAULT_W, h: DEFAULT_H } },
          structures: [],
          windows: [],
        }
        renderMode.value = 'vector'
      }

      baselineSnapshot.value = draft.value ? deepClone(draft.value) : null
      _resetHistory()
      dirty.value = false
      selectedIndex.value = null
    } finally {
      loading.value = false
    }
  }

  /** 保存当前 draft；冲突时不清 dirty，由 UI 层弹窗处理 */
  async function save(floorId: string): Promise<boolean> {
    if (!draft.value) return false
    const err = validate(draft.value)
    if (err) {
      error.value = err
      return false
    }
    saving.value = true
    error.value = null
    try {
      const res = await putStructures(floorId, draft.value, ifMatch.value ?? undefined)
      confirmed.value = res.data
      ifMatch.value = res.headers['etag'] ?? ifMatch.value
      renderMode.value = res.data.render_mode
      // 用服务端回填覆盖 draft（防止 units 等 server-only 字段丢失）
      draft.value = deepClone(res.data)
      baselineSnapshot.value = deepClone(res.data)
      _resetHistory()
      dirty.value = false
      return true
    } catch (e) {
      _setError(e)
      return false
    } finally {
      saving.value = false
    }
  }

  /** 切换渲染模式（调用前 UI 层应保证 !dirty） */
  async function setRenderMode(
    floorId: string,
    mode: 'vector' | 'semantic',
  ): Promise<boolean> {
    error.value = null
    try {
      const res = await patchRenderMode(floorId, mode)
      renderMode.value = res.render_mode
      if (draft.value) draft.value.render_mode = res.render_mode
      if (confirmed.value) confirmed.value.render_mode = res.render_mode
      return true
    } catch (e) {
      _setError(e)
      return false
    }
  }

  function addStructure(s: StructureOrColumn): void {
    if (!draft.value) return
    draft.value.structures.push(deepClone(s))
    dirty.value = true
    _pushHistory()
  }

  function updateStructure(idx: number, patch: Partial<StructureOrColumn>): void {
    if (!draft.value) return
    const cur = draft.value.structures[idx]
    if (!cur) return
    // type 切换由调用方自行准备完整字段，这里用 spread 浅合并
    draft.value.structures[idx] = { ...cur, ...patch } as StructureOrColumn
    dirty.value = true
    _pushHistory()
  }

  function removeStructure(idx: number): void {
    if (!draft.value) return
    if (idx < 0 || idx >= draft.value.structures.length) return
    draft.value.structures.splice(idx, 1)
    if (selectedIndex.value === idx) selectedIndex.value = null
    dirty.value = true
    _pushHistory()
  }

  function addWindow(w: WindowSegment): void {
    if (!draft.value) return
    if (!draft.value.windows) draft.value.windows = []
    draft.value.windows.push({ ...w })
    dirty.value = true
    _pushHistory()
  }

  function removeWindow(idx: number): void {
    if (!draft.value || !draft.value.windows) return
    if (idx < 0 || idx >= draft.value.windows.length) return
    draft.value.windows.splice(idx, 1)
    dirty.value = true
    _pushHistory()
  }

  function undo(): void {
    if (!canUndo.value) return
    historyIndex.value -= 1
    draft.value = deepClone(history.value[historyIndex.value])
    dirty.value = true
  }

  function redo(): void {
    if (!canRedo.value) return
    historyIndex.value += 1
    draft.value = deepClone(history.value[historyIndex.value])
    dirty.value = true
  }

  function reset(): void {
    if (!baselineSnapshot.value) return
    draft.value = deepClone(baselineSnapshot.value)
    _resetHistory()
    dirty.value = false
    selectedIndex.value = null
    error.value = null
  }

  function selectStructure(idx: number | null): void {
    selectedIndex.value = idx
  }

  /** 新增矩形结构的便捷方法 */
  function addRectStructure(rect: { x: number; y: number; w: number; h: number }, type: StructureType = 'corridor'): void {
    addStructure({
      type,
      rect,
      source: 'manual',
    })
  }

  return {
    // state
    candidates,
    confirmed,
    draft,
    baselineSnapshot,
    ifMatch,
    renderMode,
    loading,
    saving,
    error,
    dirty,
    selectedIndex,
    history,
    historyIndex,
    // computed
    validationError,
    canSave,
    canUndo,
    canRedo,
    // actions
    load,
    save,
    setRenderMode,
    addStructure,
    updateStructure,
    removeStructure,
    addWindow,
    removeWindow,
    undo,
    redo,
    reset,
    selectStructure,
    addRectStructure,
  }
})
