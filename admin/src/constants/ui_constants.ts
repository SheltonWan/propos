// UI 展示常量
export const DEFAULT_PAGE_SIZE = 20
export const MAX_PAGE_SIZE = 100
export const CONTENT_MAX_WIDTH_PX = 1200
export const CARD_MAX_WIDTH_PX = 480
export const ANIM_DURATION_MS = 200
export const SIDEBAR_WIDTH_PX = 240
export const SIDEBAR_COLLAPSED_WIDTH_PX = 64
export const ALERT_POLL_INTERVAL_MS = 30_000

// 楼层结构标注：撤销/重做历史栈深度
export const FLOOR_STRUCTURE_HISTORY_LIMIT = 20

// 楼层结构标注：结构类型颜色（全部使用 CSS 变量，禁止 #xxx 硬编码）
import type { AnyStructureType } from '@/types/floorMap'

export const STRUCTURE_TYPE_COLORS: Record<AnyStructureType, string> = {
  core: 'var(--floor-core)',
  elevator: 'var(--floor-elevator)',
  stair: 'var(--floor-stair)',
  restroom: 'var(--floor-restroom)',
  equipment: 'var(--floor-equipment)',
  corridor: 'var(--floor-corridor)',
  column: 'var(--floor-column)',
}

// 结构类型中文标签
export const STRUCTURE_TYPE_LABELS: Record<AnyStructureType, string> = {
  core: '核心筒',
  elevator: '电梯',
  stair: '楼梯',
  restroom: '卫生间',
  equipment: '设备间',
  corridor: '走廊',
  column: '柱位',
}
