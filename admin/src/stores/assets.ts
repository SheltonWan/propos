/**
 * M1 资产模块 Pinia stores（setup 风格）
 * 含：
 *   - useAssetOverviewStore   — 资产总览页（业态统计 + 楼栋列表）
 *   - useBuildingDetailStore  — 楼栋详情页
 *   - useFloorMapStore        — 楼层热区图
 *   - useUnitDetailStore      — 房源详情页
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { ApiError } from '@/types/api'
import type { PaginationMeta } from '@/types/api'
import type {
  AssetOverviewStats,
  Building,
  ContractSummary,
  Floor,
  FloorHeatmap,
  FloorPlan,
  ImportBatchDetail,
  RenovationCreateRequest,
  RenovationRecord,
  Unit,
  UnitStatus,
  UnitUpdateRequest,
} from '@/types/asset'
import {
  createRenovation as apiCreateRenovation,
  exportUnits as apiExportUnits,
  fetchAssetOverview,
  fetchBuilding,
  fetchBuildings,
  fetchContractSummary,
  fetchFloor,
  fetchFloorHeatmap,
  fetchFloorPlans,
  fetchFloors,
  fetchRenovations,
  fetchUnit,
  fetchUnits,
  importUnits as apiImportUnits,
  patchUnit,
  setCurrentFloorPlan as apiSetCurrentFloorPlan,
} from '@/api/modules/assets'

/** 楼栋粒度出租率聚合（前端在 useAssetOverviewStore 中根据 units 计算） */
export interface BuildingOccupancy {
  total: number
  leased: number
  vacant: number
  rate: number
}

/** 楼层粒度出租率聚合 */
export interface FloorOccupancy {
  total: number
  leased: number
  vacant: number
  rate: number
}

function aggregate(units: { current_status: UnitStatus }[]): { total: number; leased: number; vacant: number; rate: number } {
  let total = 0
  let leased = 0
  let vacant = 0
  for (const u of units) {
    if (u.current_status === 'non_leasable') continue
    total += 1
    if (u.current_status === 'leased' || u.current_status === 'expiring_soon' || u.current_status === 'pre_lease') {
      leased += 1
    } else {
      vacant += 1
    }
  }
  const rate = total > 0 ? leased / total : 0
  return { total, leased, vacant, rate }
}

function _msg(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

// ─── 1. 资产总览 ───────────────────────────────────────

export const useAssetOverviewStore = defineStore('assetOverview', () => {
  const list = ref<Building[]>([])
  const overview = ref<AssetOverviewStats | null>(null)
  const buildingOccupancy = ref<Record<string, BuildingOccupancy>>({})
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchAll(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [buildings, stats] = await Promise.all([fetchBuildings(), fetchAssetOverview()])
      list.value = buildings
      overview.value = stats
      // 后端 BuildingSummary 当前不含 occupancy_rate，前端拉一次单元列表（NLA 较大时上限 1000）做分组聚合
      const unitsRes = await fetchUnits({ page: 1, pageSize: 1000 })
      const grouped: Record<string, BuildingOccupancy> = {}
      for (const u of unitsRes.data) {
        if (!grouped[u.building_id]) {
          grouped[u.building_id] = { total: 0, leased: 0, vacant: 0, rate: 0 }
        }
        if (u.current_status === 'non_leasable') continue
        grouped[u.building_id].total += 1
        if (
          u.current_status === 'leased' ||
          u.current_status === 'expiring_soon' ||
          u.current_status === 'pre_lease'
        ) {
          grouped[u.building_id].leased += 1
        } else {
          grouped[u.building_id].vacant += 1
        }
      }
      for (const k of Object.keys(grouped)) {
        const g = grouped[k]
        g.rate = g.total > 0 ? g.leased / g.total : 0
      }
      buildingOccupancy.value = grouped
    } catch (e) {
      error.value = _msg(e, '资产数据加载失败')
    } finally {
      loading.value = false
    }
  }

  /** 导出房源台账（触发浏览器下载） */
  async function exportUnits(): Promise<void> {
    error.value = null
    try {
      const blob = await apiExportUnits()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `units_export_${Date.now()}.xlsx`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    } catch (e) {
      error.value = _msg(e, '导出失败')
      throw e
    }
  }

  return { list, overview, buildingOccupancy, loading, error, fetchAll, exportUnits }
})

// ─── 2. 楼栋详情 ───────────────────────────────────────

export const useBuildingDetailStore = defineStore('buildingDetail', () => {
  const item = ref<Building | null>(null)
  const floors = ref<Floor[]>([])
  const units = ref<Unit[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  /** 楼栋整体出租率聚合 */
  const overall = computed<BuildingOccupancy>(() => aggregate(units.value))

  /** 楼层 ID -> 出租率聚合 */
  const floorOccupancy = computed<Record<string, FloorOccupancy>>(() => {
    const map: Record<string, FloorOccupancy> = {}
    for (const u of units.value) {
      if (!map[u.floor_id]) {
        map[u.floor_id] = { total: 0, leased: 0, vacant: 0, rate: 0 }
      }
      if (u.current_status === 'non_leasable') continue
      map[u.floor_id].total += 1
      if (
        u.current_status === 'leased' ||
        u.current_status === 'expiring_soon' ||
        u.current_status === 'pre_lease'
      ) {
        map[u.floor_id].leased += 1
      } else {
        map[u.floor_id].vacant += 1
      }
    }
    for (const k of Object.keys(map)) {
      map[k].rate = map[k].total > 0 ? map[k].leased / map[k].total : 0
    }
    return map
  })

  async function fetchDetail(buildingId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [building, floorList, unitsRes] = await Promise.all([
        fetchBuilding(buildingId),
        fetchFloors(buildingId),
        fetchUnits({ building_id: buildingId, page: 1, pageSize: 1000 }),
      ])
      item.value = building
      floors.value = floorList
      units.value = unitsRes.data
    } catch (e) {
      error.value = _msg(e, '楼栋数据加载失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    item.value = null
    floors.value = []
    units.value = []
    error.value = null
  }

  return { item, floors, units, overall, floorOccupancy, loading, error, fetchDetail, reset }
})

// ─── 3. 楼层热区图 ─────────────────────────────────────

export const useFloorMapStore = defineStore('floorMap', () => {
  const item = ref<Floor | null>(null)
  const heatmap = ref<FloorHeatmap | null>(null)
  const plans = ref<FloorPlan[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchMap(floorId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [floor, hm, planList] = await Promise.all([
        fetchFloor(floorId),
        fetchFloorHeatmap(floorId),
        fetchFloorPlans(floorId),
      ])
      item.value = floor
      heatmap.value = hm
      plans.value = planList
    } catch (e) {
      error.value = _msg(e, '楼层数据加载失败')
    } finally {
      loading.value = false
    }
  }

  async function setCurrentPlan(planId: string): Promise<void> {
    error.value = null
    try {
      await apiSetCurrentFloorPlan(planId)
      // 切换版本后刷新热区与图纸列表
      if (item.value) {
        await fetchMap(item.value.id)
      }
    } catch (e) {
      error.value = _msg(e, '切换图纸版本失败')
      throw e
    }
  }

  function reset(): void {
    item.value = null
    heatmap.value = null
    plans.value = []
    error.value = null
  }

  return { item, heatmap, plans, loading, error, fetchMap, setCurrentPlan, reset }
})

// ─── 4. 房源详情 ───────────────────────────────────────

export const useUnitDetailStore = defineStore('unitDetail', () => {
  const item = ref<Unit | null>(null)
  const renovations = ref<RenovationRecord[]>([])
  const renovationsMeta = ref<PaginationMeta | null>(null)
  const currentContract = ref<ContractSummary | null>(null)
  const loading = ref(false)
  const saving = ref(false)
  const error = ref<string | null>(null)

  async function fetchDetail(unitId: string): Promise<void> {
    loading.value = true
    error.value = null
    currentContract.value = null
    try {
      const [unit, renovationsRes] = await Promise.all([
        fetchUnit(unitId),
        fetchRenovations({ unit_id: unitId, page: 1, pageSize: 50 }),
      ])
      item.value = unit
      renovations.value = renovationsRes.data
      renovationsMeta.value = renovationsRes.meta
      // 当前合同（若存在）
      if (unit.current_contract_id) {
        try {
          currentContract.value = await fetchContractSummary(unit.current_contract_id)
        } catch {
          // 合同读取失败时降级为只显示合同 ID 链接，不阻断主流程
          currentContract.value = null
        }
      }
    } catch (e) {
      error.value = _msg(e, '房源数据加载失败')
    } finally {
      loading.value = false
    }
  }

  /** 更新房源（编辑弹窗提交） */
  async function updateUnit(unitId: string, payload: UnitUpdateRequest): Promise<void> {
    saving.value = true
    error.value = null
    try {
      const updated = await patchUnit(unitId, payload)
      item.value = updated
    } catch (e) {
      error.value = _msg(e, '更新失败')
      throw e
    } finally {
      saving.value = false
    }
  }

  /** 新增改造记录 */
  async function addRenovation(payload: RenovationCreateRequest): Promise<void> {
    saving.value = true
    error.value = null
    try {
      const rec = await apiCreateRenovation(payload)
      renovations.value = [rec, ...renovations.value]
    } catch (e) {
      error.value = _msg(e, '新增改造记录失败')
      throw e
    } finally {
      saving.value = false
    }
  }

  function reset(): void {
    item.value = null
    renovations.value = []
    renovationsMeta.value = null
    currentContract.value = null
    error.value = null
  }

  return {
    item,
    renovations,
    renovationsMeta,
    currentContract,
    loading,
    saving,
    error,
    fetchDetail,
    updateUnit,
    addRenovation,
    reset,
  }
})

// ─── 5. 楼层热区图弹窗（点击单元加载更详细信息）────────

export const useFloorUnitDrawerStore = defineStore('floorUnitDrawer', () => {
  const unit = ref<Unit | null>(null)
  const contract = ref<ContractSummary | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function load(unitId: string): Promise<void> {
    loading.value = true
    error.value = null
    contract.value = null
    try {
      const u = await fetchUnit(unitId)
      unit.value = u
      if (u.current_contract_id) {
        try {
          contract.value = await fetchContractSummary(u.current_contract_id)
        } catch {
          contract.value = null
        }
      }
    } catch (e) {
      error.value = _msg(e, '加载单元详情失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    unit.value = null
    contract.value = null
    error.value = null
  }

  return { unit, contract, loading, error, load, reset }
})

// ─── 6. 单元批量导入 ──────────────────────────────────

export const useUnitImportStore = defineStore('unitImport', () => {
  const file = ref<File | null>(null)
  const dryRunResult = ref<ImportBatchDetail | null>(null)
  const commitResult = ref<ImportBatchDetail | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  function setFile(f: File | null): void {
    file.value = f
    dryRunResult.value = null
    commitResult.value = null
    error.value = null
  }

  async function dryRun(): Promise<void> {
    if (!file.value) {
      error.value = '请先选择文件'
      return
    }
    loading.value = true
    error.value = null
    try {
      dryRunResult.value = await apiImportUnits(file.value, true)
    } catch (e) {
      error.value = _msg(e, '预校验失败')
    } finally {
      loading.value = false
    }
  }

  async function commit(): Promise<void> {
    if (!file.value) {
      error.value = '请先选择文件'
      return
    }
    loading.value = true
    error.value = null
    try {
      commitResult.value = await apiImportUnits(file.value, false)
    } catch (e) {
      error.value = _msg(e, '导入失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    file.value = null
    dryRunResult.value = null
    commitResult.value = null
    error.value = null
  }

  return { file, dryRunResult, commitResult, loading, error, setFile, dryRun, commit, reset }
})
