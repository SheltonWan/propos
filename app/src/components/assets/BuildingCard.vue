<template>
  <view
    class="building-card"
    hover-class="building-card--hover"
    :hover-stay-time="80"
    @tap="$emit('tap', building.id)"
  >
    <view class="building-card__head">
      <text class="building-card__name">{{ building.name }}</text>
      <view class="building-card__tag" :class="`building-card__tag--${building.property_type}`">
        <text class="building-card__tag-text">{{ propertyTypeLabel(building.property_type) }}</text>
      </view>
    </view>

    <view class="building-card__meta">
      <text class="building-card__meta-item">{{ building.total_floors }} 层</text>
      <text class="building-card__meta-dot">·</text>
      <text class="building-card__meta-item">{{ formatArea(building.gfa) }}</text>
    </view>

    <view class="building-card__rate">
      <view class="building-card__bar">
        <view
          class="building-card__bar-fill"
          :class="rateLevelClass(occupancy.rate)"
          :style="{ width: `${Math.round(occupancy.rate * 100)}%` }"
        />
      </view>
      <text class="building-card__rate-text">{{ formatRate(occupancy.rate) }}</text>
    </view>

    <view class="building-card__footer">
      <text class="building-card__footer-item">已租 {{ occupancy.leased }}</text>
      <text class="building-card__footer-item">空置 {{ occupancy.vacant }}</text>
      <text class="building-card__footer-item">总数 {{ occupancy.total }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { Building, BuildingOccupancy, PropertyType } from '@/types/assets'

// 楼栋卡片：展示单栋楼的基本信息与出租率进度条
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
  if (value >= 10000) return `${(value / 10000).toFixed(1)} 万㎡`
  return `${value.toLocaleString()} ㎡`
}

function rateLevelClass(rate: number): string {
  if (rate >= 0.85) return 'building-card__bar-fill--success'
  if (rate >= 0.6) return 'building-card__bar-fill--warning'
  return 'building-card__bar-fill--danger'
}
</script>

<style lang="scss" scoped>
.building-card {
  @include card-base;
  padding: $space-card;
  display: flex;
  flex-direction: column;
  gap: $space-gap-sm;
  transition: transform 120ms ease;
}

.building-card--hover {
  transform: scale(0.99);
  background: var(--color-muted);
}

.building-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.building-card__name {
  @include title-md;
}

.building-card__tag {
  padding: 6rpx 16rpx;
  border-radius: 12rpx;
  background: var(--color-muted);
}

.building-card__tag-text {
  font-size: 22rpx;
  color: var(--color-foreground);
}

.building-card__tag--office {
  background: var(--color-tag-office, var(--color-muted));
}

.building-card__tag--retail {
  background: var(--color-tag-retail, var(--color-muted));
}

.building-card__tag--apartment {
  background: var(--color-tag-apartment, var(--color-muted));
}

.building-card__tag--mixed {
  background: var(--color-muted);
}

.building-card__meta {
  display: flex;
  align-items: center;
  gap: 12rpx;
}

.building-card__meta-item {
  @include text-caption;
}

.building-card__meta-dot {
  @include text-caption;
}

.building-card__rate {
  display: flex;
  align-items: center;
  gap: $space-gap-sm;
}

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
