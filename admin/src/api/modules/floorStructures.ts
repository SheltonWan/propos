/**
 * 楼层结构标注 API 模块（Floor Map v2）
 * 端点契约：docs/backend/API_CONTRACT_v1.7.md / FLOOR_STRUCTURE_ANNOTATOR_IMPL_PLAN.md
 */
import { apiGet, apiPut, apiPatch, type WithHeaders } from '@/api/client'
import {
  apiFloorStructureCandidates,
  apiFloorStructures,
  apiFloorRenderMode,
} from '@/constants/api_paths'
import type { FloorMapV2, RenderModeChangeResult } from '@/types/floorMap'

/**
 * 获取候选项（DXF 自动抽取，仅 source=auto）
 * 后端在尚未抽取时返回 404 FLOOR_MAP_CANDIDATES_NOT_GENERATED
 */
export const getCandidates = (floorId: string): Promise<FloorMapV2> =>
  apiGet<FloorMapV2>(apiFloorStructureCandidates(floorId))

/**
 * 获取已确认结构（上次 PUT 保存的数据）
 * 同时返回响应头，用于读取 ETag 作为乐观锁版本号
 */
export const getConfirmedStructures = (
  floorId: string,
): Promise<WithHeaders<FloorMapV2>> =>
  apiGet<FloorMapV2>(apiFloorStructures(floorId), { withResponseHeaders: true })

/**
 * 保存审核后的结构（覆盖写）
 * @param ifMatch 上次拉取/保存的 ETag 值，用于乐观锁；冲突时后端返回 409 FLOOR_MAP_VERSION_CONFLICT
 */
export const putStructures = (
  floorId: string,
  payload: FloorMapV2,
  ifMatch?: string,
): Promise<WithHeaders<FloorMapV2>> =>
  apiPut<FloorMapV2>(apiFloorStructures(floorId), payload, {
    withResponseHeaders: true,
    headers: ifMatch ? { 'If-Match': ifMatch } : undefined,
  })

/**
 * 切换渲染模式（vector ↔ semantic）
 * semantic 模式要求 outline 完整且至少含 1 个 core/corridor 结构，否则返回 422 FLOOR_MAP_NOT_READY_FOR_SEMANTIC
 */
export const patchRenderMode = (
  floorId: string,
  renderMode: 'vector' | 'semantic',
): Promise<RenderModeChangeResult> =>
  apiPatch<RenderModeChangeResult>(apiFloorRenderMode(floorId), {
    render_mode: renderMode,
  })
