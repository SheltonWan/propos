<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell>
    <template #header>
      <PageHeader title="房源详情" :back="true" :animated="false" />
    </template>

    <view class="unit-detail">
      <AppCard :state="cardState" :animated="false" class="unit-detail__card">
        <template #empty>
          <text class="unit-detail__placeholder">未找到房源</text>
        </template>
        <template #error>
          <text class="unit-detail__placeholder">{{ store.error || '加载失败' }}</text>
          <view class="unit-detail__retry" @tap="reload">
            <text class="unit-detail__retry-text">点击重试</text>
          </view>
        </template>

        <view v-if="unit" class="unit-detail__body">
          <!-- 标题区 -->
          <view class="unit-header">
            <text class="unit-header__number">{{ unit.unit_number }}</text>
            <view class="unit-header__status" :class="`unit-header__status--${unit.current_status}`">
              <text class="unit-header__status-text">{{ statusLabel(unit.current_status) }}</text>
            </view>
          </view>
          <text class="unit-header__sub">{{ unit.building_name }} · {{ unit.floor_name }}</text>

          <!-- 关键指标 -->
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

          <!-- 详情字段 -->
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

          <!-- 当前合同 -->
          <view v-if="unit.current_contract_id" class="contract-link" @tap="onContractTap">
            <text class="contract-link__label">关联合同</text>
            <text class="contract-link__action">查看 ›</text>
          </view>
        </view>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { DecorationStatus, Orientation, PropertyType, UnitStatus } from '@/types/assets'
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useUnitDetailStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useUnitDetailStore()
const unit = computed(() => store.item)

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已租',
  vacant: '空置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租',
}

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

function statusLabel(s: UnitStatus): string {
  return STATUS_LABELS[s]
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

const marketRentDisplay = computed(() =>
  unit.value?.market_rent_reference != null ? unit.value.market_rent_reference.toString() : '—',
)

const workstationCount = computed<number | null>(() => {
  const v = unit.value?.ext_fields?.workstation_count
  return typeof v === 'number' ? v : null
})

const cardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading) return 'loading'
  if (store.error) return 'error'
  if (!unit.value) return 'empty'
  return 'default'
})

function onContractTap() {
  if (!unit.value?.current_contract_id) return
  uni.navigateTo({ url: `/pages/contracts/detail?id=${unit.value.current_contract_id}` })
}

async function reload() {
  if (unit.value?.id) {
    await store.fetchDetail(unit.value.id)
  }
}

onLoad((options) => {
  const opts = (options ?? {}) as { id?: string }
  if (opts.id) store.fetchDetail(opts.id)
})
</script>

<style lang="scss" scoped>
.unit-detail {
  padding: $space-page-y $space-page-x;
}

.unit-detail__placeholder {
  @include text-caption;
  display: block;
  text-align: center;
  margin: 60rpx 0;
}

.unit-detail__retry {
  text-align: center;
  margin-top: $space-gap-sm;
}

.unit-detail__retry-text {
  @include text-caption;
  color: var(--color-primary);
}

.unit-detail__body {
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

// ─── 头部 ──────────────────────────────────────────────────────────────────

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

// ─── 指标 ──────────────────────────────────────────────────────────────────

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

// ─── 详情列表 ──────────────────────────────────────────────────────────────

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

// ─── 合同入口 ──────────────────────────────────────────────────────────────

.contract-link {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $space-gap-md;
  border-radius: $radius-control;
  background: var(--color-primary-soft);
}

.contract-link__label {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--color-foreground);
}

.contract-link__action {
  font-size: 26rpx;
  color: var(--color-primary);
}
</style>
