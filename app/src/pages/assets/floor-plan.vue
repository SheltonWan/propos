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
      <!-- 楼层选择栏 -->
      <scroll-view
        v-if="floorList.length > 0"
        class="floor-plan__floor-bar"
        scroll-x
        :show-scrollbar="false"
      >
        <view
          v-for="floor in floorList"
          :key="floor.id"
          class="floor-tab"
          :class="{ 'floor-tab--active': floor.id === activeFloorId }"
          @tap="onFloorTap(floor.id)"
        >
          <text class="floor-tab__text">{{ floor.floor_name }}</text>
        </view>
      </scroll-view>

      <!-- 状态图例 -->
      <view class="legend">
        <view v-for="legend in LEGENDS" :key="legend.status" class="legend__item">
          <view class="legend__dot" :class="`legend__dot--${legend.status}`" />
          <text class="legend__text">{{ legend.label }}</text>
        </view>
      </view>

      <!-- 单元网格 -->
      <AppCard :state="cardState" :animated="false" class="floor-plan__card">
        <template #empty>
          <text class="floor-plan__placeholder">该楼层暂无单元数据</text>
        </template>
        <template #error>
          <text class="floor-plan__placeholder">{{ floorMapStore.error || '加载失败' }}</text>
          <view class="floor-plan__retry" @tap="reload">
            <text class="floor-plan__retry-text">点击重试</text>
          </view>
        </template>

        <view class="unit-grid">
          <view
            v-for="unit in heatmapUnits"
            :key="unit.unit_id"
            class="unit-cell"
            :class="`unit-cell--${unit.current_status}`"
            hover-class="unit-cell--hover"
            :hover-stay-time="80"
            @tap="onUnitTap(unit.unit_id)"
          >
            <text class="unit-cell__number">{{ unit.unit_number }}</text>
            <text v-if="unit.tenant_name" class="unit-cell__tenant">{{ unit.tenant_name }}</text>
            <text v-else class="unit-cell__status">{{ statusLabel(unit.current_status) }}</text>
            <text v-if="unit.contract_end_date" class="unit-cell__end">{{ formatDate(unit.contract_end_date) }} 到期</text>
          </view>
        </view>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import type { Floor, UnitStatus } from '@/types/assets'
import { computed, ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { fetchFloors } from '@/api/modules/assets'
import { useFloorMapStore } from '@/stores/assetsStore'
import { ApiError } from '@/types/api'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const floorMapStore = useFloorMapStore()

const buildingId = ref<string | null>(null)
const floorList = ref<Floor[]>([])
const activeFloorId = ref<string | null>(null)
const floorBarError = ref<string | null>(null)
const floorBarLoading = ref(false)

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已租',
  vacant: '空置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租',
}

const LEGENDS: Array<{ status: UnitStatus, label: string }> = [
  { status: 'leased', label: '已租' },
  { status: 'expiring_soon', label: '即将到期' },
  { status: 'vacant', label: '空置' },
  { status: 'non_leasable', label: '非可租' },
]

function statusLabel(s: UnitStatus): string {
  return STATUS_LABELS[s]
}

function formatDate(value: string): string {
  // ISO 字符串截取 YYYY-MM-DD（业务计算在后端，前端仅展示）
  return value.slice(0, 10)
}

const heatmapUnits = computed(() => floorMapStore.heatmap?.units ?? [])

const cardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (floorMapStore.loading || floorBarLoading.value) return 'loading'
  if (floorMapStore.error || floorBarError.value) return 'error'
  if (!activeFloorId.value || heatmapUnits.value.length === 0) return 'empty'
  return 'default'
})

const headerTitle = computed(() => floorMapStore.item?.building_name ?? '楼层平面图')
const headerSubtitle = computed(() => floorMapStore.item?.floor_name ?? '')

async function loadFloorList(bid: string): Promise<void> {
  floorBarLoading.value = true
  floorBarError.value = null
  try {
    const list = await fetchFloors(bid)
    floorList.value = [...list].sort((a, b) => b.floor_number - a.floor_number)
    if (floorList.value.length > 0 && !activeFloorId.value) {
      activeFloorId.value = floorList.value[0].id
      await floorMapStore.fetchDetail(floorList.value[0].id)
    }
  } catch (e) {
    floorBarError.value = e instanceof ApiError ? e.message : '楼层列表加载失败'
  } finally {
    floorBarLoading.value = false
  }
}

async function onFloorTap(floorId: string) {
  if (floorId === activeFloorId.value) return
  activeFloorId.value = floorId
  await floorMapStore.fetchDetail(floorId)
}

function onUnitTap(unitId: string) {
  uni.navigateTo({ url: `/pages/assets/unit-detail?id=${unitId}` })
}

async function reload() {
  if (activeFloorId.value) {
    await floorMapStore.fetchDetail(activeFloorId.value)
  } else if (buildingId.value) {
    await loadFloorList(buildingId.value)
  }
}

onLoad((options) => {
  const opts = (options ?? {}) as { building_id?: string, floor_id?: string }
  if (opts.floor_id) {
    activeFloorId.value = opts.floor_id
    floorMapStore.fetchDetail(opts.floor_id).then(() => {
      const bid = floorMapStore.item?.building_id ?? null
      buildingId.value = bid
      if (bid) loadFloorList(bid)
    })
  } else if (opts.building_id) {
    buildingId.value = opts.building_id
    loadFloorList(opts.building_id)
  }
})
</script>

<style lang="scss" scoped>
.floor-plan {
  padding: $space-page-y $space-page-x;
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

// ─── 楼层标签栏 ────────────────────────────────────────────────────────────

.floor-plan__floor-bar {
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

// ─── 图例 ──────────────────────────────────────────────────────────────────

.legend {
  display: flex;
  flex-wrap: wrap;
  gap: $space-gap-md;
}

.legend__item {
  display: flex;
  align-items: center;
  gap: 10rpx;
}

.legend__dot {
  width: 18rpx;
  height: 18rpx;
  border-radius: 50%;
  background: var(--color-muted);
}

.legend__dot--leased { background: var(--color-success); }
.legend__dot--expiring_soon { background: var(--color-warning); }
.legend__dot--vacant { background: var(--color-destructive); }
.legend__dot--non_leasable { background: var(--color-muted-foreground); }
.legend__dot--renovating { background: var(--color-info); }
.legend__dot--pre_lease { background: var(--color-info); }

.legend__text {
  @include text-caption;
}

// ─── 单元网格 ──────────────────────────────────────────────────────────────

.floor-plan__card {
  padding: 0;
}

.unit-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: $space-gap-sm;
}

.unit-cell {
  position: relative;
  padding: $space-gap-md;
  border-radius: $radius-control;
  border: 2rpx solid var(--color-border);
  background: var(--color-background);
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  min-height: 160rpx;
  transition: transform 120ms ease;
}

.unit-cell--hover {
  transform: scale(0.98);
}

.unit-cell--leased {
  background: var(--color-primary-soft);
  border-color: var(--color-success);
}

.unit-cell--expiring_soon {
  background: var(--color-primary-soft);
  border-color: var(--color-warning);
}

.unit-cell--vacant {
  border-color: var(--color-destructive);
  background: var(--color-destructive-soft);
}

.unit-cell--non_leasable {
  background: var(--color-muted);
  border-color: var(--color-border);
}

.unit-cell--renovating,
.unit-cell--pre_lease {
  background: var(--color-primary-soft);
  border-color: var(--color-info);
}

.unit-cell__number {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.unit-cell__tenant {
  font-size: 24rpx;
  color: var(--color-foreground);
}

.unit-cell__status {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
}

.unit-cell__end {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
}
</style>
