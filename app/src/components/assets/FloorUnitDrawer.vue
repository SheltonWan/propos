<template>
  <!-- 楼层单元详情底部抽屉 -->
  <view v-if="open && unit" class="drawer-root">
    <!-- 遮罩 -->
    <view class="drawer-mask" @tap="$emit('close')" />

    <!-- 底部面板 -->
    <view class="drawer-sheet">
      <!-- 拖拽把手 -->
      <view class="drawer-handle" />

      <!-- 头部：房间编号 + 状态标签 + 关闭按钮 -->
      <view class="drawer-header">
        <view class="drawer-header__info">
          <text class="drawer-header__number">{{ unit.unit_number }}</text>
          <view
            class="status-badge"
            :class="`status-badge--${unit.current_status}`"
          >
            <text class="status-badge__text">{{ STATUS_LABELS[unit.current_status] }}</text>
          </view>
        </view>
        <view class="drawer-close" @tap="$emit('close')">
          <text class="drawer-close__icon">✕</text>
        </view>
      </view>

      <!-- 正文 -->
      <scroll-view class="drawer-body" scroll-y :show-scrollbar="false">
        <!-- 租户区块（已租/即将到期） -->
        <view
          v-if="unit.current_status === 'leased' || unit.current_status === 'expiring_soon'"
          class="tenant-block"
          :class="unit.current_status === 'expiring_soon' ? 'tenant-block--warning' : ''"
        >
          <view class="tenant-block__row">
            <text class="tenant-block__label">租户名称</text>
            <text class="tenant-block__value">{{ unit.tenant_name ?? '—' }}</text>
          </view>
          <view class="tenant-block__row">
            <text class="tenant-block__label">合同到期</text>
            <view class="tenant-block__date-row">
              <text class="tenant-block__value">{{ formatDate(unit.contract_end_date) }}</text>
              <view v-if="unit.current_status === 'expiring_soon'" class="expiry-chip">
                <text class="expiry-chip__text">即将到期</text>
              </view>
            </view>
          </view>
        </view>

        <!-- 空置提示 -->
        <view v-else-if="unit.current_status === 'vacant'" class="vacant-block">
          <text class="vacant-block__title">当前空置</text>
          <text class="vacant-block__desc">该房源暂无租户，可对外出租</text>
        </view>

        <!-- 装修中提示 -->
        <view v-else-if="unit.current_status === 'renovating'" class="reno-block">
          <text class="reno-block__title">装修改造中</text>
          <text class="reno-block__desc">该房源正在进行内部改造工程</text>
        </view>

        <!-- 预租提示 -->
        <view v-else-if="unit.current_status === 'pre_lease'" class="prelease-block">
          <text class="prelease-block__title">招租中 / 预租洽谈</text>
          <text class="prelease-block__desc">正在进行租户洽谈，预计近期完成签约</text>
        </view>

        <!-- 面积信息行 -->
        <view v-if="unit.area_sqm != null" class="meta-row">
          <text class="meta-row__label">建筑面积</text>
          <text class="meta-row__value">{{ unit.area_sqm }} m²</text>
        </view>

        <!-- 操作按钮 -->
        <view class="action-row">
          <view
            class="action-btn action-btn--primary"
            hover-class="action-btn--hover"
            :hover-stay-time="80"
            @tap="$emit('navigate-to-unit', unit.unit_id)"
          >
            <text class="action-btn__text">查看房源详情</text>
          </view>
          <view
            v-if="unit.contract_id"
            class="action-btn action-btn--outline"
            hover-class="action-btn--hover"
            :hover-stay-time="80"
            @tap="$emit('navigate-to-contract', unit.contract_id!)"
          >
            <text class="action-btn__text action-btn__text--outline">查看合同</text>
          </view>
        </view>
      </scroll-view>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { FloorHeatmapUnit, UnitStatus } from '@/types/assets'

// 楼层房间详情底部抽屉：展示状态/租户信息 + 跳转房源详情
defineProps<{
  unit: FloorHeatmapUnit | null
  open: boolean
}>()

defineEmits<{
  (e: 'close'): void
  (e: 'navigate-to-unit', unitId: string): void
  (e: 'navigate-to-contract', contractId: string): void
}>()

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已出租',
  vacant: '空 置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租中',
}

/** 截取 ISO 日期字符串前 10 位展示 */
function formatDate(value: string | null): string {
  if (!value) return '—'
  return value.slice(0, 10)
}
</script>

<style lang="scss" scoped>
.drawer-root {
  position: fixed;
  inset: 0;
  z-index: 100;
}

.drawer-mask {
  position: absolute;
  inset: 0;
  background: var(--color-mask);
}

.drawer-sheet {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  max-height: 70vh;
  background: var(--color-background);
  border-radius: 32rpx 32rpx 0 0;
  box-shadow: 0 -4rpx 32rpx rgba(0, 0, 0, 0.12);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  padding-bottom: env(safe-area-inset-bottom);
}

.drawer-handle {
  width: 80rpx;
  height: 8rpx;
  border-radius: 999rpx;
  background: var(--color-border);
  margin: 24rpx auto 0;
  flex-shrink: 0;
}

.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24rpx 40rpx 20rpx;
  border-bottom: 1rpx solid var(--color-border);
  flex-shrink: 0;
}

.drawer-header__info {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.drawer-header__number {
  font-size: 34rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.status-badge {
  padding: 6rpx 18rpx;
  border-radius: 999rpx;
  border: 1rpx solid var(--color-border);
}

.status-badge--leased {
  background: var(--color-primary-soft);
  border-color: var(--color-primary);
  .status-badge__text { color: var(--color-primary); }
}
.status-badge--expiring_soon {
  background: rgba(255, 149, 0, 0.1);
  border-color: rgba(255, 149, 0, 0.3);
  .status-badge__text { color: var(--color-warning); }
}
.status-badge--vacant {
  background: rgba(255, 59, 48, 0.08);
  border-color: rgba(255, 59, 48, 0.2);
  .status-badge__text { color: var(--color-destructive); }
}
.status-badge--renovating, .status-badge--pre_lease {
  background: rgba(0, 122, 204, 0.08);
  border-color: rgba(0, 122, 204, 0.2);
  .status-badge__text { color: var(--color-info); }
}
.status-badge--non_leasable {
  background: var(--color-muted);
  .status-badge__text { color: var(--color-muted-foreground); }
}

.status-badge__text {
  font-size: 22rpx;
  font-weight: 600;
}

.drawer-close {
  width: 64rpx;
  height: 64rpx;
  border-radius: 20rpx;
  background: var(--color-muted);
  display: flex;
  align-items: center;
  justify-content: center;
}

.drawer-close__icon {
  font-size: 26rpx;
  color: var(--color-muted-foreground);
}

.drawer-body {
  flex: 1;
  padding: 32rpx 40rpx;
  display: flex;
  flex-direction: column;
  gap: 20rpx;
  min-height: 0;
}

// ─── 租户区块 ────────────────────────────────────────────────────────────────

.tenant-block {
  background: var(--color-primary-soft);
  border: 1rpx solid rgba(0, 0, 0, 0.06);
  border-radius: 20rpx;
  padding: 28rpx 32rpx;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.tenant-block--warning {
  background: rgba(255, 149, 0, 0.06);
  border-color: rgba(255, 149, 0, 0.2);
}

.tenant-block__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.tenant-block__label {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.tenant-block__value {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-foreground);
}

.tenant-block__date-row {
  display: flex;
  align-items: center;
  gap: 12rpx;
}

.expiry-chip {
  background: rgba(255, 59, 48, 0.1);
  border: 1rpx solid rgba(255, 59, 48, 0.25);
  border-radius: 999rpx;
  padding: 4rpx 12rpx;
}

.expiry-chip__text {
  font-size: 20rpx;
  color: var(--color-destructive);
  font-weight: 600;
}

// ─── 状态提示区块 ────────────────────────────────────────────────────────────

.vacant-block {
  background: rgba(255, 59, 48, 0.06);
  border: 1rpx solid rgba(255, 59, 48, 0.15);
  border-radius: 20rpx;
  padding: 24rpx 28rpx;
}

.vacant-block__title {
  display: block;
  font-size: 26rpx;
  font-weight: 700;
  color: var(--color-destructive);
  margin-bottom: 8rpx;
}

.vacant-block__desc {
  display: block;
  font-size: 23rpx;
  color: var(--color-muted-foreground);
}

.reno-block {
  background: rgba(0, 122, 204, 0.06);
  border: 1rpx solid rgba(0, 122, 204, 0.15);
  border-radius: 20rpx;
  padding: 24rpx 28rpx;
}

.reno-block__title {
  display: block;
  font-size: 26rpx;
  font-weight: 700;
  color: var(--color-info);
  margin-bottom: 8rpx;
}

.reno-block__desc {
  display: block;
  font-size: 23rpx;
  color: var(--color-muted-foreground);
}

.prelease-block {
  background: rgba(255, 149, 0, 0.06);
  border: 1rpx solid rgba(255, 149, 0, 0.15);
  border-radius: 20rpx;
  padding: 24rpx 28rpx;
}

.prelease-block__title {
  display: block;
  font-size: 26rpx;
  font-weight: 700;
  color: var(--color-warning);
  margin-bottom: 8rpx;
}

.prelease-block__desc {
  display: block;
  font-size: 23rpx;
  color: var(--color-muted-foreground);
}

// ─── 操作按钮 ────────────────────────────────────────────────────────────────

.action-row {
  display: flex;
  gap: 16rpx;
  padding-top: 8rpx;
}

.action-btn {
  flex: 1;
  height: 88rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.action-btn--primary {
  background: var(--color-primary);
}

.action-btn--outline {
  background: transparent;
  border: 2rpx solid var(--color-primary);
}

.action-btn--hover {
  opacity: 0.85;
}

.action-btn__text {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--color-primary-foreground);
}

.action-btn__text--outline {
  color: var(--color-primary);
}

// ─── 面积行 ────────────────────────────────────────────────────────────────────────────

.meta-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16rpx 0;
  border-bottom: 1rpx solid var(--color-border);
}

.meta-row__label {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.meta-row__value {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-foreground);
}
</style>
