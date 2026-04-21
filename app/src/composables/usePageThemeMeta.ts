import type { ComputedRef, Ref } from 'vue'
import { storeToRefs } from 'pinia'
import { computed, unref } from 'vue'
import { useThemeStore } from '@/stores/theme'

type PageBackgroundStyleSource = string | Ref<string | undefined> | ComputedRef<string | undefined> | undefined

export function usePageThemeMeta(
  backgroundStyle?: PageBackgroundStyleSource,
  /** 可选：覆盖状态栏顶部颜色（用于深色 Header 页面，如 Dashboard） */
  topBackgroundColor?: PageBackgroundStyleSource,
) {
  const themeStore = useThemeStore()
  const { activeTheme } = storeToRefs(themeStore)

  const pageMetaBackgroundColor = computed(() => (
    activeTheme.value.vars['--color-surface-light']
    ?? activeTheme.value.vars['--color-background']
    ?? '#ffffff'
  ))

  const pageMetaTopBackgroundColor = computed(() => {
    const override = unref(topBackgroundColor)?.trim()
    return (override && override.length > 0)
      ? override
      : pageMetaBackgroundColor.value
  })

  const pageMetaTextStyle = computed<'dark' | 'light'>(() => (
    activeTheme.value.id === 'dark' ? 'light' : 'dark'
  ))

  const pageMetaPageStyle = computed(() => {
    const resolvedBackgroundStyle = unref(backgroundStyle)?.trim()
    const background = resolvedBackgroundStyle && resolvedBackgroundStyle.length > 0
      ? resolvedBackgroundStyle
      : pageMetaBackgroundColor.value
    const foreground = activeTheme.value.vars['--color-foreground'] ?? '#1d1d1f'

    return [
      `background: ${background}`,
      'background-repeat: no-repeat',
      'background-size: cover',
      `color: ${foreground}`,
    ].join('; ')
  })

  return {
    pageMetaBackgroundColor,
    pageMetaTopBackgroundColor,
    pageMetaRootBackgroundColor: pageMetaBackgroundColor,
    pageMetaTextStyle,
    pageMetaPageStyle,
  }
}
