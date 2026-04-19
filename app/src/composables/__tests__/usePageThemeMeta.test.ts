import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'
import { useThemeStore } from '@/stores/theme'
import { usePageThemeMeta } from '../usePageThemeMeta'

// Mock platform module
vi.mock('@/platform/index', () => ({
  applyThemeToDom: vi.fn(),
  applyThemeToNative: vi.fn(),
}))

describe('usePageThemeMeta', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('returns backgroundColor from active theme', () => {
    const store = useThemeStore()
    store.initializeTheme()

    const { pageMetaBackgroundColor } = usePageThemeMeta()
    expect(pageMetaBackgroundColor.value).toBeTruthy()
    expect(pageMetaBackgroundColor.value).toMatch(/^#|^rgb/)
  })

  it('textStyle is dark for light themes', () => {
    const store = useThemeStore()
    store.initializeTheme()
    store.setTheme('apple')

    const { pageMetaTextStyle } = usePageThemeMeta()
    expect(pageMetaTextStyle.value).toBe('dark')
  })

  it('textStyle is light for dark theme', () => {
    const store = useThemeStore()
    store.initializeTheme()
    store.setTheme('dark')

    const { pageMetaTextStyle } = usePageThemeMeta()
    expect(pageMetaTextStyle.value).toBe('light')
  })

  it('pageStyle uses custom background when provided', () => {
    const store = useThemeStore()
    store.initializeTheme()

    const { pageMetaPageStyle } = usePageThemeMeta('linear-gradient(red, blue)')
    expect(pageMetaPageStyle.value).toContain('linear-gradient(red, blue)')
  })

  it('pageStyle falls back to theme color when no custom bg', () => {
    const store = useThemeStore()
    store.initializeTheme()

    const { pageMetaPageStyle } = usePageThemeMeta()
    expect(pageMetaPageStyle.value).toContain('background:')
  })
})
