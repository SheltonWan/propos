/**
 * 模块开关 / 灰度发布开关
 *
 * 用于在某些后端模块尚未交付时，关闭依赖该模块的前端入口（按钮、链接、卡片），
 * 避免用户点击后陷入"路由不存在 / 接口 404"的死路。
 *
 * 当对应模块整体上线后，将开关置为 true 即可一处生效，所有引用点同步开放。
 */

/// M2（租务与合同管理）模块是否已交付。
/// 控制：M1 资产页中的"查看合同详情"链接是否显示。
export const M2_CONTRACT_ENABLED = false

/// M3（财务与 NOI）模块是否已交付。
export const M3_FINANCE_ENABLED = false

/// M4（工单系统）模块是否已交付。
export const M4_WORKORDER_ENABLED = false

/// M5（二房东穿透管理）模块是否已交付。
export const M5_SUBLEASE_ENABLED = false
