import type { ApiListResponse } from '@/types/api'
import type {
  Building,
  Floor,
  FloorHeatmap,
  FloorHeatmapUnit,
  FloorPlan,
  PropertyType,
  Unit,
  UnitStatus,
} from '@/types/assets'
import type { MockHandler, MockResult } from './types'
import { BUILDINGS, FLOORS, UNITS } from '@/constants/api_paths'

// ─── Mock 数据 ─────────────────────────────────────────────────────────────

const NOW = new Date().toISOString()

const MOCK_BUILDINGS: Building[] = [
  {
    id: 'bld-001',
    name: 'A座 · 写字楼',
    property_type: 'office',
    total_floors: 24,
    basement_floors: 2,
    gfa: 32000,
    nla: 26500,
    address: '北京市朝阳区望京东路 1 号',
    built_year: 2015,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'bld-002',
    name: 'B座 · 商铺',
    property_type: 'retail',
    total_floors: 4,
    basement_floors: 1,
    gfa: 6800,
    nla: 5400,
    address: '北京市朝阳区望京东路 1 号',
    built_year: 2015,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    id: 'bld-003',
    name: 'C座 · 公寓',
    property_type: 'apartment',
    total_floors: 18,
    basement_floors: 1,
    gfa: 9200,
    nla: 8100,
    address: '北京市朝阳区望京东路 3 号',
    built_year: 2018,
    created_at: NOW,
    updated_at: NOW,
  },
]

const MOCK_FLOORS: Floor[] = [
  ...Array.from({ length: 6 }, (_, i): Floor => ({
    id: `flr-a-${i + 1}`,
    building_id: 'bld-001',
    building_name: 'A座 · 写字楼',
    floor_number: i + 8,
    floor_name: `${i + 8}F`,
    svg_path: `floors/bld-001/flr-a-${i + 1}.svg`,
    png_path: null,
    nla: 1100 + i * 30,
    created_at: NOW,
    updated_at: NOW,
  })),
  ...Array.from({ length: 3 }, (_, i): Floor => ({
    id: `flr-b-${i + 1}`,
    building_id: 'bld-002',
    building_name: 'B座 · 商铺',
    floor_number: i + 1,
    floor_name: `${i + 1}F`,
    svg_path: null,
    png_path: null,
    nla: 1800 + i * 100,
    created_at: NOW,
    updated_at: NOW,
  })),
  ...Array.from({ length: 4 }, (_, i): Floor => ({
    id: `flr-c-${i + 1}`,
    building_id: 'bld-003',
    building_name: 'C座 · 公寓',
    floor_number: i + 5,
    floor_name: `${i + 5}F`,
    svg_path: null,
    png_path: null,
    nla: 480 + i * 20,
    created_at: NOW,
    updated_at: NOW,
  })),
]

const STATUS_CYCLE: UnitStatus[] = ['leased', 'leased', 'leased', 'expiring_soon', 'vacant', 'non_leasable']

function buildingPropertyType(buildingId: string): PropertyType {
  const b = MOCK_BUILDINGS.find(x => x.id === buildingId)
  return (b?.property_type === 'mixed' ? 'office' : b?.property_type) ?? 'office'
}

const MOCK_UNITS: Unit[] = MOCK_FLOORS.flatMap((floor) => {
  const ptype = buildingPropertyType(floor.building_id)
  const count = ptype === 'apartment' ? 8 : 6
  return Array.from({ length: count }, (_, i): Unit => {
    const status = STATUS_CYCLE[i % STATUS_CYCLE.length]
    const isLeasable = status !== 'non_leasable'
    return {
      id: `${floor.id}-u-${i + 1}`,
      building_id: floor.building_id,
      building_name: floor.building_name,
      floor_id: floor.id,
      floor_name: floor.floor_name,
      unit_number: `${floor.floor_number}${String.fromCharCode(65 + Math.floor(i / 2))}${((i % 2) + 1).toString().padStart(2, '0')}`,
      property_type: ptype,
      gross_area: 80 + i * 12,
      net_area: 70 + i * 10,
      orientation: (['east', 'south', 'west', 'north'] as const)[i % 4],
      ceiling_height: 3.6,
      decoration_status: 'refined',
      current_status: status,
      is_leasable: isLeasable,
      ext_fields: ptype === 'office' ? { workstation_count: 8 + i * 2 } : {},
      current_contract_id: status === 'leased' || status === 'expiring_soon' ? `ct-${floor.id}-${i}` : null,
      qr_code: null,
      market_rent_reference: ptype === 'office' ? 280 : ptype === 'retail' ? 520 : 180,
      predecessor_unit_ids: [],
      archived_at: null,
      created_at: NOW,
      updated_at: NOW,
    }
  })
})

const TENANT_NAMES = ['京东物流', '字节跳动', '美团点评', '小米通讯', '比亚迪', '宁德时代', '华润置地', '链家网络']

function buildHeatmap(floorId: string): FloorHeatmap {
  const floor = MOCK_FLOORS.find(f => f.id === floorId)
  const units = MOCK_UNITS.filter(u => u.floor_id === floorId)
  return {
    floor_id: floorId,
    svg_path: floor?.svg_path ?? null,
    units: units.map((u, i): FloorHeatmapUnit => ({
      unit_id: u.id,
      unit_number: u.unit_number,
      current_status: u.current_status,
      property_type: u.property_type,
      tenant_name: u.current_contract_id ? TENANT_NAMES[i % TENANT_NAMES.length] : null,
      contract_end_date: u.current_status === 'expiring_soon'
        ? '2026-08-31'
        : u.current_status === 'leased' ? '2027-12-31' : null,
      area_sqm: 80 + (i % 5) * 20,
      contract_id: u.current_contract_id ?? null,
    })),
  }
}

// ─── 路径解析辅助 ───────────────────────────────────────────────────────────

/** 从 url 提取 :id（取 BUILDINGS / FLOORS / UNITS 后第一个 segment） */
function extractId(url: string, prefix: string): string | null {
  if (!url.startsWith(`${prefix}/`)) return null
  const tail = url.slice(prefix.length + 1)
  const seg = tail.split('/')[0]
  return seg || null
}

function isExactPath(url: string, prefix: string): boolean {
  return url === prefix
}

function isSubResource(url: string, prefix: string, sub: string): { id: string } | null {
  if (!url.startsWith(`${prefix}/`)) return null
  const parts = url.slice(prefix.length + 1).split('/')
  if (parts.length === 2 && parts[1] === sub) return { id: parts[0] }
  return null
}

// ─── 通用 GET 处理 ─────────────────────────────────────────────────────────

function handleGet(url: string, body?: unknown): MockResult {
  // /api/buildings
  if (isExactPath(url, BUILDINGS)) {
    return { delay: 250, data: MOCK_BUILDINGS }
  }
  // /api/buildings/:id
  const buildingId = extractId(url, BUILDINGS)
  if (buildingId) {
    const item = MOCK_BUILDINGS.find(b => b.id === buildingId)
    if (item) return { delay: 200, data: item }
    return { delay: 200, error: { code: 'BUILDING_NOT_FOUND', message: '楼栋不存在', status: 404 } }
  }

  // /api/floors/:id/heatmap
  const heatmap = isSubResource(url, FLOORS, 'heatmap')
  if (heatmap) return { delay: 300, data: buildHeatmap(heatmap.id) }

  // /api/floors/:id/plans
  const plans = isSubResource(url, FLOORS, 'plans')
  if (plans) {
    const floor = MOCK_FLOORS.find(f => f.id === plans.id)
    const list: FloorPlan[] = floor && floor.svg_path
      ? [{
          id: `${plans.id}-plan-1`,
          floor_id: plans.id,
          version: 1,
          svg_path: floor.svg_path,
          png_path: floor.png_path,
          is_current: true,
          uploaded_by: null,
          uploaded_at: NOW,
        }]
      : []
    return { delay: 200, data: list }
  }

  // /api/floors
  if (isExactPath(url, FLOORS)) {
    const params = (body ?? {}) as { building_id?: string }
    const list = params.building_id
      ? MOCK_FLOORS.filter(f => f.building_id === params.building_id)
      : MOCK_FLOORS
    return { delay: 220, data: list }
  }
  // /api/floors/:id
  const floorId = extractId(url, FLOORS)
  if (floorId) {
    const item = MOCK_FLOORS.find(f => f.id === floorId)
    if (item) return { delay: 180, data: item }
    return { delay: 180, error: { code: 'FLOOR_NOT_FOUND', message: '楼层不存在', status: 404 } }
  }

  // /api/units
  if (isExactPath(url, UNITS)) {
    const params = (body ?? {}) as {
      building_id?: string
      floor_id?: string
      property_type?: PropertyType
      current_status?: UnitStatus
      is_leasable?: boolean
      page?: number
      pageSize?: number
    }
    let filtered = MOCK_UNITS
    if (params.building_id) filtered = filtered.filter(u => u.building_id === params.building_id)
    if (params.floor_id) filtered = filtered.filter(u => u.floor_id === params.floor_id)
    if (params.property_type) filtered = filtered.filter(u => u.property_type === params.property_type)
    if (params.current_status) filtered = filtered.filter(u => u.current_status === params.current_status)
    if (typeof params.is_leasable === 'boolean') filtered = filtered.filter(u => u.is_leasable === params.is_leasable)

    const page = params.page ?? 1
    const pageSize = params.pageSize ?? 20
    const total = filtered.length
    const start = (page - 1) * pageSize
    const data = filtered.slice(start, start + pageSize)
    const result: ApiListResponse<Unit> = { data, meta: { page, pageSize, total } }
    return { delay: 280, data: result }
  }
  // /api/units/:id
  const unitId = extractId(url, UNITS)
  if (unitId) {
    const item = MOCK_UNITS.find(u => u.id === unitId)
    if (item) return { delay: 200, data: item }
    return { delay: 200, error: { code: 'UNIT_NOT_FOUND', message: '房源不存在', status: 404 } }
  }

  return { delay: 0, error: { code: 'MOCK_NOT_FOUND', message: 'mock 路由未匹配', status: 404 } }
}

// ─── 导出 handlers ─────────────────────────────────────────────────────────

// 现有 mock 框架按 url 全等匹配，故为列表精确路径与每个有限 ID 的详情/子资源
// 分别注册 handler；所有 handler 共享同一 handleGet 实现。
const subResources = ['heatmap', 'plans']

function buildAllHandlers(): MockHandler[] {
  const handlers: MockHandler[] = []

  // 列表
  handlers.push({ method: 'GET', url: BUILDINGS, handler: handleGet })
  handlers.push({ method: 'GET', url: FLOORS, handler: handleGet })
  handlers.push({ method: 'GET', url: UNITS, handler: handleGet })

  // 楼栋详情
  for (const b of MOCK_BUILDINGS) {
    handlers.push({ method: 'GET', url: `${BUILDINGS}/${b.id}`, handler: handleGet })
  }
  // 楼层详情 / heatmap / plans
  for (const f of MOCK_FLOORS) {
    handlers.push({ method: 'GET', url: `${FLOORS}/${f.id}`, handler: handleGet })
    for (const sub of subResources) {
      handlers.push({ method: 'GET', url: `${FLOORS}/${f.id}/${sub}`, handler: handleGet })
    }
  }
  // 房源详情
  for (const u of MOCK_UNITS) {
    handlers.push({ method: 'GET', url: `${UNITS}/${u.id}`, handler: handleGet })
  }

  return handlers
}

export const assetsMocks: MockHandler[] = buildAllHandlers()
