<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell with-tabbar>
    <template #header>
      <PageHeader title="资产" :sticky="true" :back="false" :animated="false" />
    </template>

    <view class="assets">
      <!-- 总览卡片 -->
      <AppCard
        class="assets__overview"
        :state="overviewCardState"
        :animated="false"
      >
        <template #empty>
          <text class="assets__placeholder">暂无楼栋数据</text>
        </template>
        <template #error>
          <text class="assets__error">{{ store.error || '加载失败' }}</text>
          <view class="assets__retry" @tap="loadAll">
            <text class="assets__retry-text">点击重试</text>
          </view>
        </template>

        <view class="overview">
          <text class="overview__label">整体出租率</text>
          <text class="overview__rate">{{ formatRate(store.overallRate) }}</text>
          <view class="overview__bar">
            <view
              class="overview__bar-fill"
              :style="{ width: `${Math.round(store.overallRate * 100)}%` }"
            />
          </view>
          <view class="overview__metrics">
            <view class="overview__metric">
              <text class="overview__metric-value">{{ store.totalUnits }}</text>
              <text class="overview__metric-label">可租总数</text>
            </view>
            <view class="overview__metric">
              <text class="overview__metric-value">{{ store.totalLeased }}</text>
              <text class="overview__metric-label">已租</text>
            </view>
            <view class="overview__metric">
              <text class="overview__metric-value">{{ store.totalUnits - store.totalLeased }}</text>
              <text class="overview__metric-label">空置</text>
            </view>
          </view>
        </view>
      </AppCard>

      <!-- 楼栋列表 -->
      <view v-if="overviewCardState === 'default'" class="assets__list">
        <view
          v-for="building in store.list"
          :key="building.id"
          class="building-card"
          hover-class="building-card--hover"
          :hover-stay-time="80"
          @tap="onBuildingTap(building.id)"
        >
          <view class="building-card__head">
            <text class="building-card__name">{{ building.name }}</text>
            <view class="building-card__tag" :class="`building-card__tag--${building.property_type}`">
              <text class="building-card__tag-text">{{ propertyTypeLabel(building.property_type) }}</text>
            </view>
          </view>

          <view class="building-card__meta">
            <text class="building-card__meta-item">{{ building.total_floors }} 层</text>
            <text class="building-card__meta-dot">·</text>
            <text class="building-card__meta-item">{{ formatArea(building.gfa) }}</text>
          </view>

          <view class="building-card__rate">
            <view class="building-card__bar">
              <view
                class="building-card__bar-fill"
                :class="rateLevelClass(occupancyOf(building.id).rate)"
                :style="{ width: `${Math.round(occupancyOf(building.id).rate * 100)}%` }"
              />
            </view>
            <text class="building-card__rate-text">{{ formatRate(occupancyOf(building.id).rate) }}</text>
          </view>

          <view class="building-card__footer">
            <text class="building-card__footer-item">已租 {{ occupancyOf(building.id).leased }}</text>
            <text class="building-card__footer-item">空置 {{ occupancyOf(building.id).vacant }}</text>
            <text class="building-card__footer-item">总数 {{ occupancyOf(building.id).total }}</text>
          </view>
        </view>
      </view>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { BuildingOccupancy, PropertyType } from '@/types/assets'
import { computed, onMounted } from 'vue'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAssetOverviewStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useAssetOverviewStore()

const overviewCardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && store.list.length === 0) return 'loading'
  if (store.error) return 'error'
  if (store.list.length === 0) return 'empty'
  return 'default'
})

const PROPERTY_TYPE_LABELS: Record<PropertyType, string> = {
  office: '写字楼',
  retail: '商铺',
  apartment: '公寓',
  mixed: '综合体',
}

function propertyTypeLabel(t: PropertyType): string {
  return PROPERTY_TYPE_LABELS[t]
}

function formatRate(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`
}

function formatArea(value: number): string {
  if (value >= 10000) return `${(value / 10000).toFixed(1)} 万㎡`
  return `${value.toLocaleString()} ㎡`
}

const EMPTY_OCCUPANCY: BuildingOccupancy = { total: 0, leased: 0, vacant: 0, rate: 0 }

function occupancyOf(buildingId: string): BuildingOccupancy {
  return store.buildingOccupancy[buildingId] ?? EMPTY_OCCUPANCY
}

function rateLevelClass(rate: number): string {
  if (rate >= 0.85) return 'building-card__bar-fill--success'
  if (rate >= 0.6) return 'building-card__bar-fill--warning'
  return 'building-card__bar-fill--danger'
}

function onBuildingTap(buildingId: string) {
  uni.navigateTo({ url: `/pages/assets/floor-plan?building_id=${buildingId}` })
}

async function loadAll() {
  await store.fetchAll()
}

onMounted(() => {
  loadAll()
})
</script>

<style lang="scss" scoped>
.assets {
  padding: $space-page-y $space-page-x;
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

.assets__placeholder,
.assets__error {
  @include text-caption;
  display: block;
  text-align: center;
  margin: 60rpx 0;
}

.assets__retry {
  text-align: center;
  margin-top: $space-gap-sm;
}

.assets__retry-text {
  @include text-caption;
  color: var(--color-primary);
}

.assets__list {
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

// ─── 顶部总览 ──────────────────────────────────────────────────────────────

.overview {
  padding: $space-gap-sm 0;
}

.overview__label {
  @include text-caption;
  display: block;
}

.overview__rate {
  display: block;
  font-size: 56rpx;
  font-weight: 700;
  color: var(--color-foreground);
  margin-top: 8rpx;
}

.overview__bar {
  width: 100%;
  height: 12rpx;
  border-radius: 6rpx;
  background: var(--color-border);
  overflow: hidden;
  margin-top: $space-gap-sm;
}

.overview__bar-fill {
  height: 100%;
  background: var(--color-primary);
  border-radius: 6rpx;
}

.overview__metrics {
  display: flex;
  margin-top: $space-gap-md;
  gap: $space-gap-md;
}

.overview__metric {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.overview__metric-value {
  font-size: 36rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.overview__metric-label {
  @include text-caption;
  margin-top: 4rpx;
}

// ─── 楼栋卡片 ──────────────────────────────────────────────────────────────

.building-card {
  @include card-base;
  padding: $space-card;
  display: flex;
  flex-direction: column;
  gap: $space-gap-sm;
  transition: transform 120ms ease;
}

.building-card--hover {
  transform: scale(0.99);
  background: var(--color-muted);
}

.building-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.building-card__name {
  @include title-md;
}

.building-card__tag {
  padding: 6rpx 16rpx;
  border-radius: 12rpx;
  background: var(--color-muted);
}

.building-card__tag-text {
  font-size: 22rpx;
  color: var(--color-foreground);
}

.building-card__tag--office {
  background: var(--color-tag-office, var(--color-muted));
}

.building-card__tag--retail {
  background: var(--color-tag-retail, var(--color-muted));
}

.building-card__tag--apartment {
  background: var(--color-tag-apartment, var(--color-muted));
}

.building-card__tag--mixed {
  background: var(--color-muted);
}

.building-card__meta {
  display: flex;
  align-items: center;
  gap: 12rpx;
}

.building-card__meta-item {
  @include text-caption;
}

.building-card__meta-dot {
  @include text-caption;
}

.building-card__rate {
  display: flex;
  align-items: center;
  gap: $space-gap-sm;
}

.building-card__bar {
  flex: 1;
  height: 10rpx;
  border-radius: 5rpx;
  background: var(--color-border);
  overflow: hidden;
}

.building-card__bar-fill {
  height: 100%;
  border-radius: 5rpx;
  background: var(--color-primary);
}

.building-card__bar-fill--success {
  background: var(--color-success);
}

.building-card__bar-fill--warning {
  background: var(--color-warning);
}

.building-card__bar-fill--danger {
  background: var(--color-destructive);
}

.building-card__rate-text {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--color-foreground);
  min-width: 90rpx;
  text-align: right;
}

.building-card__footer {
  display: flex;
  gap: $space-gap-md;
}

.building-card__footer-item {
  @include text-caption;
}
</style>
