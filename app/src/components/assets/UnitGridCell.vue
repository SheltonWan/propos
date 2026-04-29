<template>
  <view
    class="unit-cell"
    :class="`unit-cell--${unit.current_status}`"
    hover-class="unit-cell--hover"
    :hover-stay-time="80"
    @tap="$emit('tap', unit.unit_id)"
  >
    <text class="unit-cell__number">{{ unit.unit_number }}</text>
    <text v-if="unit.tenant_name" class="unit-cell__tenant">{{ unit.tenant_name }}</text>
    <text v-else class="unit-cell__status">{{ statusLabel(unit.current_status) }}</text>
    <text v-if="unit.contract_end_date" class="unit-cell__end">{{ formatDate(unit.contract_end_date) }} 到期</text>
  </view>
</template>

<script setup lang="ts">
import type { FloorHeatmapUnit, UnitStatus } from '@/types/assets'

// 楼层热区单元格：根据 current_status 渲染对应语义色边框/底色
defineProps<{
  unit: FloorHeatmapUnit
}>()

defineEmits<{
  (e: 'tap', unitId: string): void
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

function formatDate(value: string): string {
  // ISO 字符串截取 YYYY-MM-DD（业务计算在后端，前端仅展示）
  return value.slice(0, 10)
}
</script>

<style lang="scss" scoped>
.unit-cell {
  position: relative;
  padding: $space-gap-md;
  border-radius: $radius-control;
  border: 2rpx solid var(--color-border);
  background: var(--color-background);
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  min-height: 160rpx;
  transition: transform 120ms ease;
}

.unit-cell--hover {
  transform: scale(0.98);
}

.unit-cell--leased {
  background: var(--color-primary-soft);
  border-color: var(--color-success);
}

.unit-cell--expiring_soon {
  background: var(--color-primary-soft);
  border-color: var(--color-warning);
}

.unit-cell--vacant {
  border-color: var(--color-destructive);
  background: var(--color-destructive-soft);
}

.unit-cell--non_leasable {
  background: var(--color-muted);
  border-color: var(--color-border);
}

.unit-cell--renovating,
.unit-cell--pre_lease {
  background: var(--color-primary-soft);
  border-color: var(--color-info);
}

.unit-cell__number {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.unit-cell__tenant {
  font-size: 24rpx;
  color: var(--color-foreground);
}

.unit-cell__status {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.unit-cell__end {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
}
</style>
