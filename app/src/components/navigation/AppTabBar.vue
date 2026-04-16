<template>
  <view class="app-tabbar" :class="tabbarClassNames" :style="tabbarStyle">
    <view class="app-tabbar__panel" :style="tabbarPanelStyle">
      <view class="app-tabbar__active-pill" :style="activePillStyle" />

      <view
        v-for="item in tabItems"
        :key="item.id"
        class="app-tabbar__item"
        :class="{ 'is-active': item.active, 'is-pressed': pressedItemId === item.id }"
        @touchstart="handlePressStart(item.id)"
        @touchend="handlePressEnd"
        @touchcancel="handlePressEnd"
        @touchmove="handlePressEnd"
        @tap="switchTo(item.pagePath)"
      >
        <view class="app-tabbar__icon-surface">
          <image class="app-tabbar__icon" :src="item.iconSrc" mode="aspectFit" />
        </view>
        <text class="app-tabbar__label">{{ item.text }}</text>
        <view class="app-tabbar__indicator" />
      </view>
    </view>

    <view class="app-tabbar__safe-bottom" :style="tabbarSafeBottomStyle" />
  </view>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import {
  APP_TABBAR_ITEMS,
  getTabBarIconSrc,
  type AppTabBarItemId,
} from '@/constants/tabbar'

import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const { activeTheme } = storeToRefs(themeStore)

const currentPath = ref(APP_TABBAR_ITEMS[0].pagePath)
const pressedItemId = ref<AppTabBarItemId | null>(null)

function hideNativeTabBar() {
  if (typeof uni.hideTabBar !== 'function') {
    return
  }

  try {
    uni.hideTabBar({ animation: false })
  } catch {
    // 原生 tabBar 仅用于声明 tab 页路由，这里统一隐藏
  }
}

function normalizePagePath(route?: string) {
  if (!route) {
    return APP_TABBAR_ITEMS[0].pagePath
  }

  return route.startsWith('/') ? route : `/${route}`
}

function resolveCurrentPagePath() {
  const pages = getCurrentPages()
  const currentPage = pages[pages.length - 1]
  return normalizePagePath(currentPage?.route)
}

currentPath.value = resolveCurrentPagePath()
hideNativeTabBar()

function syncCurrentPath() {
  currentPath.value = resolveCurrentPagePath()
  hideNativeTabBar()
}

const tabItems = computed(() => {
  const vars = activeTheme.value.vars

  return APP_TABBAR_ITEMS.map((item) => {
    const active = item.pagePath === currentPath.value

    return {
      ...item,
      active,
      iconSrc: getTabBarIconSrc(item.id, {
        active,
        activeColor: vars['--color-primary'],
        inactiveColor: vars['--color-muted-foreground'],
        surfaceColor: vars['--color-surface-light'],
      }),
    }
  })
})

const activeIndex = computed(() => {
  const index = tabItems.value.findIndex((item) => item.active)
  return index >= 0 ? index : 0
})

const activePillStyle = computed(() => ({
  transform: `translateX(${activeIndex.value * 100}%)`,
}))

const tabbarStyle = computed(() => ({
  ...activeTheme.value.vars,
  background: activeTheme.value.vars['--color-surface-light'],
}))

const tabbarPanelStyle = computed(() => ({
  background: activeTheme.value.vars['--color-surface-light'],
  borderTopColor: activeTheme.value.vars['--color-border'],
}))

const tabbarSafeBottomStyle = computed(() => ({
  background: activeTheme.value.vars['--color-surface-light'],
}))

const tabbarClassNames = computed(() => ({
  'app-tabbar--dark': activeTheme.value.id === 'dark',
}))

function handlePressStart(itemId: AppTabBarItemId) {
  pressedItemId.value = itemId
}

function handlePressEnd() {
  pressedItemId.value = null
}

function switchTo(pagePath: string) {
  if (pagePath === currentPath.value) {
    handlePressEnd()
    return
  }

  handlePressEnd()
  hideNativeTabBar()
  uni.switchTab({ url: pagePath })
}

onMounted(syncCurrentPath)
onShow(syncCurrentPath)
</script>

<style lang="scss" scoped>
.app-tabbar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 30;
  background: $color-surface-light;
  box-shadow: 0 -10rpx 26rpx $color-muted-soft;

  &--dark {
    box-shadow: 0 -4rpx 14rpx $color-mask;
  }
}

.app-tabbar__panel {
  position: relative;
  min-height: 116rpx;
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  padding: 8rpx 14rpx 6rpx;
  background: $color-surface-light;
  border-top: 2rpx solid $color-border;
  overflow: hidden;
}

.app-tabbar__active-pill {
  position: absolute;
  top: 8rpx;
  bottom: 6rpx;
  left: 14rpx;
  width: calc((100% - 28rpx) / 5);
  border-radius: 24rpx;
  background: $color-muted-soft;
  opacity: 0.82;
  pointer-events: none;
}

.app-tabbar__item {
  position: relative;
  z-index: 1;
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4rpx;
  padding: 6rpx 4rpx 0;
}

.app-tabbar__icon-surface {
  width: 76rpx;
  height: 52rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 999rpx;
}

.app-tabbar__icon {
  width: 42rpx;
  height: 42rpx;
}

.app-tabbar__label {
  font-size: 20rpx;
  font-weight: 500;
  color: $color-muted-foreground;
  letter-spacing: 0.4rpx;
}

.app-tabbar__indicator {
  width: 16rpx;
  height: 6rpx;
  border-radius: 999rpx;
  background: transparent;
  transform: scaleX(0.6);
  opacity: 0;
}

.app-tabbar__item.is-pressed {
  transform: scale(0.96);

  .app-tabbar__icon-surface {
    transform: scale(0.94);
  }

  .app-tabbar__icon {
    transform: scale(0.94);
    opacity: 0.92;
  }

  .app-tabbar__label {
    transform: translateY(2rpx);
  }
}

.app-tabbar__item.is-active {
  .app-tabbar__icon-surface {
    background: $color-primary-soft;
    transform: translateY(-3rpx);
  }

  .app-tabbar__label {
    color: $color-primary;
    font-weight: 600;
    transform: translateY(-1rpx);
  }

  .app-tabbar__indicator {
    background: $color-primary;
    transform: scaleX(1);
    opacity: 1;
  }
}

.app-tabbar__safe-bottom {
  height: constant(safe-area-inset-bottom);
  height: env(safe-area-inset-bottom);
  background: $color-surface-light;
}
</style>
