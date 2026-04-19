import type { ThemeId } from '@/constants/theme'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import {
  DEFAULT_THEME_ID,
  getThemePreset,
  isThemeId,
  THEME_PRESETS,
  THEME_STORAGE_KEY,

} from '@/constants/theme'
import { applyThemeToDom, applyThemeToNative } from '@/platform/index'

function readStoredThemeId(): ThemeId {
  const storedThemeId = uni.getStorageSync(THEME_STORAGE_KEY)

  if (typeof storedThemeId === 'string' && isThemeId(storedThemeId)) {
    return storedThemeId
  }

  return DEFAULT_THEME_ID
}

export const useThemeStore = defineStore('theme', () => {
  const themeId = ref<ThemeId>(DEFAULT_THEME_ID)
  const initialized = ref(false)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const activeTheme = computed(() => getThemePreset(themeId.value))
  const themeVars = computed(() => activeTheme.value.vars)
  const themeOptions = computed(() => THEME_PRESETS)

  function applyRuntimeTheme() {
    applyThemeToDom(themeVars.value)
    applyThemeToNative(themeVars.value, themeId.value === 'dark')
  }

  function initializeTheme() {
    if (initialized.value) {
      applyRuntimeTheme()
      return
    }

    loading.value = true
    error.value = null

    try {
      themeId.value = readStoredThemeId()
      applyRuntimeTheme()
      initialized.value = true
    }
    catch {
      themeId.value = DEFAULT_THEME_ID
      error.value = '主题初始化失败'
      applyRuntimeTheme()
      initialized.value = true
    }
    finally {
      loading.value = false
    }
  }

  function setTheme(nextThemeId: ThemeId) {
    themeId.value = nextThemeId
    uni.setStorageSync(THEME_STORAGE_KEY, nextThemeId)
    applyRuntimeTheme()
  }

  function setThemeById(nextThemeId: string) {
    if (!isThemeId(nextThemeId)) {
      error.value = '主题不存在'
      return false
    }

    error.value = null
    setTheme(nextThemeId)
    return true
  }

  return {
    themeId,
    initialized,
    loading,
    error,
    activeTheme,
    themeVars,
    themeOptions,
    initializeTheme,
    applyRuntimeTheme,
    setTheme,
    setThemeById,
  }
})
