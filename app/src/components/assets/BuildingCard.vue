<template>
  <view
    class="building-card"
    hover-class="building-card--hover"
    :hover-stay-time="80"
    @tap="$emit('tap', building.id)"
  >
    <view class="building-card__top">
      <!-- 左侧业态色块 -->
      <view class="building-card__accent" :class="`building-card__accent--${building.property_type}`">
        <image class="building-card__icon" src="/static/icons/logo-building.svg" mode="aspectFit" />
        <text class="building-card__floors">{{ building.total_floors }}层</text>
      </view>

      <!-- 右侧信息 -->
      <view class="building-card__info">
        <view class="building-card__head">
          <text class="building-card__name">{{ building.name }}</text>
          <view class="building-card__tag" :class="`building-card__tag--${building.property_type}`">
            <text class="building-card__tag-text">{{ propertyTypeLabel(building.property_type) }}</text>
          </view>
        </view>
        <view class="building-card__address">
          <text class="building-card__address-text">{{ building.address }}</text>
        </view>
        <view class="building-card__chips">
          <view class="building-card__chip">
            <text class="building-card__chip-text">GFA {{ formatArea(building.gfa) }}</text>
          </view>
          <view class="building-card__chip">
            <text class="building-card__chip-text">{{ occupancy.total }}套房源</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 三列统计 + 进度条 -->
    <view class="building-card__footer">
      <view class="building-card__stat">
        <text class="building-card__stat-label">已租/总套</text>
        <view class="building-card__stat-row">
          <text class="building-card__stat-value">{{ occupancy.leased }}</text>
          <text class="building-card__stat-sub"> / {{ occupancy.total }}</text>
        </view>
      </view>
      <view class="building-card__sep" />
      <view class="building-card__stat">
        <text class="building-card__stat-label">空置 (套/面积)</text>
        <view class="building-card__stat-row">
          <text class="building-card__stat-value" :class="{ 'building-card__stat-value--warn': occupancy.vacant > 0 }">
            {{ occupancy.vacant }}
          </text>
          <text class="building-card__stat-sub"> / {{ formatVacantArea(building.gfa, occupancy.rate) }}</text>
        </view>
      </view>
      <view class="building-card__sep" />
      <view class="building-card__stat">
        <text class="building-card__stat-label">出租率</text>
        <text class="building-card__stat-rate" :class="rateLevelClass(occupancy.rate)">
          {{ formatRate(occupancy.rate) }}
        </text>
      </view>
    </view>

    <!-- 出租率进度条 -->
    <view class="building-card__bar-wrap">
      <view
        class="building-card__bar-fill"
        :class="rateLevelClass(occupancy.rate)"
        :style="{ width: `${Math.round(occupancy.rate * 100)}%` }"
      />
    </view>
  </view>
</template>

<script setup lang="ts">
import type { Building, BuildingOccupancy, PropertyType } from '@/types/assets'

// 楼栋卡片：业态色块 + 地址 + GFA / 房源数标签 + 三列统计 + 出租率进度条
defineProps<{
  building: Building
  occupancy: BuildingOccupancy
}>()

defineEmits<{
  (e: 'tap', buildingId: string): void
}>()

const PROPERTY_TYPE_LABELS: Record<PropertyType, string> = {
  office: '写字楼',
  retail: '商铺',
  apartment: '公寓',
  mixed: '综合体',
}

function propertyTypeLabel(t: PropertyType): string {
  return PROPERTY_TYPE_LABELS[t]
}

function formatRate(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`
}

function formatArea(value: number): string {
  if (value >= 10000) return `${(value / 10000).toFixed(1)}k㎡`
  return `${value.toLocaleString()}㎡`
}

/** 根据出租率估算空置面积（近似值，精确值需后端计算） */
function formatVacantArea(gfa: number, rate: number): string {
  const vacant = Math.round(gfa * (1 - rate))
  if (vacant >= 10000) return `${(vacant / 10000).toFixed(1)}万㎡`
  return `${vacant.toLocaleString()}㎡`
}

function rateLevelClass(rate: number): string {
  if (rate >= 0.9) return 'level-success'
  if (rate >= 0.75) return 'level-primary'
  return 'level-warning'
}
</script>

<style lang="scss" scoped>
.building-card {
  @include card-base;
  padding: $space-card;
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
  transition: transform 120ms ease;
}

.building-card--hover {
  transform: scale(0.99);
  background: var(--color-muted);
}

/* 顶部布局 */
.building-card__top {
  display: flex;
  gap: $space-gap-md;
}

/* 左侧业态色块 */
.building-card__accent {
  width: 152rpx;
  height: 152rpx;
  border-radius: $radius-control;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8rpx;
}

.building-card__accent--office {
  background: $color-primary-soft-md;
}

.building-card__accent--retail {
  background: $color-warning-soft;
}

.building-card__accent--apartment {
  background: $color-info-soft;
}

.building-card__accent--mixed {
  background: var(--color-muted);
}

.building-card__icon {
  width: 48rpx;
  height: 48rpx;
  opacity: 0.8;
}

.building-card__floors {
  font-size: 22rpx;
  font-weight: 700;
}

.building-card__accent--office .building-card__floors { color: var(--color-primary); }
.building-card__accent--retail .building-card__floors { color: var(--color-warning); }
.building-card__accent--apartment .building-card__floors { color: var(--color-info); }
.building-card__accent--mixed .building-card__floors { color: var(--color-muted-foreground); }

/* 右侧信息 */
.building-card__info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}

.building-card__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8rpx;
}

.building-card__name {
  @include title-md;
  flex: 1;
  min-width: 0;
}

.building-card__tag {
  flex-shrink: 0;
  padding: 6rpx 14rpx;
  border-radius: 10rpx;
  border: 1px solid transparent;
}

.building-card__tag-text {
  font-size: 20rpx;
  font-weight: 600;
}

.building-card__tag--office {
  background: $color-primary-soft-md;
  border-color: $color-primary-border-soft;
  .building-card__tag-text { color: var(--color-primary); }
}

.building-card__tag--retail {
  background: $color-warning-soft;
  border-color: $color-warning-border-soft;
  .building-card__tag-text { color: var(--color-warning); }
}

.building-card__tag--apartment {
  background: $color-info-soft;
  border-color: $color-info-border-soft;
  .building-card__tag-text { color: var(--color-info); }
}

.building-card__tag--mixed {
  background: var(--color-muted);
  border-color: var(--color-border);
  .building-card__tag-text { color: var(--color-muted-foreground); }
}

.building-card__address {
  display: flex;
  align-items: center;
  gap: 6rpx;
}

.building-card__address-text {
  @include text-caption;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.building-card__chips {
  display: flex;
  gap: 10rpx;
  flex-wrap: wrap;
}

.building-card__chip {
  padding: 4rpx 16rpx;
  border-radius: 8rpx;
  background: var(--color-muted);
  border: 1px solid var(--color-border);
}

.building-card__chip-text {
  font-size: 20rpx;
  color: var(--color-muted-foreground);
}

/* 三列统计 */
.building-card__footer {
  display: flex;
  align-items: center;
  border-top: 1px solid var(--color-border);
  padding-top: $space-gap-md;
}

.building-card__stat {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6rpx;
}

.building-card__stat-label {
  font-size: 20rpx;
  color: var(--color-muted-foreground);
}

.building-card__stat-row {
  display: flex;
  align-items: baseline;
  gap: 2rpx;
}

.building-card__stat-value {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-foreground);
}

.building-card__stat-value--warn {
  color: var(--color-warning);
}

.building-card__stat-sub {
  font-size: 20rpx;
  color: var(--color-muted-foreground);
}

.building-card__stat-rate {
  font-size: 26rpx;
  font-weight: 600;
}

.building-card__sep {
  width: 1px;
  height: 56rpx;
  background: var(--color-border);
}

/* 出租率进度条 */
.building-card__bar-wrap {
  height: 8rpx;
  background: var(--color-muted);
  border-radius: 999rpx;
  overflow: hidden;
}

.building-card__bar-fill {
  height: 100%;
  border-radius: 999rpx;
  transition: width 400ms ease;
}

/* 颜色分级 */
.level-success { color: var(--color-success); background: var(--color-success); }
.level-primary { color: var(--color-primary); background: var(--color-primary); }
.level-warning { color: var(--color-warning); background: var(--color-warning); }
</style>


.building-card__bar {
  flex: 1;
  height: 10rpx;
  border-radius: 5rpx;
  background: var(--color-border);
  overflow: hidden;
}

.building-card__bar-fill {
  height: 100%;
  border-radius: 5rpx;
  background: var(--color-primary);
}

.building-card__bar-fill--success {
  background: var(--color-success);
}

.building-card__bar-fill--warning {
  background: var(--color-warning);
}

.building-card__bar-fill--danger {
  background: var(--color-destructive);
}

.building-card__rate-text {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-foreground);
  min-width: 90rpx;
  text-align: right;
}

.building-card__footer {
  display: flex;
  gap: $space-gap-md;
}

.building-card__footer-item {
  @include text-caption;
}
</style>
