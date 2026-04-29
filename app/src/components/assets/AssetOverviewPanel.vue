<template>
  <view class="overview">
    <!-- 装饰性楼栋图标 -->
    <image class="overview__deco" src="/static/icons/logo-building.svg" mode="aspectFit" />

    <view class="overview__main">
      <text class="overview__label">管理总面积 (㎡)</text>
      <text class="overview__gfa">{{ formatGfa(totalGfa) }}<text class="overview__gfa-unit">万</text></text>
    </view>

    <view class="overview__metrics">
      <view class="overview__metric">
        <text class="overview__metric-label">总房源</text>
        <view class="overview__metric-row">
          <text class="overview__metric-value">{{ totalUnits }}</text>
          <text class="overview__metric-unit">套</text>
        </view>
      </view>
      <view class="overview__divider" />
      <view class="overview__metric">
        <text class="overview__metric-label">空置房源</text>
        <view class="overview__metric-row">
          <text class="overview__metric-value overview__metric-value--warn">{{ totalVacant }}</text>
          <text class="overview__metric-unit">套</text>
        </view>
      </view>
      <view class="overview__divider" />
      <view class="overview__metric">
        <text class="overview__metric-label">楼栋数</text>
        <view class="overview__metric-row">
          <text class="overview__metric-value">{{ buildingCount }}</text>
          <text class="overview__metric-unit">栋</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
// 资产首页总览面板：深色卡片，管理总面积 + 总房源 / 空置 / 楼栋数
defineProps<{
  totalGfa: number
  totalUnits: number
  totalLeased: number
  totalVacant: number
  buildingCount: number
}>()

function formatGfa(gfa: number): string {
  return (gfa / 10000).toFixed(1)
}
</script>

<style lang="scss" scoped>
.overview {
  position: relative;
  padding: $space-card;
  overflow: hidden;
}

.overview__deco {
  position: absolute;
  top: 0;
  right: 0;
  width: 160rpx;
  height: 160rpx;
  opacity: 0.06;
}

.overview__main {
  position: relative;
  z-index: 1;
  margin-bottom: $space-gap-md;
}

.overview__label {
  display: block;
  font-size: 22rpx;
  font-weight: 500;
  color: $color-on-dark-text-muted;
  margin-bottom: 8rpx;
}

.overview__gfa {
  font-size: 60rpx;
  font-weight: 700;
  color: $color-on-dark-text;
  line-height: 1.1;
}

.overview__gfa-unit {
  font-size: 30rpx;
  font-weight: 400;
  color: $color-on-dark-text-muted;
  margin-left: 4rpx;
}

.overview__metrics {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border: 1px solid $color-on-dark-overlay-sm;
  border-radius: $radius-control;
  padding: $space-gap-sm $space-gap-md;
}

.overview__metric {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6rpx;
}

.overview__metric-label {
  font-size: 20rpx;
  color: $color-on-dark-text-muted;
}

.overview__metric-row {
  display: flex;
  align-items: baseline;
  gap: 4rpx;
}

.overview__metric-value {
  font-size: 28rpx;
  font-weight: 600;
  color: $color-on-dark-text;
}

.overview__metric-value--warn {
  color: var(--color-warning);
}

.overview__metric-unit {
  font-size: 20rpx;
  color: $color-on-dark-text-muted;
}

.overview__divider {
  width: 1px;
  height: 48rpx;
  background: $color-on-dark-overlay-sm;
}
</style>
