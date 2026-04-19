import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'
import { useThemeStore } from '../theme'

// Mock platform module
vi.mock('@/platform/index', () => ({
  applyThemeToDom: vi.fn(),
  applyThemeToNative: vi.fn(),
}))

describe('theme store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('initializes with default theme', () => {
    const store = useThemeStore()
    store.initializeTheme()
    expect(store.themeId).toBe('apple')
    expect(store.initialized).toBe(true)
  })

  it('setTheme updates themeId and persists', () => {
    const store = useThemeStore()
    store.initializeTheme()
    store.setTheme('dark')
    expect(store.themeId).toBe('dark')
    expect(uni.setStorageSync).toHaveBeenCalledWith('propos_theme_id', 'dark')
  })

  it('setThemeById validates theme id', () => {
    const store = useThemeStore()
    store.initializeTheme()

    expect(store.setThemeById('emerald')).toBe(true)
    expect(store.themeId).toBe('emerald')

    expect(store.setThemeById('nonexistent')).toBe(false)
    expect(store.error).toBe('主题不存在')
  })

  it('activeTheme returns correct preset', () => {
    const store = useThemeStore()
    store.initializeTheme()
    store.setTheme('violet')
    expect(store.activeTheme.id).toBe('violet')
    expect(store.activeTheme.name).toBe('优雅紫')
  })

  it('restores theme from storage', () => {
    uni.getStorageSync = vi.fn((key: string): any => {
      if (key === 'propos_theme_id')
        return 'rose'
      return ''
    })
    const store = useThemeStore()
    store.initializeTheme()
    expect(store.themeId).toBe('rose')
  })

  it('themeOptions lists all presets', () => {
    const store = useThemeStore()
    expect(store.themeOptions.length).toBeGreaterThanOrEqual(6)
  })
})
