<template>
  <view class="metrics">
    <view class="metric">
      <text class="metric__value">{{ unit.gross_area }}</text>
      <text class="metric__label">建面 ㎡</text>
    </view>
    <view class="metric">
      <text class="metric__value">{{ unit.net_area }}</text>
      <text class="metric__label">套内 ㎡</text>
    </view>
    <view class="metric">
      <text class="metric__value">{{ marketRentDisplay }}</text>
      <text class="metric__label">参考租金 元/㎡/月</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { Unit } from '@/types/assets'
import { computed } from 'vue'

// 房源关键指标三联展示：建面 / 套内 / 参考租金
const props = defineProps<{
  unit: Unit
}>()

const marketRentDisplay = computed(() =>
  props.unit.market_rent_reference != null ? props.unit.market_rent_reference.toString() : '—',
)
</script>

<style lang="scss" scoped>
.metrics {
  display: flex;
  background: var(--color-muted);
  border-radius: $radius-control;
  padding: $space-gap-md;
  gap: $space-gap-md;
}

.metric {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4rpx;
}

.metric__value {
  font-size: 36rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.metric__label {
  @include text-caption;
}
</style>
