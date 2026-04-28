<template>
  <scroll-view
    class="floor-tab-bar"
    scroll-x
    :show-scrollbar="false"
  >
    <view
      v-for="floor in floors"
      :key="floor.id"
      class="floor-tab"
      :class="{ 'floor-tab--active': floor.id === activeId }"
      @tap="$emit('select', floor.id)"
    >
      <text class="floor-tab__text">{{ floor.floor_name }}</text>
    </view>
  </scroll-view>
</template>

<script setup lang="ts">
import type { Floor } from '@/types/assets'

// 楼层切换标签栏：横向滚动列表，点击切换当前楼层
defineProps<{
  floors: Floor[]
  activeId: string | null
}>()

defineEmits<{
  (e: 'select', floorId: string): void
}>()
</script>

<style lang="scss" scoped>
.floor-tab-bar {
  white-space: nowrap;
}

.floor-tab {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 12rpx 28rpx;
  margin-right: 16rpx;
  border-radius: 999rpx;
  background: var(--color-muted);
}

.floor-tab--active {
  background: var(--color-primary);
}

.floor-tab__text {
  font-size: 26rpx;
  color: var(--color-foreground);
}

.floor-tab--active .floor-tab__text {
  color: var(--color-primary-foreground);
  font-weight: 600;
}
</style>
