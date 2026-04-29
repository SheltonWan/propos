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
      <PageHeader
        :title="building?.name ?? '楼层索引'"
        :subtitle="building?.address ?? ''"
        :back="true"
        :animated="false"
        :state="headerState"
      >
        <template v-if="building" #actions>
          <view class="type-badge" :class="`type-badge--${building.property_type}`">
            <text class="type-badge__text">{{ propertyTypeLabel(building.property_type) }}</text>
          </view>
        </template>
      </PageHeader>
    </template>

    <view class="floors">
      <!-- 楼栋汇总卡片 -->
      <AppCard :state="summaryCardState" :animated="false" :padding="'md'">
        <view v-if="building" class="summary">
          <view class="summary__item">
            <text class="summary__label">总楼层</text>
            <text class="summary__value">{{ building.total_floors }}</text>
            <text class="summary__unit">层</text>
          </view>
          <view class="summary__sep" />
          <view class="summary__item">
            <text class="summary__label">总 GFA</text>
            <text class="summary__value">{{ formatGfa(building.gfa) }}</text>
            <text class="summary__unit">万㎡</text>
          </view>
          <view class="summary__sep" />
          <view class="summary__item">
            <text class="summary__label">净可租面积</text>
            <text class="summary__value">{{ formatGfa(building.nla) }}</text>
            <text class="summary__unit">万㎡</text>
          </view>
        </view>
      </AppCard>

      <!-- 楼层列表标题 -->
      <view class="section-title">
        <view class="section-title__bar" :class="`section-title__bar--${building?.property_type ?? 'office'}`" />
        <text class="section-title__text">楼层索引</text>
        <text class="section-title__hint">点击楼层查看平面图</text>
      </view>

      <!-- 楼层卡片列表 -->
      <AppCard :state="listCardState" :animated="false" :padding="'md'">
        <template #empty>
          <text class="floors__placeholder">暂无楼层数据</text>
        </template>
        <template #error>
          <text class="floors__placeholder">{{ store.error || '加载失败' }}</text>
          <view class="floors__retry" @tap="reload">
            <text class="floors__retry-text">点击重试</text>
          </view>
        </template>

        <view class="floor-list">
          <view
            v-for="floor in store.list"
            :key="floor.id"
            class="floor-item"
            hover-class="floor-item--hover"
            :hover-stay-time="80"
            @tap="onFloorTap(floor.id)"
          >
            <view class="floor-item__left">
              <view class="floor-item__accent" :class="`floor-item__accent--${building?.property_type ?? 'office'}`" />
              <view class="floor-item__info">
                <text class="floor-item__name">{{ floor.floor_name }}</text>
                <text class="floor-item__nla">净可租 {{ formatNla(floor.nla) }}㎡</text>
              </view>
            </view>
            <text class="floor-item__arrow">›</text>
          </view>
        </view>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { PropertyType } from '@/types/assets'
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useBuildingDetailStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useBuildingDetailStore()

const building = computed(() => store.item)

const PROPERTY_TYPE_LABELS: Record<PropertyType, string> = {
  office: '写字楼',
  retail: '商铺',
  apartment: '公寓',
  mixed: '综合体',
}

function propertyTypeLabel(t: PropertyType): string {
  return PROPERTY_TYPE_LABELS[t]
}

const headerState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && !store.item) return 'loading'
  if (store.error && !store.item) return 'error'
  return 'default'
})

const summaryCardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && !store.item) return 'loading'
  if (store.error && !store.item) return 'error'
  if (!store.item) return 'empty'
  return 'default'
})

const listCardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && store.list.length === 0) return 'loading'
  if (store.error) return 'error'
  if (!store.loading && store.list.length === 0) return 'empty'
  return 'default'
})

function formatGfa(value: number): string {
  return (value / 10000).toFixed(1)
}

function formatNla(value: number): string {
  if (value >= 10000) return `${(value / 10000).toFixed(1)}万`
  return value.toLocaleString()
}

function onFloorTap(floorId: string) {
  uni.navigateTo({ url: `/pages/assets/floor-plan?floor_id=${floorId}` })
}

async function reload() {
  if (building.value?.id) {
    await store.fetchDetail(building.value.id)
  }
}

onLoad((options) => {
  const opts = (options ?? {}) as { building_id?: string }
  if (opts.building_id) {
    store.fetchDetail(opts.building_id)
  }
})
</script>

<style lang="scss" scoped>
.floors {
  padding: $space-page-y $space-page-x;
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

/* 业态标签（PageHeader actions） */
.type-badge {
  padding: 8rpx 20rpx;
  border-radius: 999rpx;
  border: 1px solid transparent;
}

.type-badge__text {
  font-size: 22rpx;
  font-weight: 700;
}

.type-badge--office {
  background: $color-primary-soft-md;
  border-color: $color-primary-border-soft;
  .type-badge__text { color: var(--color-primary); }
}

.type-badge--retail {
  background: $color-warning-soft;
  border-color: $color-warning-border-soft;
  .type-badge__text { color: var(--color-warning); }
}

.type-badge--apartment {
  background: $color-info-soft;
  border-color: $color-info-border-soft;
  .type-badge__text { color: var(--color-info); }
}

.type-badge--mixed {
  background: var(--color-muted);
  border-color: var(--color-border);
  .type-badge__text { color: var(--color-muted-foreground); }
}

/* 汇总卡片 */
.summary {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 8rpx 0;
}

.summary__item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4rpx;
}

.summary__label {
  font-size: 20rpx;
  color: var(--color-muted-foreground);
}

.summary__value {
  font-size: 40rpx;
  font-weight: 600;
  color: var(--color-foreground);
  line-height: 1.2;
}

.summary__unit {
  font-size: 18rpx;
  color: var(--color-muted-foreground);
}

.summary__sep {
  width: 1px;
  height: 60rpx;
  background: var(--color-border);
}

/* 分区标题 */
.section-title {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 0 4rpx;
}

.section-title__bar {
  width: 6rpx;
  height: 32rpx;
  border-radius: 999rpx;
}

.section-title__bar--office { background: var(--color-primary); }
.section-title__bar--retail { background: var(--color-warning); }
.section-title__bar--apartment { background: var(--color-info); }
.section-title__bar--mixed { background: var(--color-muted-foreground); }

.section-title__text {
  font-size: 26rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.section-title__hint {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
  margin-left: auto;
}

/* 楼层列表 */
.floor-list {
  display: flex;
  flex-direction: column;
}

.floor-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: $space-gap-md 0;
  border-bottom: 1px solid var(--color-border);
  transition: background 100ms ease;
}

.floor-item:last-child {
  border-bottom: none;
}

.floor-item--hover {
  background: var(--color-muted);
  border-radius: $radius-control;
}

.floor-item__left {
  display: flex;
  align-items: center;
  gap: $space-gap-md;
  flex: 1;
  min-width: 0;
}

.floor-item__accent {
  width: 8rpx;
  height: 48rpx;
  border-radius: 999rpx;
  flex-shrink: 0;
}

.floor-item__accent--office { background: var(--color-primary); }
.floor-item__accent--retail { background: var(--color-warning); }
.floor-item__accent--apartment { background: var(--color-info); }
.floor-item__accent--mixed { background: var(--color-muted-foreground); }

.floor-item__info {
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.floor-item__name {
  font-size: 30rpx;
  font-weight: 600;
  color: var(--color-foreground);
}

.floor-item__nla {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
}

.floor-item__arrow {
  font-size: 36rpx;
  color: var(--color-muted-foreground);
  flex-shrink: 0;
}

/* 占位 / 重试 */
.floors__placeholder {
  @include text-caption;
  display: block;
  text-align: center;
  margin: 60rpx 0;
}

.floors__retry {
  text-align: center;
  margin-top: $space-gap-sm;
}

.floors__retry-text {
  @include text-caption;
  color: var(--color-primary);
}
</style>
