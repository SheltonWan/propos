<template>
  <view
    class="app-card"
    :class="cardClass"
    :style="cardMotionStyle"
    :hover-class="clickable && state === 'default' && !disabled ? 'app-card--hover' : 'none'"
    :hover-start-time="30"
    :hover-stay-time="90"
    @tap="handleClick"
  >
    <template v-if="state === 'default'">
      <view v-if="$slots.header" class="app-card__header">
        <slot name="header" />
      </view>

      <view class="app-card__body">
        <slot />
      </view>

      <view v-if="$slots.footer" class="app-card__footer">
        <slot name="footer" />
      </view>
    </template>

    <view v-else-if="state === 'loading'" class="app-card__state app-card__state--loading">
      <slot name="loading">
        <view class="app-card__skeleton app-card__skeleton--title" />
        <view class="app-card__skeleton app-card__skeleton--line" />
        <view class="app-card__skeleton app-card__skeleton--line short" />
      </slot>
    </view>

    <view v-else-if="state === 'empty'" class="app-card__state app-card__state--empty">
      <slot name="empty">
        <text class="app-card__state-title">暂无数据</text>
        <text class="app-card__state-desc">当前卡片没有可展示内容。</text>
      </slot>
    </view>

    <view v-else class="app-card__state app-card__state--error">
      <slot name="error">
        <text class="app-card__state-title">加载失败</text>
        <text class="app-card__state-desc">请稍后重试。</text>
      </slot>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'
import {
  MOTION_DURATION_ENTER_MS,
  MOTION_DURATION_STAGGER_MS,
  MOTION_DURATION_STANDARD_MS,
  MOTION_EASING_STANDARD,
} from '@/constants/ui_constants'

const props = withDefaults(defineProps<{
  padding?: 'sm' | 'md' | 'lg'
  variant?: 'default' | 'muted' | 'dark'
  state?: 'default' | 'loading' | 'empty' | 'error'
  disabled?: boolean
  clickable?: boolean
  border?: boolean
  shadow?: boolean
  animated?: boolean
  motionIndex?: number
}>(), {
  padding: 'md',
  variant: 'default',
  state: 'default',
  disabled: false,
  clickable: false,
  border: true,
  shadow: true,
  animated: true,
  motionIndex: 0,
})

const emit = defineEmits<{ (e: 'click'): void }>()
const motionReady = ref(false)
const cardEnterDuration = `${MOTION_DURATION_ENTER_MS}ms`
const cardStandardDuration = `${MOTION_DURATION_STANDARD_MS}ms`
const cardMotionCurve = MOTION_EASING_STANDARD

const cardClass = computed(() => [
  `app-card--${props.variant}`,
  `app-card--pad-${props.padding}`,
  {
    'is-borderless': !props.border,
    'is-shadowless': !props.shadow,
    'is-clickable': props.clickable,
    'is-disabled': props.disabled,
    'is-animated': props.animated,
    'is-motion-ready': motionReady.value,
  },
])

const cardMotionStyle = computed(() => ({
  transitionDelay: `${props.motionIndex * MOTION_DURATION_STAGGER_MS}ms`,
}))

function handleClick() {
  if (props.clickable && props.state === 'default' && !props.disabled) emit('click')
}

onMounted(() => {
  if (!props.animated) {
    motionReady.value = true
    return
  }

  nextTick(() => {
    motionReady.value = true
  })
})
</script>

<style lang="scss" scoped>
.app-card {
  @include card-base;
  transition:
    opacity v-bind(cardStandardDuration) ease,
    transform v-bind(cardEnterDuration) v-bind(cardMotionCurve),
    box-shadow v-bind(cardStandardDuration) ease,
    border-color v-bind(cardStandardDuration) ease,
    background v-bind(cardStandardDuration) ease;

  &.is-animated {
    opacity: 0;
    transform: translateY(18rpx) scale(0.985);
  }

  &.is-animated.is-motion-ready {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.app-card--default {
  background: $color-background;
}

.app-card--muted {
  background: $color-surface-light;
}

.app-card--dark {
  background: $color-background-dark;
  border-color: $color-border-dark;
}

.app-card--pad-sm {
  padding: 24rpx;
}

.app-card--pad-md {
  padding: 32rpx;
}

.app-card--pad-lg {
  padding: 40rpx;
}

.app-card--hover {
  opacity: 1;
  transform: translateY(-6rpx) scale(0.994);
  box-shadow: $shadow-float;
}

.app-card__state {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.app-card__state-title {
  @include title-md;
}

.app-card__state-desc {
  @include text-caption;
}

.app-card__skeleton {
  @include state-skeleton;
  border-radius: 16rpx;
}

.app-card__skeleton--title {
  width: 50%;
  height: 40rpx;
}

.app-card__skeleton--line {
  width: 100%;
  height: 28rpx;

  &.short {
    width: 72%;
  }
}

.is-borderless {
  border: none;
}

.is-shadowless {
  box-shadow: none;
}

.is-disabled {
  @include state-disabled;
}
</style>
