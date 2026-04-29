import type { MockHandler, MockMethod } from './types'
import { ApiError } from '@/types/api'
import { assetsMocks } from './assets'
import { authMocks } from './auth'

// ─── 注册表：所有模块的 mock handlers 汇总于此 ────────────────────────────
// 新增业务模块时，只需：1) 创建 mock/xxx.ts  2) 在此 spread 进 handlers
const handlers: MockHandler[] = [
  ...authMocks,
  ...assetsMocks,
]

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * 尝试匹配 mock handler。
 * - 匹配成功 → 模拟延迟后返回 data 或抛出 ApiError
 * - 未匹配   → 返回 null（由调用方 fallthrough 到真实 HTTP）
 */
export async function matchMock<T = unknown>(
  method: MockMethod,
  url: string,
  body?: unknown,
): Promise<T | null> {
  const matched = handlers.find(h => h.method === method && h.url === url)
  if (!matched)
    return null

  const result = matched.handler(url, body)
  if (result.delay > 0)
    await sleep(result.delay)

  if (result.error) {
    throw new ApiError(result.error.code, result.error.message, result.error.status)
  }
  return (result.data ?? null) as T
}
