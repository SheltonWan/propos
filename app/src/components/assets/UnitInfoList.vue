<template>
  <view class="details">
    <view class="detail-row">
      <text class="detail-row__label">业态</text>
      <text class="detail-row__value">{{ propertyTypeLabel(unit.property_type) }}</text>
    </view>
    <view class="detail-row">
      <text class="detail-row__label">朝向</text>
      <text class="detail-row__value">{{ orientationLabel(unit.orientation) }}</text>
    </view>
    <view class="detail-row">
      <text class="detail-row__label">层高</text>
      <text class="detail-row__value">{{ unit.ceiling_height ? `${unit.ceiling_height} m` : '—' }}</text>
    </view>
    <view class="detail-row">
      <text class="detail-row__label">装修</text>
      <text class="detail-row__value">{{ decorationLabel(unit.decoration_status) }}</text>
    </view>
    <view class="detail-row">
      <text class="detail-row__label">是否可租</text>
      <text class="detail-row__value">{{ unit.is_leasable ? '是' : '否' }}</text>
    </view>
    <view v-if="workstationCount !== null" class="detail-row">
      <text class="detail-row__label">工位数</text>
      <text class="detail-row__value">{{ workstationCount }}</text>
    </view>
    <view v-if="unit.qr_code" class="detail-row">
      <text class="detail-row__label">二维码</text>
      <text class="detail-row__value">{{ unit.qr_code }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { DecorationStatus, Orientation, PropertyType, Unit } from '@/types/assets'
import { computed } from 'vue'

// 房源详细字段（业态 / 朝向 / 层高 / 装修 / 是否可租 / 工位数 / 二维码）
const props = defineProps<{
  unit: Unit
}>()

const PROPERTY_TYPE_LABELS: Record<PropertyType, string> = {
  office: '写字楼',
  retail: '商铺',
  apartment: '公寓',
  mixed: '综合体',
}

const ORIENTATION_LABELS: Record<Orientation, string> = {
  east: '东', south: '南', west: '西', north: '北',
}

const DECORATION_LABELS: Record<DecorationStatus, string> = {
  blank: '毛坯', simple: '简装', refined: '精装', raw: '清水',
}

function propertyTypeLabel(t: PropertyType): string {
  return PROPERTY_TYPE_LABELS[t]
}
function orientationLabel(o: Orientation | null): string {
  return o ? ORIENTATION_LABELS[o] : '—'
}
function decorationLabel(d: DecorationStatus | null): string {
  return d ? DECORATION_LABELS[d] : '—'
}

const workstationCount = computed<number | null>(() => {
  const v = props.unit.ext_fields?.workstation_count
  return typeof v === 'number' ? v : null
})
</script>

<style lang="scss" scoped>
.details {
  display: flex;
  flex-direction: column;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $space-gap-sm 0;
  border-bottom: 1px solid var(--color-border);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-row__label {
  @include text-caption;
}

.detail-row__value {
  font-size: 28rpx;
  color: var(--color-foreground);
}
</style>
