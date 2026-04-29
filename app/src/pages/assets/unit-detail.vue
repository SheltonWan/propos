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
      <PageHeader title="房源详情" :back="true" :animated="false" :state="headerState" />
    </template>

    <view class="unit-detail">
      <!-- 加载 / 错误 / 空态 全页占位 -->
      <view v-if="cardState !== 'default'" class="unit-detail__state">
        <view v-if="cardState === 'loading'" class="unit-detail__loading">
          <wd-loading />
        </view>
        <template v-else-if="cardState === 'error'">
          <text class="unit-detail__placeholder">{{ store.error || '加载失败' }}</text>
          <view class="unit-detail__retry" @tap="reload">
            <text class="unit-detail__retry-text">点击重试</text>
          </view>
        </template>
        <text v-else class="unit-detail__placeholder">未找到房源</text>
      </view>

      <template v-if="unit">
        <!-- 状态 + 业态标签行 -->
        <view class="unit-detail__badges">
          <view class="status-badge" :class="`status-badge--${unit.current_status}`">
            <text class="status-badge__text">{{ statusLabel(unit.current_status) }}</text>
          </view>
          <view class="type-badge" :class="`type-badge--${unit.property_type}`">
            <text class="type-badge__text">{{ propertyTypeLabel(unit.property_type) }}</text>
          </view>
        </view>

        <!-- 基本信息卡片 -->
        <view class="info-card">
          <view class="info-card__header">
            <view class="info-card__bar info-card__bar--primary" />
            <text class="info-card__title">基本信息</text>
          </view>
          <view class="info-card__body">
            <InfoRow label="单元编号" :value="unit.unit_number" />
            <InfoRow label="所在楼层" :value="`${unit.building_name} · ${unit.floor_name}`" />
            <InfoRow label="建筑面积 (GFA)" :value="`${unit.gross_area} m²`" />
            <InfoRow label="净使用面积 (NIA)" :value="`${unit.net_area} m²`" highlight />
            <InfoRow label="朝向" :value="orientationLabel(unit.orientation)" />
            <InfoRow label="层高" :value="unit.ceiling_height ? `${unit.ceiling_height} m` : '—'" />
            <InfoRow label="装修状态" :value="decorationLabel(unit.decoration_status)" />
            <InfoRow
              v-if="unit.market_rent_reference != null"
              label="参考市场租金"
              :value="`¥${unit.market_rent_reference}/m²·月`"
              highlight
            />
          </view>
        </view>

        <!-- 写字楼扩展 -->
        <view v-if="unit.property_type === 'office' && workstationCount !== null" class="info-card">
          <view class="info-card__header">
            <view class="info-card__bar info-card__bar--info" />
            <text class="info-card__title">写字楼扩展</text>
          </view>
          <view class="info-card__body">
            <InfoRow label="工位数" :value="`${workstationCount} 个`" />
          </view>
        </view>

        <!-- 商铺扩展 -->
        <view v-if="unit.property_type === 'retail'" class="info-card">
          <view class="info-card__header">
            <view class="info-card__bar info-card__bar--warning" />
            <text class="info-card__title">商铺扩展</text>
          </view>
          <view class="info-card__body">
            <InfoRow v-if="shopfrontWidth != null" label="门面宽度" :value="`${shopfrontWidth} m`" />
            <InfoRow v-if="streetFacing" label="临街面" :value="streetFacing" />
            <InfoRow v-if="shopHeight != null" label="层高" :value="`${shopHeight} m`" />
          </view>
        </view>

        <!-- 公寓扩展 -->
        <view v-if="unit.property_type === 'apartment'" class="info-card">
          <view class="info-card__header">
            <view class="info-card__bar info-card__bar--info" />
            <text class="info-card__title">公寓扩展</text>
          </view>
          <view class="info-card__body">
            <InfoRow v-if="bedrooms != null" label="卧室数量" :value="`${bedrooms} 间`" />
            <InfoRow label="独立卫生间" :value="privateBathroom ? '有' : '无'" />
          </view>
        </view>

        <!-- 当前租赁 -->
        <view v-if="unit.current_contract_id" class="info-card">
          <view class="info-card__header">
            <view class="info-card__bar info-card__bar--success" />
            <text class="info-card__title">当前租赁</text>
          </view>
          <view class="info-card__body">
            <view class="info-row info-row--link" @tap="onContractTap">
              <text class="info-row__label">合同编号</text>
              <view class="info-row__link">
                <text class="info-row__link-text">{{ unit.current_contract_id }}</text>
                <text class="info-row__link-arrow">›</text>
              </view>
            </view>
          </view>
        </view>
      </template>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { DecorationStatus, Orientation, PropertyType, UnitStatus } from '@/types/assets'
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useUnitDetailStore } from '@/stores/assetsStore'
import InfoRow from '@/components/assets/InfoRow.vue'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useUnitDetailStore()
const unit = computed(() => store.item)

// ── 状态映射 ──────────────────────────────────────────────────────────────────
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

function statusLabel(s: UnitStatus): string { return STATUS_LABELS[s] }
function propertyTypeLabel(t: PropertyType): string { return PROPERTY_TYPE_LABELS[t] }
function orientationLabel(o: Orientation | null): string { return o ? ORIENTATION_LABELS[o] : '—' }
function decorationLabel(d: DecorationStatus | null): string { return d ? DECORATION_LABELS[d] : '—' }

// ── 业态扩展字段（来自 ext_fields） ──────────────────────────────────────────
const workstationCount = computed<number | null>(() => {
  const v = unit.value?.ext_fields?.workstation_count
  return typeof v === 'number' ? v : null
})
const shopfrontWidth = computed<number | null>(() => {
  const v = unit.value?.ext_fields?.shopfront_width
  return typeof v === 'number' ? v : null
})
const streetFacing = computed<string | null>(() => {
  const v = unit.value?.ext_fields?.street_facing
  return typeof v === 'string' ? v : null
})
const shopHeight = computed<number | null>(() => {
  const v = unit.value?.ext_fields?.shop_height
  return typeof v === 'number' ? v : null
})
const bedrooms = computed<number | null>(() => {
  const v = unit.value?.ext_fields?.bedrooms
  return typeof v === 'number' ? v : null
})
const privateBathroom = computed<boolean>(() => {
  return !!unit.value?.ext_fields?.private_bathroom
})

// ── 卡片状态 ───────────────────────────────────────────────────────────────────
const cardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading) return 'loading'
  if (store.error) return 'error'
  if (!unit.value) return 'empty'
  return 'default'
})

const headerState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && !unit.value) return 'loading'
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
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

/* 状态占位 */
.unit-detail__state {
  padding: 80rpx 0;
  text-align: center;
}

.unit-detail__loading {
  display: flex;
  justify-content: center;
  padding: 80rpx 0;
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

/* 状态 + 业态徽章行 */
.unit-detail__badges {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 8rpx 0 4rpx;
}

.status-badge {
  padding: 8rpx 20rpx;
  border-radius: 999rpx;
  border: 1px solid transparent;
}

.status-badge__text {
  font-size: 22rpx;
  font-weight: 700;
}

.status-badge--leased { background: $color-success-soft; border-color: $color-success-border-soft; .status-badge__text { color: var(--color-success); } }
.status-badge--expiring_soon { background: $color-warning-soft; border-color: $color-warning-border-soft; .status-badge__text { color: var(--color-warning); } }
.status-badge--vacant { background: $color-destructive-soft; border-color: $color-destructive-border-soft; .status-badge__text { color: var(--color-destructive); } }
.status-badge--non_leasable { background: var(--color-muted); border-color: var(--color-border); .status-badge__text { color: var(--color-muted-foreground); } }
.status-badge--renovating,
.status-badge--pre_lease { background: $color-info-soft; border-color: $color-info-border-soft; .status-badge__text { color: var(--color-info); } }

.type-badge {
  padding: 8rpx 20rpx;
  border-radius: 999rpx;
  border: 1px solid transparent;
}

.type-badge__text {
  font-size: 22rpx;
  font-weight: 600;
}

.type-badge--office { background: $color-primary-soft-md; border-color: $color-primary-border-soft; .type-badge__text { color: var(--color-primary); } }
.type-badge--retail { background: $color-warning-soft; border-color: $color-warning-border-soft; .type-badge__text { color: var(--color-warning); } }
.type-badge--apartment { background: $color-info-soft; border-color: $color-info-border-soft; .type-badge__text { color: var(--color-info); } }
.type-badge--mixed { background: var(--color-muted); border-color: var(--color-border); .type-badge__text { color: var(--color-muted-foreground); } }

/* 信息卡片通用结构 */
.info-card {
  @include card-base;
  overflow: hidden;
}

.info-card__header {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: $space-gap-md $space-card;
  border-bottom: 1px solid var(--color-border);
}

.info-card__bar {
  width: 6rpx;
  height: 32rpx;
  border-radius: 999rpx;
}

.info-card__bar--primary { background: var(--color-primary); }
.info-card__bar--info { background: var(--color-info); }
.info-card__bar--warning { background: var(--color-warning); }
.info-card__bar--success { background: var(--color-success); }

.info-card__title {
  font-size: 28rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.info-card__body {
  padding: 0 $space-card;
}

/* 链接行 */
.info-row--link {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $space-gap-md 0;
  border-bottom: 1px solid var(--color-border);
}

.info-row--link:last-child {
  border-bottom: none;
}

.info-row__label {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.info-row__link {
  display: flex;
  align-items: center;
  gap: 4rpx;
}

.info-row__link-text {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-primary);
}

.info-row__link-arrow {
  font-size: 28rpx;
  color: var(--color-primary);
}
</style>
