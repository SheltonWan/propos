<template>
  <view class="login-theme-switcher">
    <view class="login-theme-switcher__trigger" @tap="openSheet">
      <view class="login-theme-switcher__swatches">
        <view
          v-for="(swatch, index) in activeTheme.swatches"
          :key="`${activeTheme.id}-${index}`"
          class="login-theme-switcher__swatch"
          :style="{ backgroundColor: swatch, zIndex: activeTheme.swatches.length - index }"
        />
      </view>

      <view class="login-theme-switcher__text">
        <text class="login-theme-switcher__label">
          切换主题
        </text>
        <text class="login-theme-switcher__value">
          {{ activeTheme.name }}
        </text>
      </view>

      <text class="login-theme-switcher__action">
        查看
      </text>
    </view>

    <BottomSheet
      v-model="sheetVisible"
      title="选择主题"
      :variant="sheetVariant"
      height="72vh"
    >
      <view class="login-theme-sheet">
        <text class="login-theme-sheet__intro">
          仅切换主题 token，不改变页面结构与交互。
        </text>

        <view
          v-for="theme in themeOptions"
          :key="theme.id"
          class="login-theme-sheet__option"
          :class="{ 'is-active': theme.id === themeId }"
          @tap="selectTheme(theme.id)"
        >
          <view class="login-theme-sheet__swatches">
            <view
              v-for="(swatch, index) in theme.swatches"
              :key="`${theme.id}-${index}`"
              class="login-theme-sheet__swatch"
              :style="{ backgroundColor: swatch }"
            />
          </view>

          <view class="login-theme-sheet__content">
            <text class="login-theme-sheet__name">
              {{ theme.name }}
            </text>
            <text class="login-theme-sheet__id">
              {{ theme.id }}
            </text>
          </view>

          <text v-if="theme.id === themeId" class="login-theme-sheet__badge">
            使用中
          </text>
        </view>
      </view>
    </BottomSheet>
  </view>
</template>

<script setup lang="ts">
import type { ThemeId } from '@/constants/theme'
import { storeToRefs } from 'pinia'
import { computed, ref } from 'vue'
import BottomSheet from '@/components/base/BottomSheet.vue'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const { activeTheme, themeId, themeOptions } = storeToRefs(themeStore)

const sheetVisible = ref(false)
const sheetVariant = computed(() => (themeId.value === 'dark' ? 'dark' : 'light'))

function openSheet() {
  sheetVisible.value = true
}

function selectTheme(nextThemeId: ThemeId) {
  themeStore.setTheme(nextThemeId)
  sheetVisible.value = false
}
</script>

<style lang="scss" scoped>
.login-theme-switcher {
  width: 100%;
  display: flex;
  justify-content: center;
  margin-top: 32rpx;
}

.login-theme-switcher__trigger {
  width: auto;
  max-width: 100%;
  min-width: 360rpx;
  display: inline-flex;
  align-items: center;
  gap: 24rpx;
  padding: 24rpx 28rpx;
  background: $color-background;
  border: 2rpx solid $color-border;
  border-radius: 999rpx;
  box-shadow: $shadow-card;
}

.login-theme-switcher__swatches {
  min-width: 92rpx;
  display: flex;
  align-items: center;
}

.login-theme-switcher__swatch {
  width: 30rpx;
  height: 30rpx;
  border-radius: 999rpx;
  border: 2rpx solid $color-background;

  & + & {
    margin-left: -10rpx;
  }
}

.login-theme-switcher__text {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.login-theme-switcher__label {
  font-size: 22rpx;
  color: $color-muted-foreground;
}

.login-theme-switcher__value {
  font-size: 28rpx;
  font-weight: 600;
  color: $color-foreground;
}

.login-theme-switcher__action {
  font-size: 24rpx;
  font-weight: 600;
  color: $color-primary;
}

.login-theme-sheet {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}

.login-theme-sheet__intro {
  font-size: 24rpx;
  color: $color-muted-foreground;
}

.login-theme-sheet__option {
  display: flex;
  align-items: center;
  gap: 24rpx;
  padding: 24rpx;
  background: $color-background;
  border: 2rpx solid $color-border;
  border-radius: 28rpx;

  &.is-active {
    border-color: $color-primary;
    box-shadow: 0 0 0 4rpx $color-primary-focus-ring;
  }
}

.login-theme-sheet__swatches {
  width: 84rpx;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8rpx;
  flex-shrink: 0;
}

.login-theme-sheet__swatch {
  width: 22rpx;
  height: 22rpx;
  border-radius: 999rpx;
  border: 2rpx solid $color-background;
}

.login-theme-sheet__content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 6rpx;
}

.login-theme-sheet__name {
  font-size: 28rpx;
  font-weight: 600;
  color: $color-foreground;
}

.login-theme-sheet__id {
  font-size: 22rpx;
  color: $color-muted-foreground;
  text-transform: uppercase;
}

.login-theme-sheet__badge {
  padding: 10rpx 18rpx;
  font-size: 22rpx;
  font-weight: 600;
  color: $color-primary;
  background: $color-primary-soft;
  border-radius: 999rpx;
}
</style>
