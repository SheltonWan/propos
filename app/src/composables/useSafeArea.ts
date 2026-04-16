import { computed } from 'vue'

export function useSafeArea() {
  const systemInfo = uni.getSystemInfoSync()
  const safeAreaInsets = systemInfo.safeAreaInsets || { top: 0, bottom: 0, left: 0, right: 0 }

  const safeTop = computed(() => safeAreaInsets.top || 0)
  const safeBottom = computed(() => safeAreaInsets.bottom || 0)

  return {
    safeTop,
    safeBottom,
  }
}
