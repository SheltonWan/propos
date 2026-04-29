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
  CadImportJob,
  ContractSummary,
  Floor,
  FloorHeatmap,
  FloorPlan,
  ImportBatchDetail,
  RenovationCreateRequest,
  RenovationPhotoStage,
  RenovationRecord,
  Unit,
  UnitStatus,
  UnitUpdateRequest,
} from '@/types/asset'
import {
  assignUnmatchedSvg as apiAssignUnmatchedSvg,
  createRenovation as apiCreateRenovation,
  exportUnits as apiExportUnits,
  fetchAssetOverview,
  fetchBuilding,
  fetchBuildings,
  fetchCadImportJob as apiFetchCadImportJob,
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
  uploadBuildingDxf as apiUploadBuildingDxf,
  uploadFloorCad as apiUploadFloorCad,
  uploadRenovationPhoto as apiUploadRenovationPhoto,
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
    // 运行时防护：检测调用方意外传入对象（如 Building 整体或 Ref<Building>）而非 UUID 字符串
    if (typeof buildingId !== 'string' || !buildingId) {
      console.error('[useBuildingDetailStore] fetchDetail 收到非字符串 buildingId:', buildingId)
      error.value = '楼栋 ID 无效，请刷新页面重试'
      return
    }
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

  /** 上传 .dwg 图纸触发后端转换；上传成功后立即刷新一次（首次返回 status=converting） */
  async function uploadCad(file: File, versionLabel: string): Promise<void> {
    if (!item.value) return
    error.value = null
    try {
      await apiUploadFloorCad(item.value.id, file, versionLabel)
      // 转换异步执行，但版本记录已落库；先刷一次，UI 上版本会出现“转换中/未生效”
      await fetchMap(item.value.id)
    } catch (e) {
      error.value = _msg(e, '上传图纸失败')
      throw e
    }
  }

  function reset(): void {
    item.value = null
    heatmap.value = null
    plans.value = []
    error.value = null
  }

  return { item, heatmap, plans, loading, error, fetchMap, setCurrentPlan, uploadCad, reset }
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

  /** 上传改造前/后照片，并就地更新对应记录的 *_photo_paths */
  async function uploadRenovationPhoto(
    renovationId: string,
    file: File,
    stage: RenovationPhotoStage,
  ): Promise<void> {
    saving.value = true
    error.value = null
    try {
      const res = await apiUploadRenovationPhoto(renovationId, file, stage)
      const idx = renovations.value.findIndex((r) => r.id === renovationId)
      if (idx >= 0) {
        const rec = renovations.value[idx]
        const key: keyof RenovationRecord =
          stage === 'before' ? 'before_photo_paths' : 'after_photo_paths'
        const prev = (rec[key] as string[]) ?? []
        renovations.value = [
          ...renovations.value.slice(0, idx),
          { ...rec, [key]: [...prev, res.storage_path] },
          ...renovations.value.slice(idx + 1),
        ]
      }
    } catch (e) {
      error.value = _msg(e, '上传照片失败')
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
    uploadRenovationPhoto,
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

// ─── 7. 楼栋级 DXF 导入（Day 14）──────────────────────

/**
 * useCadImportStore — 楼栋级 DXF 上传 + 异步切分 + 未匹配指派的 Pinia store。
 *
 * 流程：
 *   1. upload(buildingId, file) → 立即拿到 job，状态 'uploaded'
 *   2. startPolling(jobId) → 每 2s 轮询一次 GET /cad-import-jobs/:id，
 *      直到 status = done 或 failed 自动停止
 *   3. assign(svgLabel, floorId) → 手动指派单个 SVG 到楼层
 *   4. reset() → 关闭对话框时清理所有状态与 timer
 *
 * 注意：本 store 是「会话级」状态，不缓存历史任务记录；每次打开对话框前
 *       调用 reset() 清空。
 */
export const useCadImportStore = defineStore('cadImport', () => {
  const job = ref<CadImportJob | null>(null)
  const loading = ref(false)
  const polling = ref(false)
  const error = ref<string | null>(null)

  let pollTimer: ReturnType<typeof setInterval> | null = null

  /** 是否处于「切分中」状态，用于 UI loading 提示 */
  const isProcessing = computed(
    () => job.value != null && (job.value.status === 'uploaded' || job.value.status === 'splitting'),
  )

  /** 是否已完成（包含 done / failed） */
  const isFinished = computed(
    () => job.value != null && (job.value.status === 'done' || job.value.status === 'failed'),
  )

  async function upload(buildingId: string, file: File): Promise<CadImportJob | null> {
    loading.value = true
    error.value = null
    try {
      const j = await apiUploadBuildingDxf(buildingId, file)
      job.value = j
      startPolling(j.id)
      return j
    } catch (e) {
      error.value = _msg(e, 'DXF 上传失败')
      return null
    } finally {
      loading.value = false
    }
  }

  function startPolling(jobId: string): void {
    stopPolling()
    polling.value = true
    pollTimer = setInterval(() => {
      void refresh(jobId)
    }, 2000)
  }

  function stopPolling(): void {
    if (pollTimer != null) {
      clearInterval(pollTimer)
      pollTimer = null
    }
    polling.value = false
  }

  async function refresh(jobId: string): Promise<void> {
    try {
      const j = await apiFetchCadImportJob(jobId)
      job.value = j
      if (j.status === 'done' || j.status === 'failed') {
        stopPolling()
      }
    } catch (e) {
      // 轮询期间的临时错误不直接清空 job，但要展示给用户
      error.value = _msg(e, '查询任务状态失败')
    }
  }

  async function assign(svgLabel: string, floorId: string): Promise<boolean> {
    if (job.value == null) return false
    error.value = null
    try {
      job.value = await apiAssignUnmatchedSvg(job.value.id, {
        svg_label: svgLabel,
        floor_id: floorId,
      })
      return true
    } catch (e) {
      error.value = _msg(e, '指派失败')
      return false
    }
  }

  function reset(): void {
    stopPolling()
    job.value = null
    error.value = null
    loading.value = false
  }

  return {
    job,
    loading,
    polling,
    error,
    isProcessing,
    isFinished,
    upload,
    refresh,
    assign,
    reset,
  }
})
