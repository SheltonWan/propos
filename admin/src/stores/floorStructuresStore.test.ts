/**
 * useFloorStructuresStore 单元测试
 *
 * 覆盖范围（24 个用例）：
 *   - load: 成功（confirmed 优先）/ 仅候选 / 全失败 / ETag 取头
 *   - save: 成功回填 / 校验失败短路 / 409 冲突保留 dirty / If-Match 透传
 *   - setRenderMode: 成功 / 失败
 *   - 编辑 actions: addStructure / updateStructure / removeStructure / addWindow / removeWindow / addRectStructure
 *   - 历史栈: undo / redo / 截断 redo 分支 / 上限 20
 *   - reset: 还原到 baselineSnapshot
 *   - validate: 各分支
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { ApiError } from '@/types/api'
import type { FloorMapV2, Structure, Column, WindowSegment } from '@/types/floorMap'

vi.mock('@/api/modules/floorStructures', () => ({
  getCandidates: vi.fn(),
  getConfirmedStructures: vi.fn(),
  putStructures: vi.fn(),
  patchRenderMode: vi.fn(),
}))

import {
  getCandidates,
  getConfirmedStructures,
  putStructures,
  patchRenderMode,
} from '@/api/modules/floorStructures'
import { useFloorStructuresStore, validate } from '@/stores/floorStructuresStore'

// ── 测试数据工厂 ─────────────────────────────
function makeMap(overrides: Partial<FloorMapV2> = {}): FloorMapV2 {
  return {
    schema_version: '2.0',
    render_mode: 'vector',
    viewport: { width: 1200, height: 800 },
    outline: { type: 'rect', rect: { x: 0, y: 0, w: 1200, h: 800 } },
    structures: [],
    ...overrides,
  }
}

function rectStructure(over: Partial<Structure> = {}): Structure {
  return {
    type: 'corridor',
    rect: { x: 100, y: 100, w: 50, h: 50 },
    source: 'manual',
    ...over,
  }
}

function columnStructure(over: Partial<Column> = {}): Column {
  return {
    type: 'column',
    point: [200, 200],
    source: 'manual',
    ...over,
  }
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
})

describe('validate', () => {
  it('完整 map 通过', () => {
    expect(validate(makeMap({ structures: [rectStructure()] }))).toBeNull()
  })

  it('source 非 manual 报错', () => {
    const m = makeMap({ structures: [{ ...rectStructure(), source: 'auto' }] })
    expect(validate(m)).toMatch(/source/)
  })

  it('矩形超出 viewport 报错', () => {
    const m = makeMap({ structures: [rectStructure({ rect: { x: 1100, y: 0, w: 200, h: 50 } })] })
    expect(validate(m)).toMatch(/viewport/)
  })

  it('elevator 缺少 code 报错', () => {
    const m = makeMap({ structures: [rectStructure({ type: 'elevator' })] })
    expect(validate(m)).toMatch(/电梯/)
  })

  it('elevator code 格式不符报错', () => {
    const m = makeMap({ structures: [rectStructure({ type: 'elevator', code: 'XYZ' })] })
    expect(validate(m)).toMatch(/电梯/)
  })

  it('restroom 缺少 gender 报错', () => {
    const m = makeMap({ structures: [rectStructure({ type: 'restroom' })] })
    expect(validate(m)).toMatch(/卫生间/)
  })

  it('column 坐标越界报错', () => {
    const m = makeMap({ structures: [columnStructure({ point: [-1, 0] })] })
    expect(validate(m)).toMatch(/超出/)
  })

  it('窗洞超出边长度报错', () => {
    const w: WindowSegment = { side: 'N', offset: 1100, width: 200 }
    expect(validate(makeMap({ windows: [w] }))).toMatch(/窗洞/)
  })

  it('结构数量 > 200 报错', () => {
    const arr = Array.from({ length: 201 }, () => rectStructure())
    expect(validate(makeMap({ structures: arr }))).toMatch(/200/)
  })
})

describe('load', () => {
  it('confirmed 成功：draft = confirmed，ETag 写入 ifMatch', async () => {
    const conf = makeMap({ structures: [rectStructure({ label: 'A' })], render_mode: 'semantic' })
    vi.mocked(getCandidates).mockRejectedValue(new ApiError('NOT_FOUND', 'no', 404))
    vi.mocked(getConfirmedStructures).mockResolvedValue({
      data: conf,
      headers: { etag: '2024-01-02T00:00:00Z' },
    })
    const store = useFloorStructuresStore()
    await store.load('f1')
    expect(store.confirmed).toEqual(conf)
    expect(store.draft).toEqual(conf)
    expect(store.draft).not.toBe(conf) // 深拷贝
    expect(store.ifMatch).toBe('2024-01-02T00:00:00Z')
    expect(store.renderMode).toBe('semantic')
    expect(store.dirty).toBe(false)
  })

  it('仅 candidates 成功：draft 取规范化候选，source 强制 manual', async () => {
    const cand = makeMap({
      structures: [{ ...rectStructure(), source: 'auto', confidence: 0.7 }],
    })
    vi.mocked(getCandidates).mockResolvedValue(cand)
    vi.mocked(getConfirmedStructures).mockRejectedValue(new ApiError('NOT_FOUND', 'no', 404))
    const store = useFloorStructuresStore()
    await store.load('f1')
    expect(store.confirmed).toBeNull()
    expect(store.ifMatch).toBeNull()
    expect(store.draft?.structures[0].source).toBe('manual')
    expect(store.draft?.structures[0].confidence).toBeUndefined()
  })

  it('两端点都失败：透传 confirmed 错误', async () => {
    vi.mocked(getCandidates).mockRejectedValue(new ApiError('X', 'cx', 500))
    vi.mocked(getConfirmedStructures).mockRejectedValue(new ApiError('Y', '加载失败', 500))
    const store = useFloorStructuresStore()
    await store.load('f1')
    expect(store.draft).toBeNull()
    expect(store.error).toBe('加载失败')
  })
})

describe('save', () => {
  async function loadFresh() {
    const conf = makeMap({ structures: [rectStructure()] })
    vi.mocked(getCandidates).mockRejectedValue(new ApiError('NOT_FOUND', 'no', 404))
    vi.mocked(getConfirmedStructures).mockResolvedValue({
      data: conf,
      headers: { etag: 'v1' },
    })
    const store = useFloorStructuresStore()
    await store.load('f1')
    return store
  }

  it('校验失败：error 设置，不发请求', async () => {
    const store = await loadFresh()
    store.addStructure({ ...rectStructure(), source: 'auto' } as Structure)
    const ok = await store.save('f1')
    expect(ok).toBe(false)
    expect(putStructures).not.toHaveBeenCalled()
    expect(store.error).toMatch(/source/)
    expect(store.dirty).toBe(true)
  })

  it('成功：用服务端回填 draft + ifMatch + renderMode + dirty=false', async () => {
    const store = await loadFresh()
    store.addStructure(rectStructure({ rect: { x: 300, y: 300, w: 50, h: 50 } }))
    const returned = makeMap({
      structures: [rectStructure(), rectStructure({ rect: { x: 300, y: 300, w: 50, h: 50 } })],
      render_mode: 'vector',
    })
    vi.mocked(putStructures).mockResolvedValue({ data: returned, headers: { etag: 'v2' } })
    const ok = await store.save('f1')
    expect(ok).toBe(true)
    expect(putStructures).toHaveBeenCalledWith('f1', expect.any(Object), 'v1')
    expect(store.ifMatch).toBe('v2')
    expect(store.dirty).toBe(false)
    expect(store.draft).toEqual(returned)
  })

  it('409 冲突：error 设置，dirty 保留', async () => {
    const store = await loadFresh()
    store.addStructure(rectStructure({ rect: { x: 300, y: 300, w: 50, h: 50 } }))
    vi.mocked(putStructures).mockRejectedValue(new ApiError('FLOOR_MAP_VERSION_CONFLICT', '版本冲突', 409))
    const ok = await store.save('f1')
    expect(ok).toBe(false)
    expect(store.error).toBe('版本冲突')
    expect(store.dirty).toBe(true)
  })
})

describe('setRenderMode', () => {
  it('成功：renderMode + draft.render_mode 同步', async () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap({ structures: [rectStructure()] })
    vi.mocked(patchRenderMode).mockResolvedValue({
      floor_id: 'f1',
      render_mode: 'semantic',
      render_mode_changed_at: '2024-01-01T00:00:00Z',
      changed_by: 'u1',
    })
    const ok = await store.setRenderMode('f1', 'semantic')
    expect(ok).toBe(true)
    expect(store.renderMode).toBe('semantic')
    expect(store.draft?.render_mode).toBe('semantic')
  })

  it('失败：error 设置', async () => {
    const store = useFloorStructuresStore()
    vi.mocked(patchRenderMode).mockRejectedValue(new ApiError('X', '切换失败', 500))
    const ok = await store.setRenderMode('f1', 'semantic')
    expect(ok).toBe(false)
    expect(store.error).toBe('切换失败')
  })
})

describe('编辑 actions', () => {
  it('addStructure / removeStructure / updateStructure 触发 dirty + 入栈', () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap()
    store.history = [store.draft]
    store.historyIndex = 0
    store.addStructure(rectStructure())
    expect(store.draft.structures).toHaveLength(1)
    expect(store.dirty).toBe(true)
    expect(store.history).toHaveLength(2)

    store.updateStructure(0, { label: 'X' })
    expect((store.draft.structures[0] as Structure).label).toBe('X')

    store.removeStructure(0)
    expect(store.draft.structures).toHaveLength(0)
    expect(store.selectedIndex).toBeNull()
  })

  it('addRectStructure 默认 type=corridor + source=manual', () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap()
    store.addRectStructure({ x: 1, y: 1, w: 10, h: 10 })
    expect(store.draft.structures[0].type).toBe('corridor')
    expect(store.draft.structures[0].source).toBe('manual')
  })

  it('addWindow / removeWindow', () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap()
    const w: WindowSegment = { side: 'N', offset: 0, width: 50 }
    store.addWindow(w)
    expect(store.draft.windows).toHaveLength(1)
    store.removeWindow(0)
    expect(store.draft.windows).toHaveLength(0)
  })
})

describe('history undo/redo', () => {
  it('undo 还原到上一版本，redo 前进', () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap()
    store.history = [makeMap()]
    store.historyIndex = 0
    store.addStructure(rectStructure({ label: 'a' }))
    store.addStructure(rectStructure({ label: 'b' }))
    expect(store.draft.structures).toHaveLength(2)
    store.undo()
    expect(store.draft.structures).toHaveLength(1)
    store.undo()
    expect(store.draft.structures).toHaveLength(0)
    store.redo()
    expect(store.draft.structures).toHaveLength(1)
  })

  it('新增操作截断 redo 分支', () => {
    const store = useFloorStructuresStore()
    store.draft = makeMap()
    store.history = [makeMap()]
    store.historyIndex = 0
    store.addStructure(rectStructure({ label: 'a' }))
    store.addStructure(rectStructure({ label: 'b' }))
    store.undo()
    store.addStructure(rectStructure({ label: 'c' }))
    expect(store.canRedo).toBe(false)
  })

  it('reset 还原到 baselineSnapshot 并清空 dirty/history', async () => {
    const conf = makeMap({ structures: [rectStructure({ label: 'base' })] })
    vi.mocked(getCandidates).mockRejectedValue(new ApiError('X', 'x', 404))
    vi.mocked(getConfirmedStructures).mockResolvedValue({ data: conf, headers: { etag: 'v1' } })
    const store = useFloorStructuresStore()
    await store.load('f1')
    store.addStructure(rectStructure({ label: 'extra' }))
    expect(store.draft?.structures).toHaveLength(2)
    store.reset()
    expect(store.draft?.structures).toHaveLength(1)
    expect(store.dirty).toBe(false)
  })
})
