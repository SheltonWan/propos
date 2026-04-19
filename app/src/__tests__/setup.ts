/**
 * uni-app 全局 API mock shim
 *
 * 方案一（当前）：手写轻量 mock，零依赖，覆盖核心 API。
 * 方案二（可选升级）：社区插件如 @uni-helper/vite-plugin-uni-mock，
 *   在 vitest.config.ts setupFiles 数组中追加即可切换。
 */

import { vi } from 'vitest'

const storage = new Map<string, unknown>()

const uni = {
  getStorageSync: vi.fn((key: string) => storage.get(key) ?? ''),
  setStorageSync: vi.fn((key: string, value: unknown) => storage.set(key, value)),
  removeStorageSync: vi.fn((key: string) => storage.delete(key)),
  reLaunch: vi.fn(),
  navigateTo: vi.fn(),
  redirectTo: vi.fn(),
  switchTab: vi.fn(),
  navigateBack: vi.fn(),
  showToast: vi.fn(),
  hideToast: vi.fn(),
  showLoading: vi.fn(),
  hideLoading: vi.fn(),
  showModal: vi.fn(() => Promise.resolve({ confirm: true, cancel: false })),
  addInterceptor: vi.fn(),
  removeInterceptor: vi.fn(),
  hideTabBar: vi.fn(),
}

// 挂到全局
;(globalThis as any).uni = uni
;(globalThis as any).getCurrentPages = vi.fn(() => [])

// 每次测试前重置 storage 和 mock
beforeEach(() => {
  storage.clear()
  vi.clearAllMocks()
})
