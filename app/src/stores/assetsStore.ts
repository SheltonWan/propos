import type { PaginationMeta } from '@/types/api'
import type {
  Building,
  BuildingOccupancy,
  Floor,
  FloorHeatmap,
  Unit,
  UnitListParams,
} from '@/types/assets'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import {
  fetchBuilding,
  fetchBuildings,
  fetchFloor,
  fetchFloorHeatmap,
  fetchFloors,
  fetchUnit,
  fetchUnits,
} from '@/api/modules/assets'
import { ApiError } from '@/types/api'

// ── 错误兜底文案统一管理 ────────────────────────────────────────────────────
function pickErrorMessage(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

const LARGE_PAGE_SIZE = 1000

/** 从单元集合聚合楼栋出租率（前端聚合，不依赖后端） */
function aggregateOccupancy(units: Unit[]): Record<string, BuildingOccupancy> {
  const grouped: Record<string, BuildingOccupancy> = {}
  for (const u of units) {
    if (u.current_status === 'non_leasable') continue
    const g = grouped[u.building_id] ?? { total: 0, leased: 0, vacant: 0, rate: 0 }
    g.total += 1
    if (u.current_status === 'leased' || u.current_status === 'expiring_soon' || u.current_status === 'pre_lease') {
      g.leased += 1
    } else {
      g.vacant += 1
    }
    grouped[u.building_id] = g
  }
  for (const k of Object.keys(grouped)) {
    const g = grouped[k]
    g.rate = g.total > 0 ? g.leased / g.total : 0
  }
  return grouped
}

// ─── Store 1：楼栋总览（资产首页） ─────────────────────────────────────────

export const useAssetOverviewStore = defineStore('assetOverview', () => {
  // State（固定字段：list / item / loading / error / meta；
  //   item / meta 在本场景无意义，以 null 占位以满足规范第 5 条。）
  const list = ref<Building[]>([])
  const item = ref<Building | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const buildingOccupancy = ref<Record<string, BuildingOccupancy>>({})
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const totalUnits = computed(() =>
    Object.values(buildingOccupancy.value).reduce((acc, g) => acc + g.total, 0),
  )
  const totalLeased = computed(() =>
    Object.values(buildingOccupancy.value).reduce((acc, g) => acc + g.leased, 0),
  )
  const overallRate = computed(() =>
    totalUnits.value > 0 ? totalLeased.value / totalUnits.value : 0,
  )

  // Actions
  async function fetchAll(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [buildings, unitsRes] = await Promise.all([
        fetchBuildings(),
        fetchUnits({ page: 1, pageSize: LARGE_PAGE_SIZE }),
      ])
      list.value = buildings
      buildingOccupancy.value = aggregateOccupancy(unitsRes.data)
    } catch (e) {
      error.value = pickErrorMessage(e, '资产数据加载失败')
    } finally {
      loading.value = false
    }
  }

  return {
    list,
    item,
    meta,
    buildingOccupancy,
    loading,
    error,
    totalUnits,
    totalLeased,
    overallRate,
    fetchAll,
  }
})

// ─── Store 2：楼栋详情 + 楼层列表 ──────────────────────────────────────────

export const useBuildingDetailStore = defineStore('buildingDetail', () => {
  // 固定字段：list（楼层列表，作为楼栋的子资源）/ item（楼栋）/ meta（无分页占位）
  const list = ref<Floor[]>([])
  const item = ref<Building | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDetail(buildingId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [b, fls] = await Promise.all([
        fetchBuilding(buildingId),
        fetchFloors(buildingId),
      ])
      item.value = b
      list.value = fls.sort((a, c) => c.floor_number - a.floor_number)
    } catch (e) {
      error.value = pickErrorMessage(e, '楼栋数据加载失败')
    } finally {
      loading.value = false
    }
  }

  return { list, item, meta, loading, error, fetchDetail }
})

// ─── Store 3：楼层热区图（含楼层切换标签栏） ───────────────────────────────

export const useFloorMapStore = defineStore('floorMap', () => {
  // 固定字段：list（同一楼栋下的楼层标签）/ item（当前楼层）/ meta（占位）
  const list = ref<Floor[]>([])
  const item = ref<Floor | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const heatmap = ref<FloorHeatmap | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const buildingId = ref<string | null>(null)

  /** 加载楼栋下的全部楼层（用于楼层切换标签），并默认选中首个 */
  async function loadByBuilding(bid: string): Promise<void> {
    loading.value = true
    error.value = null
    buildingId.value = bid
    try {
      const fls = await fetchFloors(bid)
      list.value = [...fls].sort((a, b) => b.floor_number - a.floor_number)
      if (list.value.length > 0) {
        await selectFloor(list.value[0].id)
      }
    } catch (e) {
      error.value = pickErrorMessage(e, '楼层列表加载失败')
    } finally {
      loading.value = false
    }
  }

  /** 切换到指定楼层（拉取楼层详情 + 热区） */
  async function selectFloor(floorId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [floor, heatmapData] = await Promise.all([
        fetchFloor(floorId),
        fetchFloorHeatmap(floorId),
      ])
      item.value = floor
      heatmap.value = heatmapData
      // 若标签栏未加载（直链进入），同步拉取所属楼栋的楼层列表
      if (list.value.length === 0 && floor.building_id) {
        buildingId.value = floor.building_id
        const fls = await fetchFloors(floor.building_id)
        list.value = [...fls].sort((a, b) => b.floor_number - a.floor_number)
      }
    } catch (e) {
      error.value = pickErrorMessage(e, '楼层数据加载失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    list.value = []
    item.value = null
    heatmap.value = null
    error.value = null
    buildingId.value = null
  }

  return {
    list,
    item,
    meta,
    heatmap,
    loading,
    error,
    buildingId,
    loadByBuilding,
    selectFloor,
    reset,
  }
})

// ─── Store 4：房源列表（带分页与筛选） ────────────────────────────────────

export const useUnitListStore = defineStore('unitList', () => {
  const list = ref<Unit[]>([])
  const item = ref<Unit | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const currentParams = ref<UnitListParams>({})

  async function fetchList(params: UnitListParams = {}): Promise<void> {
    loading.value = true
    error.value = null
    currentParams.value = params
    try {
      const res = await fetchUnits({ page: 1, pageSize: 20, ...params })
      list.value = res.data
      meta.value = res.meta
    } catch (e) {
      error.value = pickErrorMessage(e, '房源列表加载失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    list.value = []
    item.value = null
    meta.value = null
    error.value = null
    currentParams.value = {}
  }

  return { list, item, meta, loading, error, currentParams, fetchList, reset }
})

// ─── Store 5：房源详情 ────────────────────────────────────────────────────

export const useUnitDetailStore = defineStore('unitDetail', () => {
  // 固定字段：list / meta 在详情场景无意义，以空数组 / null 占位
  const list = ref<Unit[]>([])
  const item = ref<Unit | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDetail(unitId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      item.value = await fetchUnit(unitId)
    } catch (e) {
      error.value = pickErrorMessage(e, '房源详情加载失败')
    } finally {
      loading.value = false
    }
  }

  return { list, item, meta, loading, error, fetchDetail }
})
