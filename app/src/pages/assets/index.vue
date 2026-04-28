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

        <AssetOverviewPanel
          :rate="store.overallRate"
          :total-units="store.totalUnits"
          :total-leased="store.totalLeased"
        />
      </AppCard>

      <!-- 楼栋列表 -->
      <view v-if="overviewCardState === 'default'" class="assets__list">
        <BuildingCard
          v-for="building in store.list"
          :key="building.id"
          :building="building"
          :occupancy="occupancyOf(building.id)"
          @tap="onBuildingTap"
        />
      </view>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { BuildingOccupancy } from '@/types/assets'
import { computed, onMounted } from 'vue'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import AssetOverviewPanel from '@/components/assets/AssetOverviewPanel.vue'
import BuildingCard from '@/components/assets/BuildingCard.vue'
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

const EMPTY_OCCUPANCY: BuildingOccupancy = { total: 0, leased: 0, vacant: 0, rate: 0 }

function occupancyOf(buildingId: string): BuildingOccupancy {
  return store.buildingOccupancy[buildingId] ?? EMPTY_OCCUPANCY
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
</style>
