<template>
  <view>
    <view class="unit-header">
      <text class="unit-header__number">{{ unit.unit_number }}</text>
      <view class="unit-header__status" :class="`unit-header__status--${unit.current_status}`">
        <text class="unit-header__status-text">{{ statusLabel(unit.current_status) }}</text>
      </view>
    </view>
    <text class="unit-header__sub">{{ unit.building_name }} · {{ unit.floor_name }}</text>
  </view>
</template>

<script setup lang="ts">
import type { Unit, UnitStatus } from '@/types/assets'

// 房源详情顶部：单元号 + 当前状态徽章
defineProps<{
  unit: Unit
}>()

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已租',
  vacant: '空置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租',
}

function statusLabel(s: UnitStatus): string {
  return STATUS_LABELS[s]
}
</script>

<style lang="scss" scoped>
.unit-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.unit-header__number {
  font-size: 44rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.unit-header__status {
  padding: 8rpx 20rpx;
  border-radius: 999rpx;
  background: var(--color-muted);
}

.unit-header__status-text {
  font-size: 22rpx;
  color: var(--color-foreground);
}

.unit-header__status--leased { background: var(--color-success); }
.unit-header__status--leased .unit-header__status-text { color: var(--color-primary-foreground); }

.unit-header__status--expiring_soon { background: var(--color-warning); }
.unit-header__status--expiring_soon .unit-header__status-text { color: var(--color-primary-foreground); }

.unit-header__status--vacant { background: var(--color-destructive); }
.unit-header__status--vacant .unit-header__status-text { color: var(--color-primary-foreground); }

.unit-header__status--non_leasable { background: var(--color-muted); }
.unit-header__status--renovating,
.unit-header__status--pre_lease { background: var(--color-info); }
.unit-header__status--renovating .unit-header__status-text,
.unit-header__status--pre_lease .unit-header__status-text { color: var(--color-primary-foreground); }

.unit-header__sub {
  @include text-caption;
}
</style>
