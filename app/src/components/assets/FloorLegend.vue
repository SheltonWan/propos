<template>
  <!-- 楼层热区图状态图例：按 layer 模式显示不同图例条目 -->
  <view class="legend">
    <view v-for="item in currentLegends" :key="item.key" class="legend__item">
      <view class="legend__dot" :style="{ background: item.color }" />
      <text class="legend__text">{{ item.label }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { LayerMode } from '@/types/assets'

// 支持按图层（出租状态 / 到期预警）切换显示不同图例
const props = defineProps<{
  layer?: LayerMode
}>()

interface LegendItem {
  key: string
  label: string
  color: string
}

const STATUS_LEGENDS: LegendItem[] = [
  { key: 'leased', label: '已租', color: 'var(--color-success)' },
  { key: 'expiring_soon', label: '即将到期', color: 'var(--color-warning)' },
  { key: 'vacant', label: '空置', color: 'var(--color-destructive)' },
  { key: 'non_leasable', label: '非可租', color: 'var(--color-muted-foreground)' },
]

const EXPIRY_LEGENDS: LegendItem[] = [
  { key: 'stable', label: '>1年 稳健', color: 'var(--color-success)' },
  { key: 'warn', label: '90天~1年 预警', color: 'var(--color-warning)' },
  { key: 'urgent', label: '<90天 紧急', color: 'var(--color-destructive)' },
  { key: 'no_contract', label: '无合同', color: 'var(--color-muted-foreground)' },
]

const currentLegends = computed<LegendItem[]>(() =>
  props.layer === 'expiry' ? EXPIRY_LEGENDS : STATUS_LEGENDS,
)
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
}

.legend__text {
  @include text-caption;
}
</style>
