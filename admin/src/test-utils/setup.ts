/**
 * 全局测试初始化
 * Element Plus 在各组件测试中通过 render() 的 global.plugins 注入（见各 *.test.ts）
 * 此处提供 localStorage mock 并在每次测试前清空，防止 token 污染跨用例
 */

import { beforeEach, vi } from 'vitest'

// 提供完整的 localStorage mock（jsdom 版本可能缺少部分方法）
const _store = new Map<string, string>()
const localStorageMock = {
  getItem: vi.fn((key: string) => _store.get(key) ?? null),
  setItem: vi.fn((key: string, value: string) => _store.set(key, value)),
  removeItem: vi.fn((key: string) => _store.delete(key)),
  clear: vi.fn(() => _store.clear()),
  get length() { return _store.size },
  key: vi.fn((index: number) => Array.from(_store.keys())[index] ?? null),
}

vi.stubGlobal('localStorage', localStorageMock)

// 每次测试前清空存储和 mock 调用记录
beforeEach(() => {
  _store.clear()
  vi.clearAllMocks()
  // 重新绑定 mock 函数（clearAllMocks 会重置实现，需重新指定）
  localStorageMock.getItem.mockImplementation((key: string) => _store.get(key) ?? null)
  localStorageMock.setItem.mockImplementation((key: string, value: string) => _store.set(key, value))
  localStorageMock.removeItem.mockImplementation((key: string) => _store.delete(key))
  localStorageMock.clear.mockImplementation(() => _store.clear())
  localStorageMock.key.mockImplementation((index: number) => Array.from(_store.keys())[index] ?? null)
})
