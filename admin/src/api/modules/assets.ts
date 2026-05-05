/**
 * M1 资产模块 API 函数
 * 端点清单：参考 docs/backend/API_INVENTORY_v1.7.md L66-88
 */

import { apiGet, apiGetList, apiPost, apiPatch, apiDelete, apiPostForm } from '@/api/client'
import http from '@/api/client'
import type { ApiListResponse } from '@/types/api'
import type {
  AssetOverviewStats,
  Building,
  CadImportJob,
  ContractSummary,
  FloorCadUploadResponse,
  Floor,
  FloorHeatmap,
  FloorPlan,
  ImportBatchDetail,
  PropertyType,
  RenovationCreateRequest,
  RenovationListParams,
  RenovationPhotoStage,
  RenovationPhotoUploadResponse,
  RenovationRecord,
  Unit,
  UnitListParams,
  UnitUpdateRequest,
} from '@/types/asset'
import {
  API_ASSETS_SUMMARY,
  API_BUILDINGS,
  API_CAD_IMPORT_JOBS,
  API_CONTRACTS,
  API_FLOORS,
  API_FLOOR_PLANS,
  API_RENOVATIONS,
  API_UNITS,
  API_UNITS_EXPORT,
  API_UNITS_IMPORT,
} from '@/constants/api_paths'

// /api/assets/summary 是历史命名，新接口为 /api/assets/overview
const API_ASSETS_OVERVIEW = '/api/assets/overview'

// ─── 楼栋 ──────────────────────────────────────────────

/** GET /api/buildings — 楼栋列表（不分页） */
export async function fetchBuildings(): Promise<Building[]> {
  return apiGet<Building[]>(API_BUILDINGS)
}

/** GET /api/buildings/:id — 楼栋详情 */
export async function fetchBuilding(id: string): Promise<Building> {
  return apiGet<Building>(`${API_BUILDINGS}/${id}`)
}

/** POST /api/buildings — 创建楼栋 */
export async function createBuilding(payload: {
  name: string
  property_type: string
  total_floors: number
  gfa: number
  nla: number
  address?: string | null
  built_year?: number | null
}): Promise<Building> {
  return apiPost<Building>(API_BUILDINGS, payload)
}

/** POST /api/buildings/with-floors — 创建楼栋并自动批量创建地下/地上楼层（事务） */
export async function createBuildingWithFloors(payload: {
  name: string
  property_type: string
  total_floors: number
  gfa: number
  nla: number
  address?: string | null
  built_year?: number | null
  basement_floors?: number
}): Promise<{ building: Building; floors: Floor[] }> {
  return apiPost<{ building: Building; floors: Floor[] }>(
    `${API_BUILDINGS}/with-floors`,
    payload,
  )
}

/** PATCH /api/buildings/:id — 更新楼栋（可传 total_floors / basement_floors 调整地上/地下层数，仅可增不可减） */
export async function updateBuilding(
  id: string,
  payload: Partial<{
    name: string
    property_type: string
    total_floors: number
    basement_floors: number
    gfa: number
    nla: number
    address: string | null
    built_year: number | null
  }>,
): Promise<Building> {
  return apiPatch<Building>(`${API_BUILDINGS}/${id}`, payload)
}

/** DELETE /api/buildings/:id — 删除楼栋（仅可删除未关联单元/工单/账单的楼栋） */
export async function deleteBuilding(id: string): Promise<void> {
  return apiDelete(`${API_BUILDINGS}/${id}`)
}

// ─── 楼层 ──────────────────────────────────────────────

/** GET /api/floors?building_id= — 楼层列表 */
export async function fetchFloors(buildingId?: string): Promise<Floor[]> {
  return apiGet<Floor[]>(API_FLOORS, buildingId ? { building_id: buildingId } : undefined)
}

/** GET /api/floors/:id — 楼层详情 */
export async function fetchFloor(id: string): Promise<Floor> {
  return apiGet<Floor>(`${API_FLOORS}/${id}`)
}

/** POST /api/floors — 新建楼层 */
export async function createFloor(payload: {
  building_id: string
  floor_number: number
  floor_name?: string
  nla?: number
  property_type?: PropertyType
}): Promise<Floor> {
  return apiPost<Floor>(API_FLOORS, payload)
}

/** PATCH /api/floors/:id — 更新楼层属性（业态/楼层名/NLA）；响应含 updated_unit_count */
export async function patchFloor(
  id: string,
  payload: { property_type?: PropertyType; floor_name?: string; nla?: number },
): Promise<Floor> {
  return apiPatch<Floor>(`${API_FLOORS}/${id}`, payload)
}

/** GET /api/floors/:id/heatmap — 楼层热区状态图 */
export async function fetchFloorHeatmap(floorId: string): Promise<FloorHeatmap> {
  return apiGet<FloorHeatmap>(`${API_FLOORS}/${floorId}/heatmap`)
}

/** GET /api/floors/:id/plans — 图纸版本列表 */
export async function fetchFloorPlans(floorId: string): Promise<FloorPlan[]> {
  return apiGet<FloorPlan[]>(`${API_FLOORS}/${floorId}/plans`)
}

/** PATCH /api/floor-plans/:id/set-current — 设为当前生效版本 */
export async function setCurrentFloorPlan(planId: string): Promise<FloorPlan> {
  return apiPatch<FloorPlan>(`${API_FLOOR_PLANS}/${planId}/set-current`)
}

// ─── 单元 ──────────────────────────────────────────────

/** GET /api/units — 单元分页列表 */
export async function fetchUnits(
  params: UnitListParams = {},
): Promise<ApiListResponse<Unit>> {
  return apiGetList<Unit>(API_UNITS, params as Record<string, unknown>)
}

/** GET /api/units/:id — 单元详情 */
export async function fetchUnit(id: string): Promise<Unit> {
  return apiGet<Unit>(`${API_UNITS}/${id}`)
}

// ─── 改造记录 ──────────────────────────────────────────

/** GET /api/renovations — 改造记录列表 */
export async function fetchRenovations(
  params: RenovationListParams = {},
): Promise<ApiListResponse<RenovationRecord>> {
  return apiGetList<RenovationRecord>(API_RENOVATIONS, params as Record<string, unknown>)
}

// ─── 资产概览 ──────────────────────────────────────────

/** GET /api/assets/overview — 三业态概览统计 */
export async function fetchAssetOverview(): Promise<AssetOverviewStats> {
  return apiGet<AssetOverviewStats>(API_ASSETS_OVERVIEW)
}

/** 兼容旧名 /api/assets/summary（如未来需要恢复使用） */
export const ASSETS_SUMMARY_PATH = API_ASSETS_SUMMARY

// ─── 单元更新 ──────────────────────────────────────────

/** PATCH /api/units/:id — 更新单元（M1 房源详情编辑） */
export async function patchUnit(id: string, payload: UnitUpdateRequest): Promise<Unit> {
  return apiPatch<Unit>(`${API_UNITS}/${id}`, payload)
}

// ─── 改造记录新增 ──────────────────────────────────────

/** POST /api/renovations — 新增改造记录 */
export async function createRenovation(
  payload: RenovationCreateRequest,
): Promise<RenovationRecord> {
  return apiPost<RenovationRecord>(API_RENOVATIONS, payload)
}

// ─── 合同摘要（M1 房源详情展示当前合同信息）─────────────

/** GET /api/contracts/:id — 合同详情，仅消费 ContractSummary 字段子集 */
export async function fetchContractSummary(id: string): Promise<ContractSummary> {
  return apiGet<ContractSummary>(`${API_CONTRACTS}/${id}`)
}

// ─── 批量导入 ──────────────────────────────────────────

/** POST /api/units/import — 批量导入单元（dry_run 预校验或正式入库） */
export async function importUnits(
  file: File,
  dryRun: boolean,
): Promise<ImportBatchDetail> {
  const form = new FormData()
  form.append('file', file)
  form.append('dry_run', String(dryRun))
  return apiPostForm<ImportBatchDetail>(API_UNITS_IMPORT, form)
}

/** GET /api/units/export — 导出房源台账 Excel 二进制流 */
export async function exportUnits(propertyType?: string): Promise<Blob> {
  const res = await http.get(API_UNITS_EXPORT, {
    params: propertyType ? { property_type: propertyType } : {},
    responseType: 'blob',
  })
  return res.data as Blob
}

// ─── 改造照片上传（§2.21）─────────────────────────────

/** POST /api/renovations/:id/photos — 上传改造前/后照片 */
export async function uploadRenovationPhoto(
  renovationId: string,
  file: File,
  photoStage: RenovationPhotoStage,
): Promise<RenovationPhotoUploadResponse> {
  const form = new FormData()
  form.append('file', file)
  form.append('photo_stage', photoStage)
  return apiPostForm<RenovationPhotoUploadResponse>(
    `${API_RENOVATIONS}/${renovationId}/photos`,
    form,
  )
}

// ─── 楼层图纸上传（§2.8）──────────────────────────────

/** POST /api/floors/:id/cad — 上传 .dwg 并触发转换 */
export async function uploadFloorCad(
  floorId: string,
  file: File,
  versionLabel: string,
): Promise<FloorCadUploadResponse> {
  const form = new FormData()
  form.append('file', file)
  form.append('version_label', versionLabel)
  return apiPostForm<FloorCadUploadResponse>(`${API_FLOORS}/${floorId}/cad`, form)
}

// ─── 楼栋级 DXF 导入（Day 14）─────────────────────────

/** POST /api/buildings/:id/cad-upload — 上传整栋 DXF，立即返回任务记录 */
export async function uploadBuildingDxf(
  buildingId: string,
  file: File,
): Promise<CadImportJob> {
  const form = new FormData()
  form.append('file', file)
  return apiPostForm<CadImportJob>(`${API_BUILDINGS}/${buildingId}/cad-upload`, form)
}

/** GET /api/cad-import-jobs/:id — 查询任务状态（前端轮询） */
export async function fetchCadImportJob(jobId: string): Promise<CadImportJob> {
  return apiGet<CadImportJob>(`${API_CAD_IMPORT_JOBS}/${jobId}`)
}

/** PATCH /api/cad-import-jobs/:id/assign — 手动指派未匹配 SVG 到楼层（可同时设置楼层业态） */
export async function assignUnmatchedSvg(
  jobId: string,
  payload: { svg_label: string; floor_id: string; property_type?: PropertyType },
): Promise<CadImportJob> {
  return apiPatch<CadImportJob>(`${API_CAD_IMPORT_JOBS}/${jobId}/assign`, payload)
}
