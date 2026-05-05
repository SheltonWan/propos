<template>
  <view :id="hostId" class="app-plus-heatmap-host">
    <view v-if="loading" class="app-plus-heatmap-host__loading">
      <view class="app-plus-heatmap-host__spinner" />
    </view>
    <view v-if="error" class="app-plus-heatmap-host__error">
      <text class="app-plus-heatmap-host__error-text">{{ error }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { fetchSvgWithCache } from '@/composables/useFloorSvgCache'
import { DEFAULT_THEME_ID, getThemePreset } from '@/constants/theme'
import { useThemeStore } from '@/stores/theme'
import type { FloorHeatmapUnit, LayerMode } from '@/types/assets'
import { buildFloorSvgWebviewHtml } from './buildFloorSvgWebviewHtml'

interface AppWebviewStyle {
  top: string
  left: string
  width: string
  height: string
  background?: string
  opacity?: number
  position?: 'absolute' | 'static' | 'dock'
  render?: 'always' | 'onscreen'
}

interface AppWebviewLike {
  addEventListener?: (eventName: string, handler: () => void) => void
  append?: (child: AppWebviewLike) => void
  close?: () => void
  evalJS?: (code: string) => void
  loadData?: (
    data: string,
    options?: {
      baseURL?: string
      mimeType?: string
      encoding?: string
    },
  ) => void
  overrideUrlLoading?: (
    options: Record<string, unknown>,
    handler: (event: { url?: string }) => void,
  ) => void
  setContentVisible?: (visible: boolean) => void
  setStyle?: (styles: Partial<AppWebviewStyle>) => void
  setRenderedEventOptions?: (options: { type?: 'auto' | 'top' | 'center' | 'bottom'; interval?: number }) => void
  setVisible?: (visible: boolean) => void
}

interface PlusBridgeLike {
  webview?: {
    create?: (
      url: string,
      id?: string,
      styles?: Partial<AppWebviewStyle>,
      extras?: Record<string, unknown>,
    ) => AppWebviewLike | undefined
  }
}

interface BoundingRectLike {
  left?: number
  top?: number
  width?: number
  height?: number
}

const props = defineProps<{
  units: FloorHeatmapUnit[]
  svgPath: string
  layer: LayerMode
  scale?: number
}>()

const hostId = `floor-webview-host-${Math.random().toString(36).slice(2, 8)}`
const childId = `floor-svg-webview-${Math.random().toString(36).slice(2, 8)}`
const loading = ref(true)
const error = ref('')

const defaultThemeVars = getThemePreset(DEFAULT_THEME_ID).vars
const themeStore = useThemeStore()
const mergedThemeVars = computed<Record<string, string>>(() => ({
  ...defaultThemeVars,
  ...themeStore.themeVars,
}))

let childWebview: AppWebviewLike | null = null
let disposed = false
let renderVersion = 0
let delayedLayoutTimer: ReturnType<typeof setTimeout> | null = null

function getPlusBridge(): PlusBridgeLike | null {
  // #ifdef APP-PLUS
  return (typeof plus !== 'undefined' ? plus : null) as unknown as PlusBridgeLike | null
  // #endif
  // #ifndef APP-PLUS
  return null
  // #endif
}

function getCurrentPageWebview(): AppWebviewLike | null {
  // 注意：在 uni-app 的 Vue 页面里，JS 跑在 service 层，
  // `plus.webview.currentWebview()` 返回的不是当前可见页面，必须走
  // `getCurrentPages()[last].$getAppWebview()` 拿宿主，否则 child webview 会被 append 到错误的页面而不显示。
  const pages = getCurrentPages()
  if (!pages.length) {
    return null
  }

  const currentPage = pages[pages.length - 1] as unknown as { $getAppWebview?: () => AppWebviewLike }
  return currentPage.$getAppWebview?.() ?? null
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function parseQuery(query: string): Record<string, string> {
  const result: Record<string, string> = {}
  const normalized = query.startsWith('?') ? query.slice(1) : query

  normalized.split('&').forEach((segment) => {
    if (!segment) return
    const [rawKey, rawValue = ''] = segment.split('=')
    if (!rawKey) return
    result[decodeURIComponent(rawKey)] = decodeURIComponent(rawValue)
  })

  return result
}

function handleBridgeUrl(url: string): void {
  if (!url.startsWith('propos://navigate/')) {
    return
  }

  const payload = url.slice('propos://navigate/'.length)
  const [path, query = ''] = payload.split('?')
  const params = parseQuery(query)
  const id = params.id
  if (!id) {
    return
  }

  if (path === 'unit') {
    uni.navigateTo({ url: `/pages/assets/unit-detail?id=${id}` })
    return
  }

  if (path === 'contract') {
    uni.navigateTo({ url: `/pages/contracts/detail?id=${id}` })
  }
}

function applyWebviewCommand(command: string): void {
  childWebview?.evalJS?.(command)
}

function applyLayer(): void {
  applyWebviewCommand(`window.PropSetLayer && window.PropSetLayer(${JSON.stringify(props.layer)});`)
}

function applyScale(): void {
  applyWebviewCommand(`window.PropSetZoom && window.PropSetZoom(${JSON.stringify(props.scale ?? 1)});`)
}

function applyTheme(): void {
  applyWebviewCommand(`window.PropApplyTheme && window.PropApplyTheme(${JSON.stringify(mergedThemeVars.value)});`)
}

function rectToStyle(rect: Required<BoundingRectLike>): AppWebviewStyle {
  return {
    top: `${Math.round(rect.top)}px`,
    left: `${Math.round(rect.left)}px`,
    width: `${Math.round(rect.width)}px`,
    height: `${Math.round(rect.height)}px`,
    background: mergedThemeVars.value['--color-background'] || mergedThemeVars.value['--color-surface-light'],
  }
}

function resolveHostRect(): Promise<Required<BoundingRectLike> | null> {
  return new Promise((resolve) => {
    uni.createSelectorQuery()
      .select(`#${hostId}`)
      .boundingClientRect((result) => {
        const rect = Array.isArray(result) ? result[0] : result
        if (!rect || typeof rect.left !== 'number' || typeof rect.top !== 'number' || typeof rect.width !== 'number' || typeof rect.height !== 'number') {
          resolve(null)
          return
        }

        if (rect.width <= 0 || rect.height <= 0) {
          resolve(null)
          return
        }

        resolve({
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
        })
      })
      .exec()
  })
}

async function resolveHostRectWithRetry(): Promise<Required<BoundingRectLike> | null> {
  await nextTick()
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const rect = await resolveHostRect()
    if (rect) {
      return rect
    }
    await delay(60)
  }
  return null
}

async function syncWebviewLayout(): Promise<void> {
  if (!childWebview) {
    return
  }
  const rect = await resolveHostRectWithRetry()
  if (!rect) {
    return
  }
  childWebview.setStyle?.(rectToStyle(rect))
}

function createChildWebview(rect: Required<BoundingRectLike>): AppWebviewLike | null {
  const plusBridge = getPlusBridge()
  const pageWebview = getCurrentPageWebview()
  if (!plusBridge?.webview?.create || !pageWebview?.append) {
    return null
  }

  const nextChild = plusBridge.webview.create(
    '',
    childId,
    rectToStyle(rect),
    {
      'uni-app': 'none',
    },
  ) ?? null

  if (!nextChild) {
    return null
  }

  nextChild.overrideUrlLoading?.(
    {
      mode: 'reject',
      match: '^propos://.*',
    },
    (event) => {
      if (event.url) {
        handleBridgeUrl(event.url)
      }
    },
  )

  nextChild.addEventListener?.('loaded', () => {
    if (disposed) {
      return
    }
    // HTML 已经把初始 layer/scale/主题内联进去，loaded 之后只用作后续 evalJS 同步信号。
    error.value = ''
    loading.value = false
    applyTheme()
    applyLayer()
    applyScale()
  })

  nextChild.addEventListener?.('error', () => {
    if (disposed) {
      return
    }
    loading.value = false
    error.value = '楼层图 WebView 内容加载失败'
  })

  pageWebview.append(nextChild)
  return nextChild
}

function destroyChildWebview(): void {
  if (delayedLayoutTimer) {
    clearTimeout(delayedLayoutTimer)
    delayedLayoutTimer = null
  }

  childWebview?.close?.()
  childWebview = null
}

async function renderFloorSvg(): Promise<void> {
  if (disposed) {
    return
  }

  const version = ++renderVersion
  loading.value = true
  error.value = ''

  const rect = await resolveHostRectWithRetry()
  if (!rect) {
    if (version === renderVersion) {
      loading.value = false
      error.value = '楼层图容器初始化失败'
    }
    return
  }

  if (!childWebview) {
    childWebview = createChildWebview(rect)
  } else {
    childWebview.setStyle?.(rectToStyle(rect))
  }

  if (!childWebview) {
    if (version === renderVersion) {
      loading.value = false
      error.value = '楼层图 WebView 创建失败'
    }
    return
  }

  try {
    const rawToken = uni.getStorageSync('access_token')
    const accessToken = typeof rawToken === 'string' ? rawToken : ''
    const svgText = await fetchSvgWithCache(props.svgPath, accessToken)
    if (disposed || version !== renderVersion) {
      return
    }

    const html = buildFloorSvgWebviewHtml({
      svgText,
      units: props.units,
      layer: props.layer,
      scale: props.scale ?? 1,
      themeVars: mergedThemeVars.value,
    })

    childWebview.loadData?.(html, {
      baseURL: 'https://propos.local/',
      mimeType: 'text/html',
      encoding: 'utf-8',
    })
    // HTML 是同步内联渲染的，loadData 触发后子 webview 会自行渲染 SVG，
    // 这里立即关闭页面级 loading，避免再叠一层 Vue 蒙层在 native webview 之上造成误导。
    loading.value = false
    if (delayedLayoutTimer) {
      clearTimeout(delayedLayoutTimer)
    }
    delayedLayoutTimer = setTimeout(() => {
      void syncWebviewLayout()
    }, 120)
  }
  catch (renderError) {
    if (disposed || version !== renderVersion) {
      return
    }
    loading.value = false
    error.value = renderError instanceof Error ? renderError.message : '楼层图加载失败'
  }
}

watch(
  () => [props.svgPath, props.units] as const,
  () => {
    if (!disposed) {
      void renderFloorSvg()
    }
  },
  { deep: true },
)

watch(
  () => props.layer,
  () => {
    applyLayer()
  },
)

watch(
  () => props.scale ?? 1,
  () => {
    applyScale()
  },
)

watch(
  () => themeStore.themeVars,
  () => {
    applyTheme()
  },
  { deep: true },
)

onMounted(() => {
  void renderFloorSvg()
})

onBeforeUnmount(() => {
  disposed = true
  destroyChildWebview()
})
</script>

<style lang="scss" scoped>
.app-plus-heatmap-host {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: var(--color-background);
}

.app-plus-heatmap-host__loading,
.app-plus-heatmap-host__error {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-background);
}

.app-plus-heatmap-host__loading {
  z-index: 1;
}

.app-plus-heatmap-host__error {
  z-index: 2;
  padding: 0 32rpx;
  text-align: center;
}

.app-plus-heatmap-host__spinner {
  width: 56rpx;
  height: 56rpx;
  border-radius: 999rpx;
  border: 6rpx solid var(--color-primary-soft);
  border-top-color: var(--color-primary);
  animation: heatmap-spin 0.8s linear infinite;
}

.app-plus-heatmap-host__error-text {
  font-size: 24rpx;
  line-height: 1.5;
  color: var(--color-muted-foreground);
}

@keyframes heatmap-spin {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}
</style>