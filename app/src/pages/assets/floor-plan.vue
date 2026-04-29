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
      <PageHeader :title="headerTitle" :subtitle="headerSubtitle" :back="true" :animated="false" />
    </template>

    <view class="floor-plan">
      <!-- 楼层切换栏 -->
      <FloorTabBar
        v-if="store.list.length > 0"
        :floors="store.list"
        :active-id="store.item?.id ?? null"
        @select="onFloorSelect"
      />

      <!-- 状态图例 -->
      <FloorLegend />

      <!-- 单元网格 -->
      <AppCard :state="cardState" :animated="false" class="floor-plan__card">
        <template #empty>
          <text class="floor-plan__placeholder">该楼层暂无单元数据</text>
        </template>
        <template #error>
          <text class="floor-plan__placeholder">{{ store.error || '加载失败' }}</text>
          <view class="floor-plan__retry" @tap="reload">
            <text class="floor-plan__retry-text">点击重试</text>
          </view>
        </template>

        <view class="unit-grid">
          <UnitGridCell
            v-for="unit in heatmapUnits"
            :key="unit.unit_id"
            :unit="unit"
            @tap="onUnitTap"
          />
        </view>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import FloorTabBar from '@/components/assets/FloorTabBar.vue'
import FloorLegend from '@/components/assets/FloorLegend.vue'
import UnitGridCell from '@/components/assets/UnitGridCell.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useFloorMapStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useFloorMapStore()

const heatmapUnits = computed(() => store.heatmap?.units ?? [])

const cardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading) return 'loading'
  if (store.error) return 'error'
  if (!store.item || heatmapUnits.value.length === 0) return 'empty'
  return 'default'
})

const headerTitle = computed(() => store.item?.building_name ?? '楼层平面图')
const headerSubtitle = computed(() => store.item?.floor_name ?? '')

async function onFloorSelect(floorId: string) {
  if (floorId === store.item?.id) return
  await store.selectFloor(floorId)
}

function onUnitTap(unitId: string) {
  uni.navigateTo({ url: `/pages/assets/unit-detail?id=${unitId}` })
}

async function reload() {
  if (store.item?.id) {
    await store.selectFloor(store.item.id)
  } else if (store.buildingId) {
    await store.loadByBuilding(store.buildingId)
  }
}

onLoad((options) => {
  const opts = (options ?? {}) as { building_id?: string, floor_id?: string }
  store.reset()
  if (opts.floor_id) {
    store.selectFloor(opts.floor_id)
  } else if (opts.building_id) {
    store.loadByBuilding(opts.building_id)
  }
})
</script>

<style lang="scss" scoped>
.floor-plan {
  // 水平 padding 由 AppShell contentInset="default" 统一提供，此处只设垂直方向
  padding-top: $space-page-y;
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

.floor-plan__placeholder {
  @include text-caption;
  display: block;
  text-align: center;
  margin: 60rpx 0;
}

.floor-plan__retry {
  text-align: center;
  margin-top: $space-gap-sm;
}

.floor-plan__retry-text {
  @include text-caption;
  color: var(--color-primary);
}

.floor-plan__card {
  padding: 0;
}

.unit-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: $space-gap-sm;
}
</style>
