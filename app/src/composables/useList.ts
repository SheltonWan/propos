import { readonly, ref } from 'vue'

interface UseListOptions<T> {
  fetchFn: (page: number, pageSize: number) => Promise<{ items: T[], total: number }>
  pageSize?: number
  immediate?: boolean
}

export function useList<T>(options: UseListOptions<T>) {
  const { fetchFn, pageSize = 20, immediate = false } = options

  const items = ref<T[]>([]) as { value: T[] }
  const loading = ref(false)
  const refreshing = ref(false)
  const finished = ref(false)
  const error = ref<string | null>(null)
  const page = ref(1)
  const total = ref(0)

  async function loadMore() {
    if (loading.value || finished.value)
      return
    loading.value = true
    error.value = null

    try {
      const result = await fetchFn(page.value, pageSize)
      items.value.push(...result.items)
      total.value = result.total
      finished.value = items.value.length >= result.total
      page.value++
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : '加载失败'
    }
    finally {
      loading.value = false
    }
  }

  async function refresh() {
    refreshing.value = true
    page.value = 1
    items.value = []
    finished.value = false
    error.value = null

    await loadMore()
    refreshing.value = false
  }

  if (immediate) {
    loadMore()
  }

  return {
    items: readonly(items),
    loading: readonly(loading),
    refreshing: readonly(refreshing),
    finished: readonly(finished),
    error: readonly(error),
    total: readonly(total),
    loadMore,
    refresh,
  }
}
