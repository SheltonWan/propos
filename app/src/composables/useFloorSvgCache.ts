/**
 * SVG 楼层图缓存工具
 *
 * 两级防护：
 *   1. 内存 Map 缓存（svgPath → svg 文本）— 同一会话内楼层来回切换命中缓存，零网络请求
 *   2. 并发请求去重（svgPath → Promise）— 同一 svgPath 同时触发多次加载只发一次网络请求
 *
 * 刻意不使用 Pinia store：SVG 文本是纯工具型资产，不需要响应式追踪，
 * 模块级 Map 即可在所有组件实例间共享，且内存开销更低。
 *
 * 缓存生命周期：应用 session 级别（刷新/重启后清空）。
 * CAD-SVG 文件变更极低频（重新上传时），session 级 TTL 不引入失效问题。
 */

import { buildFileProxyUrl } from '@/constants/api_paths'

// ── 模块级缓存状态（跨组件实例共享） ────────────────────────────────────────

/** 已成功拉取的 SVG 文本缓存。key = svgPath（后端相对路径） */
const svgTextCache = new Map<string, string>()

/** 正在进行中的 fetch Promise。key = svgPath（防止并发重复请求） */
const inFlight = new Map<string, Promise<string>>()

// ── 公共接口 ─────────────────────────────────────────────────────────────────

/**
 * 获取 SVG 文本（优先命中缓存，未命中时发起网络请求并缓存结果）。
 *
 * @param svgPath 后端返回的相对路径，如 `floors/{bid}/{fid}.svg`
 * @param token   Bearer token（来自 uni.getStorageSync('access_token')）
 * @returns       SVG 原始文本（含 `<svg>` 根标签）
 * @throws        HTTP 请求失败或响应为空时抛出 Error
 */
export function fetchSvgWithCache(svgPath: string, token: string): Promise<string> {
  // 命中内存缓存：直接返回
  const cached = svgTextCache.get(svgPath)
  if (cached) {
    console.info('[FloorSvgCache] 命中缓存:', svgPath, '长度:', cached.length)
    return Promise.resolve(cached)
  }

  // 命中 in-flight：复用同一 Promise，避免并发重复请求
  const flying = inFlight.get(svgPath)
  if (flying) {
    console.info('[FloorSvgCache] 复用进行中的请求:', svgPath)
    return flying
  }

  // 发起新请求
  const promise = _doFetch(svgPath, token)
    .then((text) => {
      svgTextCache.set(svgPath, text)
      return text
    })
    .finally(() => {
      inFlight.delete(svgPath)
    })

  inFlight.set(svgPath, promise)
  return promise
}

/**
 * 主动淘汰单个楼层的 SVG 缓存（CAD 重新上传后调用）。
 * 通常不需要主动调用；若后端 svg_path URL 发生变化（含版本参数），缓存自然失效。
 */
export function evictSvgCache(svgPath: string): void {
  svgTextCache.delete(svgPath)
  // in-flight 不强行取消，正在进行的请求完成后 finally 会自行清理
}

/**
 * 清空所有 SVG 缓存（用于退出登录或强制刷新场景）。
 */
export function clearSvgCache(): void {
  svgTextCache.clear()
  // 不清理 inFlight，等待进行中请求自然结束
}

/** 当前缓存条目数（调试/测试用） */
export function svgCacheSize(): number {
  return svgTextCache.size
}

// ── 内部实现 ─────────────────────────────────────────────────────────────────

/**
 * 使用 `uni.request` 拉取 SVG 文本。
 * 封装原因：
 *   • H5 — 底层走 XHR，遵守 CORS；
 *   • App-plus — 原生网络栈，绕过 CORS；
 *   • 统一设置 Accept / Authorization / responseType。
 */
function _doFetch(svgPath: string, token: string): Promise<string> {
  const url = buildFileProxyUrl(svgPath)
  console.info('[FloorSvgCache] 开始网络请求:', url)
  return new Promise<string>((resolve, reject) => {
    uni.request({
      url,
      method: 'GET',
      header: {
        Accept: 'image/svg+xml,*/*',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      // 让响应保持为字符串而非被 JSON 解析
      dataType: '其他' as unknown as 'json',
      responseType: 'text',
      success: (res) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const text = typeof res.data === 'string' ? res.data : String(res.data)
          if (!text) {
            reject(new Error('empty svg response'))
          } else {
            resolve(text)
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}`))
        }
      },
      fail: (err) => reject(new Error(err.errMsg || 'request failed')),
    })
  })
}
