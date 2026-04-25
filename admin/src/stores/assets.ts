/**
 * M1 资产模块 Pinia stores（setup 风格）
 * 含：
 *   - useAssetOverviewStore   — 资产总览页（业态统计 + 楼栋列表）
 *   - useBuildingDetailStore  — 楼栋详情页
 *   - useFloorMapStore        — 楼层热区图
 *   - useUnitDetailStore      — 房源详情页
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ApiError } from '@/types/api'
import type { PaginationMeta } from '@/types/api'
import type {
  AssetOverviewStats,
  Building,
  Floor,
  FloorHeatmap,
  FloorPlan,
  RenovationRecord,
  Unit,
} from '@/types/asset'
import {
  fetchAssetOverview,
  fetchBuilding,
  fetchBuildings,
  fetchFloor,
  fetchFloorHeatmap,
  fetchFloorPlans,
  fetchFloors,
  fetchRenovations,
  fetchUnit,
  setCurrentFloorPlan as apiSetCurrentFloorPlan,
} from '@/api/modules/assets'

function _msg(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

// ─── 1. 资产总览 ───────────────────────────────────────

export const useAssetOverviewStore = defineStore('assetOverview', () => {
  const list = ref<Building[]>([])
  const overview = ref<AssetOverviewStats | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchAll(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [buildings, stats] = await Promise.all([fetchBuildings(), fetchAssetOverview()])
      list.value = buildings
      overview.value = stats
    } catch (e) {
      error.value = _msg(e, '资产数据加载失败')
    } finally {
      loading.value = false
    }
  }

  return { list, overview, loading, error, fetchAll }
})

// ─── 2. 楼栋详情 ───────────────────────────────────────

export const useBuildingDetailStore = defineStore('buildingDetail', () => {
  const item = ref<Building | null>(null)
  const floors = ref<Floor[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDetail(buildingId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [building, floorList] = await Promise.all([
        fetchBuilding(buildingId),
        fetchFloors(buildingId),
      ])
      item.value = building
      floors.value = floorList
    } catch (e) {
      error.value = _msg(e, '楼栋数据加载失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    item.value = null
    floors.value = []
    error.value = null
  }

  return { item, floors, loading, error, fetchDetail, reset }
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
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchDetail(unitId: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const [unit, renovationsRes] = await Promise.all([
        fetchUnit(unitId),
        fetchRenovations({ unit_id: unitId, page: 1, page_size: 50 }),
      ])
      item.value = unit
      renovations.value = renovationsRes.data
      renovationsMeta.value = renovationsRes.meta
    } catch (e) {
      error.value = _msg(e, '房源数据加载失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    item.value = null
    renovations.value = []
    renovationsMeta.value = null
    error.value = null
  }

  return { item, renovations, renovationsMeta, loading, error, fetchDetail, reset }
})
