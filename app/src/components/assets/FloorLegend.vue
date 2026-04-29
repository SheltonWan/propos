<template>
  <view class="legend">
    <view v-for="legend in LEGENDS" :key="legend.status" class="legend__item">
      <view class="legend__dot" :class="`legend__dot--${legend.status}`" />
      <text class="legend__text">{{ legend.label }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { UnitStatus } from '@/types/assets'

// 楼层热区图状态图例
const LEGENDS: Array<{ status: UnitStatus, label: string }> = [
  { status: 'leased', label: '已租' },
  { status: 'expiring_soon', label: '即将到期' },
  { status: 'vacant', label: '空置' },
  { status: 'non_leasable', label: '非可租' },
]
</script>

<style lang="scss" scoped>
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: $space-gap-md;
}

.legend__item {
  display: flex;
  align-items: center;
  gap: 10rpx;
}

.legend__dot {
  width: 18rpx;
  height: 18rpx;
  border-radius: 50%;
  background: var(--color-muted);
}

.legend__dot--leased { background: var(--color-success); }
.legend__dot--expiring_soon { background: var(--color-warning); }
.legend__dot--vacant { background: var(--color-destructive); }
.legend__dot--non_leasable { background: var(--color-muted-foreground); }
.legend__dot--renovating { background: var(--color-info); }
.legend__dot--pre_lease { background: var(--color-info); }

.legend__text {
  @include text-caption;
}
</style>
