<template>
  <view class="overview">
    <text class="overview__label">整体出租率</text>
    <text class="overview__rate">{{ formatRate(rate) }}</text>
    <view class="overview__bar">
      <view
        class="overview__bar-fill"
        :style="{ width: `${Math.round(rate * 100)}%` }"
      />
    </view>
    <view class="overview__metrics">
      <view class="overview__metric">
        <text class="overview__metric-value">{{ totalUnits }}</text>
        <text class="overview__metric-label">可租总数</text>
      </view>
      <view class="overview__metric">
        <text class="overview__metric-value">{{ totalLeased }}</text>
        <text class="overview__metric-label">已租</text>
      </view>
      <view class="overview__metric">
        <text class="overview__metric-value">{{ totalUnits - totalLeased }}</text>
        <text class="overview__metric-label">空置</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
// 资产首页顶部总览面板：整体出租率 + 总数 / 已租 / 空置 三项指标
defineProps<{
  rate: number
  totalUnits: number
  totalLeased: number
}>()

function formatRate(r: number): string {
  return `${(r * 100).toFixed(1)}%`
}
</script>

<style lang="scss" scoped>
.overview {
  padding: $space-gap-sm 0;
}

.overview__label {
  @include text-caption;
  display: block;
}

.overview__rate {
  display: block;
  font-size: 56rpx;
  font-weight: 700;
  color: var(--color-foreground);
  margin-top: 8rpx;
}

.overview__bar {
  width: 100%;
  height: 12rpx;
  border-radius: 6rpx;
  background: var(--color-border);
  overflow: hidden;
  margin-top: $space-gap-sm;
}

.overview__bar-fill {
  height: 100%;
  background: var(--color-primary);
  border-radius: 6rpx;
}

.overview__metrics {
  display: flex;
  margin-top: $space-gap-md;
  gap: $space-gap-md;
}

.overview__metric {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.overview__metric-value {
  font-size: 36rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.overview__metric-label {
  @include text-caption;
  margin-top: 4rpx;
}
</style>
