<template>
  <view class="info-row" :class="{ 'info-row--highlight': highlight }">
    <text class="info-row__label">{{ label }}</text>
    <text class="info-row__value" :class="{ 'info-row__value--highlight': highlight }">{{ value }}</text>
  </view>
</template>

<script setup lang="ts">
// 通用信息行：左侧 label + 右侧 value，highlight=true 时值文字加重色
defineProps<{
  label: string
  value: string
  highlight?: boolean
}>()
</script>

<style lang="scss" scoped>
.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $space-gap-md 0;
  border-bottom: 1px solid var(--color-border);
}

.info-row:last-child {
  border-bottom: none;
}

.info-row__label {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.info-row__value {
  font-size: 26rpx;
  color: var(--color-foreground);
}

.info-row__value--highlight {
  font-weight: 600;
  color: var(--color-primary);
}
</style>
