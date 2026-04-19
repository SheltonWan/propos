<template>
  <view v-if="visible" class="bottom-sheet">
    <view class="bottom-sheet__mask" @tap="handleMask" />

    <view class="bottom-sheet__panel" :class="[`bottom-sheet__panel--${variant}`]" :style="panelStyle">
      <view v-if="showHandle" class="bottom-sheet__handle" />

      <view v-if="title || $slots.title" class="bottom-sheet__header">
        <slot name="title">
          <text class="bottom-sheet__title">
            {{ title }}
          </text>
        </slot>
      </view>

      <scroll-view class="bottom-sheet__body" scroll-y enhanced :show-scrollbar="false">
        <slot v-if="state === 'default'" />

        <view v-else-if="state === 'loading'" class="bottom-sheet__state">
          <slot name="loading">
            <view class="bottom-sheet__skeleton" />
            <view class="bottom-sheet__skeleton" />
          </slot>
        </view>

        <view v-else-if="state === 'empty'" class="bottom-sheet__state bottom-sheet__state--empty">
          <slot name="empty">
            <text class="bottom-sheet__state-title">
              暂无内容
            </text>
            <text class="bottom-sheet__state-desc">
              当前抽屉没有可展示项。
            </text>
          </slot>
        </view>

        <view v-else class="bottom-sheet__state bottom-sheet__state--error">
          <slot name="error">
            <text class="bottom-sheet__state-title">
              加载失败
            </text>
            <text class="bottom-sheet__state-desc">
              请关闭后重试。
            </text>
          </slot>
        </view>
      </scroll-view>

      <view v-if="$slots.footer" class="bottom-sheet__footer">
        <slot name="footer" />
      </view>

      <view class="bottom-sheet__safe-bottom" :style="{ height: `${safeBottomInset}px` }" />
      <view v-if="disabled" class="bottom-sheet__disabled-mask" />
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useSafeArea } from '@/composables/useSafeArea'

const props = withDefaults(defineProps<{
  modelValue: boolean
  title?: string
  variant?: 'light' | 'dark'
  state?: 'default' | 'loading' | 'empty' | 'error'
  disabled?: boolean
  closeOnMask?: boolean
  showHandle?: boolean
  height?: string
}>(), {
  title: '',
  variant: 'light',
  state: 'default',
  disabled: false,
  closeOnMask: true,
  showHandle: true,
  height: 'auto',
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'close'): void
}>()

const { safeBottom } = useSafeArea()
const visible = computed(() => props.modelValue)
const safeBottomInset = computed(() => safeBottom.value)
const panelStyle = computed(() => ({ maxHeight: props.height }))

function closeSheet() {
  emit('update:modelValue', false)
  emit('close')
}

function handleMask() {
  if (props.closeOnMask)
    closeSheet()
}
</script>

<style lang="scss" scoped>
.bottom-sheet {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
}

.bottom-sheet__mask {
  position: absolute;
  inset: 0;
  background: $color-mask;
}

.bottom-sheet__panel {
  position: relative;
  width: 100%;
  background: $color-background;
  border-radius: $radius-sheet $radius-sheet 0 0;
  box-shadow: $shadow-float;
  overflow: hidden;
}

.bottom-sheet__panel--dark {
  background: $color-background-dark;
}

.bottom-sheet__handle {
  width: 72rpx;
  height: 8rpx;
  border-radius: 999rpx;
  background: $color-handle;
  margin: 20rpx auto 16rpx;
}

.bottom-sheet__header {
  padding: 0 40rpx 24rpx;
}

.bottom-sheet__title {
  @include title-md;
}

.bottom-sheet__footer {
  padding: 0 40rpx 24rpx;
}

.bottom-sheet__body {
  max-height: 60vh;
  padding: 0 40rpx 24rpx;
}

.bottom-sheet__state {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.bottom-sheet__state-title {
  @include title-md;
}

.bottom-sheet__state-desc {
  @include text-caption;
}

.bottom-sheet__skeleton {
  @include state-skeleton;
  border-radius: 20rpx;
  height: 96rpx;
}

.bottom-sheet__disabled-mask {
  position: absolute;
  inset: 0;
  background: $color-surface-overlay;
}
</style>
