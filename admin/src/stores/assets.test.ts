/**
 * useAssetOverviewStore / useBuildingDetailStore 单元测试
 *
 * 覆盖范围：
 * - useAssetOverviewStore.fetchAll()：成功/失败/出租率聚合/non_leasable 排除
 * - useAssetOverviewStore.exportUnits()：成功触发下载/失败设置 error
 * - useBuildingDetailStore.fetchDetail()：成功/失败/楼层聚合 computed
 * - aggregate 函数：leased / expiring_soon / pre_lease / vacant / non_leasable 分类
 */

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAssetOverviewStore, useBuildingDetailStore } from '@/stores/assets'
import { ApiError } from '@/types/api'
import type { Building, Floor, Unit } from '@/types/asset'

// ── Mock API modules ───────────────────────────────────

vi.mock('@/api/modules/assets', () => ({
  fetchBuildings: vi.fn(),
  fetchAssetOverview: vi.fn(),
  fetchUnits: vi.fn(),
  fetchBuilding: vi.fn(),
  fetchFloors: vi.fn(),
  apiExportUnits: vi.fn(),
  exportUnits: vi.fn(),
  patchUnit: vi.fn(),
  fetchFloorHeatmap: vi.fn(),
  fetchFloor: vi.fn(),
  fetchUnit: vi.fn(),
  uploadBuildingDxf: vi.fn(),
  uploadFloorCad: vi.fn(),
  fetchCadImportJob: vi.fn(),
  importUnits: vi.fn(),
  fetchFloorPlans: vi.fn(),
  setCurrentFloorPlan: vi.fn(),
  assignUnmatchedSvg: vi.fn(),
  fetchRenovations: vi.fn(),
  createRenovation: vi.fn(),
  uploadRenovationPhoto: vi.fn(),
  fetchContractSummary: vi.fn(),
}))

import {
  fetchBuildings,
  fetchAssetOverview,
  fetchUnits,
  fetchBuilding,
  fetchFloors,
  exportUnits as apiExportUnits,
} from '@/api/modules/assets'

// ── 测试数据工厂 ────────────────────────────────────────

function makeBuilding(id: string, name: string): Building {
  return {
    id,
    name,
    property_type: 'office',
    total_floors: 10,
    basement_floors: 1,
    gfa: 10000,
    nla: 8000,
    address: '某路1号',
    built_year: 2020,
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  }
}

function makeUnit(id: string, buildingId: string, floorId: string, status: Unit['current_status']): Unit {
  return {
    id,
    building_id: buildingId,
    floor_id: floorId,
    unit_number: id,
    current_status: status,
    property_type: "office",
    nla: 100,
    floor_number: 1,
    building_name: "楼A",
    floor_name: "1F",
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  } as unknown as Unit;
}

function makeFloor(id: string, buildingId: string): Floor {
  return {
    id,
    building_id: buildingId,
    building_name: null,
    floor_number: 1,
    floor_name: '1F',
    svg_path: null,
    png_path: null,
    nla: null,
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  }
}

// ── useAssetOverviewStore ──────────────────────────────

describe('useAssetOverviewStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('初始状态', () => {
    it('list 为空，overview 为 null，loading 为 false，error 为 null', () => {
      const store = useAssetOverviewStore()
      expect(store.list).toEqual([])
      expect(store.overview).toBeNull()
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })
  })

  describe('fetchAll()', () => {
    it('成功：填充楼栋列表和总览统计', async () => {
      const buildings = [makeBuilding('b1', '楼A'), makeBuilding('b2', '楼B')]
      const overview = { total_units: 100, leased: 80, vacant: 20 }
      vi.mocked(fetchBuildings).mockResolvedValue(buildings)
      vi.mocked(fetchAssetOverview).mockResolvedValue(overview as never)
      vi.mocked(fetchUnits).mockResolvedValue({ data: [], meta: { page: 1, pageSize: 1000, total: 0 } })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      expect(store.list).toEqual(buildings)
      expect(store.overview).toEqual(overview)
      expect(store.error).toBeNull()
    })

    it('成功：按 building_id 聚合出租率（leased + expiring_soon + pre_lease 计为已租）', async () => {
      vi.mocked(fetchBuildings).mockResolvedValue([makeBuilding('b1', '楼A')])
      vi.mocked(fetchAssetOverview).mockResolvedValue({} as never)
      vi.mocked(fetchUnits).mockResolvedValue({
        data: [
          makeUnit('u1', 'b1', 'f1', 'leased'),
          makeUnit('u2', 'b1', 'f1', 'expiring_soon'),
          makeUnit('u3', 'b1', 'f1', 'pre_lease'),
          makeUnit('u4', 'b1', 'f1', 'vacant'),
          makeUnit('u5', 'b1', 'f1', 'renovating'),
        ],
        meta: { page: 1, pageSize: 1000, total: 5 },
      })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      const occ = store.buildingOccupancy['b1']
      expect(occ.total).toBe(5)
      expect(occ.leased).toBe(3)   // leased + expiring_soon + pre_lease
      expect(occ.vacant).toBe(2)   // vacant + renovating
      expect(occ.rate).toBeCloseTo(3 / 5)
    })

    it('成功：non_leasable 状态不计入 total 和 leased', async () => {
      vi.mocked(fetchBuildings).mockResolvedValue([makeBuilding('b1', '楼A')])
      vi.mocked(fetchAssetOverview).mockResolvedValue({} as never)
      vi.mocked(fetchUnits).mockResolvedValue({
        data: [
          makeUnit('u1', 'b1', 'f1', 'leased'),
          makeUnit('u2', 'b1', 'f1', 'non_leasable'), // 应被排除
          makeUnit('u3', 'b1', 'f1', 'non_leasable'), // 应被排除
        ],
        meta: { page: 1, pageSize: 1000, total: 3 },
      })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      const occ = store.buildingOccupancy['b1']
      expect(occ.total).toBe(1)   // 只有 u1 计入
      expect(occ.leased).toBe(1)
      expect(occ.rate).toBe(1)
    })

    it('成功：多楼栋各自独立聚合', async () => {
      vi.mocked(fetchBuildings).mockResolvedValue([
        makeBuilding('b1', '楼A'),
        makeBuilding('b2', '楼B'),
      ])
      vi.mocked(fetchAssetOverview).mockResolvedValue({} as never)
      vi.mocked(fetchUnits).mockResolvedValue({
        data: [
          makeUnit('u1', 'b1', 'f1', 'leased'),
          makeUnit('u2', 'b1', 'f1', 'vacant'),
          makeUnit('u3', 'b2', 'f2', 'vacant'),
        ],
        meta: { page: 1, pageSize: 1000, total: 3 },
      })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      expect(store.buildingOccupancy['b1'].leased).toBe(1)
      expect(store.buildingOccupancy['b1'].total).toBe(2)
      expect(store.buildingOccupancy['b2'].leased).toBe(0)
      expect(store.buildingOccupancy['b2'].total).toBe(1)
    })

    it('失败（ApiError）：error.value = e.message', async () => {
      vi.mocked(fetchBuildings).mockRejectedValue(
        new ApiError('FORBIDDEN', '无权访问资产列表', 403),
      )
      vi.mocked(fetchAssetOverview).mockRejectedValue(new Error())
      vi.mocked(fetchUnits).mockResolvedValue({ data: [], meta: { page: 1, pageSize: 1000, total: 0 } })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      expect(store.error).toBe('无权访问资产列表')
    })

    it('失败（普通 Error）：error.value = 默认消息', async () => {
      vi.mocked(fetchBuildings).mockRejectedValue(new Error('Network Error'))
      vi.mocked(fetchAssetOverview).mockRejectedValue(new Error())
      vi.mocked(fetchUnits).mockResolvedValue({ data: [], meta: { page: 1, pageSize: 1000, total: 0 } })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      // 断言 error 为非空字符串（默认兜底消息）
      expect(store.error).toBeTruthy()
    })

    it('成功/失败：loading 最终恢复为 false', async () => {
      vi.mocked(fetchBuildings).mockRejectedValue(new Error())
      vi.mocked(fetchAssetOverview).mockResolvedValue({} as never)
      vi.mocked(fetchUnits).mockResolvedValue({ data: [], meta: { page: 1, pageSize: 1000, total: 0 } })

      const store = useAssetOverviewStore()
      await store.fetchAll()

      expect(store.loading).toBe(false)
    })
  })

  describe('exportUnits()', () => {
    it('成功：触发浏览器下载（createObjectURL 被调用）', async () => {
      const fakeBlob = new Blob(['data'])
      vi.mocked(apiExportUnits).mockResolvedValue(fakeBlob as never)

      // stub DOM 相关方法
      const createObjUrl = vi.fn().mockReturnValue('blob:fake-url')
      const revokeObjUrl = vi.fn()
      const appendSpy = vi.spyOn(document.body, 'appendChild').mockImplementation((() => {}) as never)
      const removeSpy = vi.spyOn(document.body, 'removeChild').mockImplementation((() => {}) as never)
      vi.stubGlobal('URL', { createObjectURL: createObjUrl, revokeObjectURL: revokeObjUrl })

      const store = useAssetOverviewStore()
      await store.exportUnits()

      expect(createObjUrl).toHaveBeenCalledWith(fakeBlob)
      expect(revokeObjUrl).toHaveBeenCalledWith('blob:fake-url')
      appendSpy.mockRestore()
      removeSpy.mockRestore()
      vi.unstubAllGlobals()
    })

    it('失败：error.value 被设置，异常重新抛出', async () => {
      vi.mocked(apiExportUnits).mockRejectedValue(new ApiError('EXPORT_FAIL', '导出失败', 500))

      const store = useAssetOverviewStore()
      await expect(store.exportUnits()).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('导出失败')
    })
  })
})

// ── useBuildingDetailStore ─────────────────────────────

describe('useBuildingDetailStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('初始状态', () => {
    it('item 为 null，floors/units 为空数组，loading 为 false', () => {
      const store = useBuildingDetailStore()
      expect(store.item).toBeNull()
      expect(store.floors).toEqual([])
      expect(store.units).toEqual([])
      expect(store.loading).toBe(false)
    })
  })

  describe('fetchDetail()', () => {
    it('成功：填充 item、floors、units', async () => {
      const building = makeBuilding('b1', '楼A')
      const floors = [makeFloor('f1', 'b1')]
      const units = [makeUnit('u1', 'b1', 'f1', 'leased')]

      vi.mocked(fetchBuilding).mockResolvedValue(building)
      vi.mocked(fetchFloors).mockResolvedValue(floors)
      vi.mocked(fetchUnits).mockResolvedValue({ data: units, meta: { page: 1, pageSize: 1000, total: 1 } })

      const store = useBuildingDetailStore()
      await store.fetchDetail('b1')

      expect(store.item).toEqual(building)
      expect(store.floors).toEqual(floors)
      expect(store.units).toEqual(units)
      expect(store.error).toBeNull()
    })

    it('失败：error.value 被设置', async () => {
      vi.mocked(fetchBuilding).mockRejectedValue(
        new ApiError('NOT_FOUND', '楼栋不存在', 404),
      )
      vi.mocked(fetchFloors).mockResolvedValue([])
      vi.mocked(fetchUnits).mockResolvedValue({ data: [], meta: { page: 1, pageSize: 1000, total: 0 } })

      const store = useBuildingDetailStore()
      await store.fetchDetail('no-such')

      expect(store.error).toBe('楼栋不存在')
      expect(store.loading).toBe(false)
    })
  })

  describe('computed — overall 出租率聚合', () => {
    it('正确计算整栋出租率', async () => {
      const building = makeBuilding('b1', '楼A')
      const floors = [makeFloor('f1', 'b1')]
      const units = [
        makeUnit('u1', 'b1', 'f1', 'leased'),
        makeUnit('u2', 'b1', 'f1', 'vacant'),
        makeUnit('u3', 'b1', 'f1', 'non_leasable'),
      ]
      vi.mocked(fetchBuilding).mockResolvedValue(building)
      vi.mocked(fetchFloors).mockResolvedValue(floors)
      vi.mocked(fetchUnits).mockResolvedValue({ data: units, meta: { page: 1, pageSize: 1000, total: 3 } })

      const store = useBuildingDetailStore()
      await store.fetchDetail('b1')

      expect(store.overall.total).toBe(2)   // non_leasable 排除
      expect(store.overall.leased).toBe(1)
      expect(store.overall.rate).toBeCloseTo(0.5)
    })
  })

  describe('computed — floorOccupancy 楼层聚合', () => {
    it('按楼层 ID 独立聚合', async () => {
      const building = makeBuilding('b1', '楼A')
      const floors = [makeFloor('f1', 'b1'), makeFloor('f2', 'b1')]
      const units = [
        makeUnit('u1', 'b1', 'f1', 'leased'),
        makeUnit('u2', 'b1', 'f1', 'vacant'),
        makeUnit('u3', 'b1', 'f2', 'leased'),
      ]
      vi.mocked(fetchBuilding).mockResolvedValue(building)
      vi.mocked(fetchFloors).mockResolvedValue(floors)
      vi.mocked(fetchUnits).mockResolvedValue({ data: units, meta: { page: 1, pageSize: 1000, total: 3 } })

      const store = useBuildingDetailStore()
      await store.fetchDetail('b1')

      expect(store.floorOccupancy['f1'].leased).toBe(1)
      expect(store.floorOccupancy['f1'].total).toBe(2)
      expect(store.floorOccupancy['f2'].leased).toBe(1)
      expect(store.floorOccupancy['f2'].total).toBe(1)
    })
  })
})
