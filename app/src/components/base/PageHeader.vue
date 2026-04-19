<template>
  <view class="page-header" :class="headerClass" :style="headerMotionStyle">
    <view class="page-header__main" :class="{ 'is-disabled': disabled }">
      <view
        v-if="back"
        class="page-header__back"
        hover-class="page-header__back--pressed"
        :hover-start-time="20"
        :hover-stay-time="80"
        @tap="handleBack"
      >
        <text class="page-header__back-icon">
          ‹
        </text>
      </view>

      <view class="page-header__center">
        <view v-if="state === 'loading'" class="page-header__title-skeleton" />
        <template v-else>
          <slot name="title">
            <text class="page-header__title">
              {{ title }}
            </text>
          </slot>
          <text v-if="subtitle" class="page-header__subtitle">
            {{ subtitle }}
          </text>
          <text v-else-if="state === 'empty'" class="page-header__subtitle">
            当前内容为空
          </text>
        </template>
      </view>

      <view class="page-header__actions">
        <slot v-if="state !== 'loading'" name="actions" />
      </view>
    </view>

    <view v-if="state === 'error'" class="page-header__status page-header__status--error">
      <slot name="status">
        <text class="page-header__status-text">
          当前内容加载失败，可下拉或点击重试。
        </text>
      </slot>
    </view>

    <view v-if="$slots.extra && state !== 'loading'" class="page-header__extra">
      <slot name="extra" />
    </view>

    <view v-else-if="state === 'loading'" class="page-header__extra-skeleton" />
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
  title: string
  subtitle?: string
  variant?: 'light' | 'dark'
  state?: 'default' | 'loading' | 'empty' | 'error'
  disabled?: boolean
  back?: boolean
  sticky?: boolean
  border?: boolean
  animated?: boolean
  motionIndex?: number
}>(), {
  subtitle: '',
  variant: 'light',
  state: 'default',
  disabled: false,
  back: false,
  sticky: true,
  border: true,
  animated: true,
  motionIndex: 0,
})

const emit = defineEmits<{ (e: 'back'): void }>()
const motionReady = ref(false)
const headerEnterDuration = `${MOTION_DURATION_ENTER_MS}ms`
const headerStandardDuration = `${MOTION_DURATION_STANDARD_MS}ms`
const headerMotionCurve = MOTION_EASING_STANDARD

const headerClass = computed(() => [
  `page-header--${props.variant}`,
  {
    'is-sticky': props.sticky,
    'has-border': props.border,
    'is-animated': props.animated,
    'is-motion-ready': motionReady.value,
  },
])

const headerMotionStyle = computed(() => ({
  transitionDelay: `${props.motionIndex * MOTION_DURATION_STAGGER_MS}ms`,
}))

function handleBack() {
  emit('back')
  const pages = getCurrentPages()
  if (pages.length > 1) {
    uni.navigateBack()
  }
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
.page-header {
  @include page-x;
  padding-top: 24rpx;
  padding-bottom: 24rpx;
  transition:
    opacity v-bind(headerStandardDuration) ease,
    transform v-bind(headerEnterDuration) v-bind(headerMotionCurve),
    background v-bind(headerStandardDuration) ease,
    border-color v-bind(headerStandardDuration) ease;

  &.is-animated {
    opacity: 0;
    transform: translateY(-12rpx);
  }

  &.is-animated.is-motion-ready {
    opacity: 1;
    transform: translateY(0);
  }

  &.is-sticky {
    position: sticky;
    top: 0;
    z-index: 20;
  }

  &.has-border {
    border-bottom: 1px solid $color-border;
  }

  &--light {
    background: $color-background;
  }

  &--dark {
    background: $color-background-dark;
  }
}

.page-header__main {
  display: flex;
  align-items: center;
  gap: 24rpx;

  &.is-disabled {
    @include state-disabled;
  }
}

.page-header__back {
  width: 64rpx;
  height: 64rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 999rpx;
  transition:
    transform v-bind(headerStandardDuration) v-bind(headerMotionCurve),
    background v-bind(headerStandardDuration) ease;
}

.page-header__back--pressed {
  background: $color-primary-soft;
  transform: scale(0.94);
}

.page-header__back-icon {
  font-size: 48rpx;
  color: $color-foreground;
  line-height: 1;
}

.page-header__center {
  flex: 1;
  min-width: 0;
}

.page-header__title {
  @include title-lg;
}

.page-header__subtitle {
  @include text-caption;
  display: block;
  margin-top: 8rpx;
}

.page-header__actions {
  flex-shrink: 0;
}

.page-header__title-skeleton,
.page-header__extra-skeleton {
  @include state-skeleton;
  border-radius: 20rpx;
}

.page-header__title-skeleton {
  width: 240rpx;
  height: 44rpx;
}

.page-header__extra-skeleton {
  margin-top: 24rpx;
  height: 80rpx;
}

.page-header__extra {
  margin-top: 24rpx;
}

.page-header__status {
  margin-top: 20rpx;
  padding: 16rpx 20rpx;
  border-radius: 24rpx;
}

.page-header__status--error {
  background: $color-destructive-soft;
}

.page-header__status-text {
  font-size: 24rpx;
  color: $color-destructive;
}
</style>
