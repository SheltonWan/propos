<template>
  <view class="app-shell" :class="[`app-shell--${variant}`]" :style="shellStyle">
    <view class="app-shell__viewport-background" :style="viewportBackgroundStyle" />

    <view class="app-shell__viewport-content">
      <view
        v-if="safeTop"
        class="app-shell__safe-top"
        :style="safeTopStyle"
      />

      <slot name="header" />

      <scroll-view
        v-if="scroll"
        class="app-shell__body"
        scroll-y
        enhanced
        :show-scrollbar="false"
      >
        <view class="app-shell__content" :class="contentClass">
          <slot v-if="state === 'default'" />

          <view v-else-if="state === 'loading'" class="app-shell__state-wrap app-shell__state-wrap--loading">
            <slot name="loading">
              <view class="app-shell__loading-card" />
              <view class="app-shell__loading-card" />
            </slot>
          </view>

          <view v-else-if="state === 'empty'" class="app-shell__state-wrap app-shell__state-wrap--empty">
            <slot name="empty">
              <text class="app-shell__state-title">暂无内容</text>
              <text class="app-shell__state-desc">当前页面没有可展示的数据。</text>
            </slot>
          </view>

          <view v-else class="app-shell__state-wrap app-shell__state-wrap--error">
            <slot name="error">
              <text class="app-shell__state-title">加载失败</text>
              <text class="app-shell__state-desc">请稍后重试或检查网络状态。</text>
            </slot>
          </view>
        </view>
        <slot name="footer" />
        <view v-if="withTabbar" class="app-shell__tabbar-space" />
        <view
          v-if="safeBottom && !withTabbar"
          class="app-shell__safe-bottom"
          :style="safeBottomStyle"
        />
      </scroll-view>

      <view v-else class="app-shell__body app-shell__body--static">
        <view class="app-shell__content" :class="contentClass">
          <slot />
        </view>
        <slot name="footer" />
        <view v-if="withTabbar" class="app-shell__tabbar-space" />
        <view
          v-if="safeBottom && !withTabbar"
          class="app-shell__safe-bottom"
          :style="safeBottomStyle"
        />
      </view>
    </view>

    <AppTabBar v-if="withTabbar" />
    <view v-if="disabled" class="app-shell__disabled-mask" />
    <slot name="overlay" />
  </view>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useThemeStore } from '@/stores/theme'
import { useSafeArea } from '@/composables/useSafeArea'
import AppTabBar from '@/components/navigation/AppTabBar.vue'

const props = withDefaults(defineProps<{
  variant?: 'light' | 'dark'
  state?: 'default' | 'loading' | 'empty' | 'error'
  disabled?: boolean
  scroll?: boolean
  withTabbar?: boolean
  safeTop?: boolean
  safeBottom?: boolean
  contentInset?: 'default' | 'none'
  backgroundStyle?: string
}>(), {
  variant: 'light',
  state: 'default',
  disabled: false,
  scroll: true,
  withTabbar: false,
  safeTop: true,
  safeBottom: true,
  contentInset: 'default',
  backgroundStyle: '',
})

const { safeTop: safeTopRef, safeBottom: safeBottomRef } = useSafeArea()
const themeStore = useThemeStore()

const safeTopInset = computed(() => safeTopRef.value)
const safeBottomInset = computed(() => safeBottomRef.value)
const contentClass = computed(() => `app-shell__content--${props.contentInset}`)
const themeStyle = computed(() => themeStore.themeVars)
const shellStyle = computed(() => themeStyle.value)

/**
 * 解析页面背景色为直接色值（hex / gradient），不再返回 CSS 变量引用。
 * 原因：App-plus WebView 中内联 CSS 自定义属性继承不可靠。
 */
const resolvedBackground = computed(() => {
  if (props.backgroundStyle) return props.backgroundStyle
  const vars = themeStore.activeTheme.vars
  return props.variant === 'dark'
    ? (vars['--color-background-dark'] || '#1c1c1e')
    : (vars['--color-surface-light'] || '#f5f5f7')
})

/**
 * Safe area 条状区域专用实色背景。
 * 始终从主题 store 解析为不含 var() 引用的色值，
 * 避免 App-plus inline style 中 CSS 自定义属性不可靠的问题。
 */
const resolvedSafeAreaColor = computed(() => {
  const vars = themeStore.activeTheme.vars
  return props.variant === 'dark'
    ? (vars['--color-background-dark'] || '#1c1c1e')
    : (vars['--color-surface-light'] || vars['--color-background'] || '#f5f5f7')
})

const viewportBackgroundStyle = computed(() => ({
  background: resolvedBackground.value,
}))
const safeTopStyle = computed(() => ({
  height: `${safeTopInset.value}px`,
  background: resolvedSafeAreaColor.value,
}))
const safeBottomStyle = computed(() => ({
  height: `${safeBottomInset.value}px`,
  background: resolvedSafeAreaColor.value,
}))

// 每次页面显示时同步原生背景 + `:root` CSS 变量
onShow(() => {
  themeStore.applyRuntimeTheme()
})

// 主题切换时立即更新 DOM 与原生背景
watch(themeStyle, () => {
  themeStore.applyRuntimeTheme()
}, { deep: true, immediate: true })
</script>

<style lang="scss" scoped>
.app-shell {
  position: relative;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  isolation: isolate;

  &--light {
    background: transparent;
  }

  &--dark {
    background: transparent;
  }
}

.app-shell__viewport-background {
  position: fixed;
  inset: 0;
  z-index: 0;
}

.app-shell__viewport-content {
  position: relative;
  z-index: 1;
  min-height: 100vh;
  display: flex;
  flex: 1;
  flex-direction: column;
}

.app-shell__body {
  flex: 1;
}

.app-shell__body--static {
  display: flex;
  flex-direction: column;
}

.app-shell__body--static > .app-shell__content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.app-shell__content--default {
  @include page-x;
}

.app-shell__state-wrap {
  @include page-x;
  min-height: 48vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
  text-align: center;
}

.app-shell__state-title {
  @include title-md;
}

.app-shell__state-desc {
  @include text-caption;
}

.app-shell__loading-card {
  @include state-skeleton;
  width: 100%;
  height: 220rpx;
  border-radius: $radius-card;
}

.app-shell__tabbar-space {
  height: calc(116rpx + constant(safe-area-inset-bottom));
  height: calc(116rpx + env(safe-area-inset-bottom));
  flex-shrink: 0;
}

.app-shell__disabled-mask {
  position: fixed;
  inset: 0;
  background: $color-surface-overlay;
  z-index: 40;
  pointer-events: auto;
}
</style>
