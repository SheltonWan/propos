import type { PaginationMeta } from '@/types/api'
import type {
  AssetOverview,
  Building,
  Floor,
  FloorHeatmap,
  PropertyType,
  Unit,
  UnitListParams,
} from '@/types/assets'

/** 前端 typeStats 展示用结构（gfa 字段实为 total_nla，单位 m²） */
export interface PropertyTypeStats {
  /** 可租面积 m²（对应后端 total_nla） */
  gfa: number
  units: number
  vacant: number
  /** 空置率 0~100 整数百分比 */
  vacancyRate: number
}
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import {
  fetchBuilding,
  fetchBuildings,
  fetchFloor,
  fetchFloorHeatmap,
  fetchFloors,
  fetchOverview,
  fetchUnit,
  fetchUnits,
} from '@/api/modules/assets'
import { ApiError } from '@/types/api'
import { fetchSvgWithCache } from '@/composables/useFloorSvgCache'

// ── 错误兜底文案统一管理 ────────────────────────────────────────────────────
function pickErrorMessage(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

// ─── Store 1：楼栋总览（资产首页） ─────────────────────────────────────────

export const useAssetOverviewStore = defineStore('assetOverview', () => {
  // State（固定字段：list / item / loading / error / meta）
  const list = ref<Building[]>([])
  const item = ref<Building | null>(null)
  const meta = ref<PaginationMeta | null>(null)
  const overview = ref<AssetOverview | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters — 全部从后端 overview 数据派生，不在前端重算业务指标

  /** 总套数（含非可租） */
  const totalUnits = computed(() => overview.value?.total_units ?? 0)

  /** 已租套数（leased + expiring_soon，口径与后端 PropertyTypeStats 一致） */
  const totalLeased = computed(() =>
    overview.value?.by_property_type.reduce((s, t) => s + t.leased_units, 0) ?? 0,
  )

  /** 空置套数 */
  const totalVacant = computed(() =>
    overview.value?.by_property_type.reduce((s, t) => s + t.vacant_units, 0) ?? 0,
  )

  /** 总体出租率 0~1 */
  const overallRate = computed(() => overview.value?.total_occupancy_rate ?? 0)

  /** 管理总面积（楼栋 GFA 求和，㎡） */
  const totalGfa = computed(() => list.value.reduce((s, b) => s + b.gfa, 0))

  /** 楼栋总数 */
  const buildingCount = computed(() => list.value.length)

  /** 按业态聚合的展示统计（写字楼 / 商铺 / 公寓） */
  const typeStats = computed<Record<string, PropertyTypeStats>>(() => {
    const result: Record<string, PropertyTypeStats> = {
      office: { gfa: 0, units: 0, vacant: 0, vacancyRate: 0 },
      retail: { gfa: 0, units: 0, vacant: 0, vacancyRate: 0 },
      apartment: { gfa: 0, units: 0, vacant: 0, vacancyRate: 0 },
    }
    for (const t of overview.value?.by_property_type ?? []) {
      const key = t.property_type as PropertyType
      if (!result[key])
        continue
      result[key].gfa = t.total_nla
      result[key].units = t.total_units
      result[key].vacant = t.vacant_units
      result[key].vacancyRate = t.total_units > 0
        ? Math.round((t.vacant_units / t.total_units) * 100)
        : 0
    }
    return result
  })

  // Actions
  async function fetchAll(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      // 并行请求：楼栋列表（用于楼栋卡片渲染）+ 聚合概览（后端计算，避免前端批拉单元）
      const [buildings, stats] = await Promise.all([fetchBuildings(), fetchOverview()])
      list.value = buildings
      overview.value = stats
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
    overview,
    loading,
    error,
    totalUnits,
    totalLeased,
    totalVacant,
    totalGfa,
    buildingCount,
    typeStats,
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
    // 运行时防护：检测调用方意外传入对象而非 UUID 字符串
    if (typeof buildingId !== 'string' || !buildingId) {
      console.error('[useBuildingDetailStore] fetchDetail 收到非字符串 buildingId:', buildingId)
      error.value = '楼栋 ID 无效，请刷新页面重试'
      return
    }
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
  /** 请求序列号：每次 selectFloor 自增，提交结果前校验是否为最新请求，丢弃过期响应 */
  let selectSeq = 0

  /** 加载楼栋下的全部楼层（用于楼层切换标签），并默认选中首个 */
  async function loadByBuilding(bid: string): Promise<void> {
    // 运行时防护：检测调用方意外传入对象而非 UUID 字符串
    if (typeof bid !== 'string' || !bid) {
      console.error('[useFloorMapStore] loadByBuilding 收到非字符串 bid:', bid)
      error.value = '楼栋 ID 无效，请返回重试'
      return
    }
    loading.value = true
    error.value = null
    buildingId.value = bid
    try {
      const fls = await fetchFloors(bid)
      list.value = [...fls].sort((a, b) => b.floor_number - a.floor_number)

      // #ifdef H5 || APP-PLUS
      // 后台预加载各楼层 SVG（floor list 已携带 svg_path，无需额外 API 调用）
      // 静默失败：不影响主流程；fetchSvgWithCache 内置并发去重，首楼层与 demand-load 自动合并 Promise
      const token = uni.getStorageSync('access_token') || ''
      for (const fl of fls) {
        if (fl.svg_path) {
          fetchSvgWithCache(fl.svg_path, token).catch(() => { /* 预加载失败静默忽略，demand-load 时还会重试 */ })
        }
      }
      // #endif

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
    // 每次调用递增序列号，捕获当前值；异步结果提交前校验，丢弃过期响应
    const seq = ++selectSeq
    loading.value = true
    error.value = null
    try {
      const [floor, heatmapData] = await Promise.all([
        fetchFloor(floorId),
        fetchFloorHeatmap(floorId),
      ])
      // 若在等待期间又触发了新的 selectFloor，丢弃本次结果，避免旧数据覆盖新状态
      if (seq !== selectSeq) return
      item.value = floor
      heatmap.value = heatmapData
      // 若标签栏未加载（直链进入），同步拉取所属楼栋的楼层列表
      if (list.value.length === 0 && floor.building_id) {
        buildingId.value = floor.building_id
        const fls = await fetchFloors(floor.building_id)
        // 二次校验：fetchFloors 本身也是异步，防止更晚的 selectFloor 发生在其之后
        if (seq !== selectSeq) return
        list.value = [...fls].sort((a, b) => b.floor_number - a.floor_number)
      }
    } catch (e) {
      if (seq !== selectSeq) return
      error.value = pickErrorMessage(e, '楼层数据加载失败')
    } finally {
      // 仅最新请求负责关闭 loading，避免过期请求提前关闭旋转指示器
      if (seq === selectSeq) loading.value = false
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
