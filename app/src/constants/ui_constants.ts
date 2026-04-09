/**
 * UI 展示常量
 * 对应 frontend ui_constants.dart
 */

// ── 分页 ─────────────────────────────────────────────────
export const DEFAULT_PAGE_SIZE = 20
export const MAX_PAGE_SIZE = 100

// ── 布局（rpx，uni-app 跨端适配单位） ────────────────────
/** 内容区最大宽度（H5 / PC 浏览器生效） */
export const CONTENT_MAX_WIDTH_PX = 1200
/** 卡片最大宽度 */
export const CARD_MAX_WIDTH_PX = 480

// ── 动画 ─────────────────────────────────────────────────
export const ANIM_DURATION_MS = 200

// ── 轮询间隔（ms） ──────────────────────────────────────
/** 未读告警轮询间隔（PC 端 / H5 替代推送） */
export const ALERT_POLL_INTERVAL_MS = 30_000
