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
      </view>
    </view>

    <view class="app-tabbar__safe-bottom" :style="tabbarSafeBottomStyle" />
  </view>
</template>

<script setup lang="ts">
import { onMounted, ref, shallowRef, watch } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import {
  APP_TABBAR_ITEMS,
  type AppTabBarItem,
  getTabBarIconSrc,
  type AppTabBarItemId,
} from '@/constants/tabbar'
import { consumeIntendedTabPath, setIntendedTabPath } from '@/utils/navigationIntent'

import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const { activeTheme } = storeToRefs(themeStore)

const currentPath = ref(APP_TABBAR_ITEMS[0].pagePath)
const pressedItemId = ref<AppTabBarItemId | null>(null)
const tabItems = shallowRef<Array<AppTabBarItem & { active: boolean; iconSrc: string }>>([])
const activePillStyle = shallowRef<Record<string, string>>({})
const tabbarStyle = shallowRef<Record<string, string>>({})
const tabbarPanelStyle = shallowRef<Record<string, string>>({})
const tabbarSafeBottomStyle = shallowRef<Record<string, string>>({})
const tabbarClassNames = shallowRef<Record<string, boolean>>({})

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

currentPath.value = consumeIntendedTabPath() ?? resolveCurrentPagePath()
hideNativeTabBar()

function syncCurrentPath() {
  currentPath.value = resolveCurrentPagePath()
  hideNativeTabBar()
}

function updateTabBarPresentation() {
  const vars = activeTheme.value.vars
  const nextTabItems = APP_TABBAR_ITEMS.map((item) => {
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

  const activeIndex = nextTabItems.findIndex((item) => item.active)
  const resolvedActiveIndex = activeIndex >= 0 ? activeIndex : 0

  tabItems.value = nextTabItems
  activePillStyle.value = {
    transform: `translateX(${resolvedActiveIndex * 100}%)`,
  }
  tabbarStyle.value = {
    ...vars,
    background: vars['--color-surface-light'],
  }
  tabbarPanelStyle.value = {
    background: vars['--color-surface-light'],
    borderTopColor: vars['--color-border'],
  }
  tabbarSafeBottomStyle.value = {
    background: vars['--color-surface-light'],
  }
  tabbarClassNames.value = {
    'app-tabbar--dark': activeTheme.value.id === 'dark',
  }
}

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
  setIntendedTabPath(pagePath)
  currentPath.value = pagePath // 乐观更新，避免首次切换闪烁
  uni.switchTab({ url: pagePath })
}

watch([currentPath, () => activeTheme.value.id], updateTabBarPresentation, { immediate: true })

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

}

.app-tabbar__safe-bottom {
  height: constant(safe-area-inset-bottom);
  height: env(safe-area-inset-bottom);
  background: $color-surface-light;
}
</style>
