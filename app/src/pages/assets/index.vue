<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell with-tabbar content-inset="none">
    <template #header>
      <PageHeader title="资产台账" :sticky="true" :back="false" :animated="false">
        <template #actions>
          <view class="header-actions">
            <view class="header-btn header-btn--primary" @tap="showExportSheet = true">
              <text class="header-btn__text header-btn__text--primary">导出</text>
            </view>
          </view>
        </template>
        <template #extra>
          <!-- 搜索框 -->
          <view class="search-bar">
            <text class="search-bar__icon">🔍</text>
            <input
              v-model="search"
              class="search-bar__input"
              placeholder="搜索楼栋名称或地址..."
              placeholder-class="search-bar__placeholder"
              confirm-type="search"
            />
          </view>
        </template>
      </PageHeader>
    </template>

    <view class="assets">
      <!-- 深色总览卡片 -->
      <AppCard
        class="assets__overview"
        variant="dark"
        :state="overviewCardState"
        :animated="false"
        :padding="'md'"
        :shadow="true"
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
          :total-gfa="store.totalGfa"
          :total-units="store.totalUnits"
          :total-leased="store.totalLeased"
          :total-vacant="store.totalVacant"
          :building-count="store.buildingCount"
        />
      </AppCard>

      <!-- 业态对比卡片（仅在数据加载完后显示） -->
      <view v-if="overviewCardState === 'default'" class="type-cards">
        <view
          v-for="type in TYPE_LIST"
          :key="type.key"
          class="type-card"
          :class="`type-card--${type.key}`"
          @tap="activeTab = type.label"
        >
          <view class="type-card__head">
            <text class="type-card__name">{{ type.label }}</text>
          </view>
          <text class="type-card__area">{{ formatGfa(store.typeStats[type.key]?.gfa ?? 0) }}万㎡ · {{ store.typeStats[type.key]?.units ?? 0 }}套</text>
          <text class="type-card__vacancy" :class="vacancyClass(store.typeStats[type.key]?.vacancyRate ?? 0)">
            空置{{ store.typeStats[type.key]?.vacancyRate ?? 0 }}%
          </text>
        </view>
      </view>

      <!-- Tab 筛选条 -->
      <view v-if="overviewCardState === 'default'" class="tab-bar">
        <scroll-view scroll-x :show-scrollbar="false" class="tab-bar__scroll">
          <view
            v-for="tab in TABS"
            :key="tab"
            class="tab-item"
            :class="{ 'tab-item--active': activeTab === tab }"
            @tap="activeTab = tab"
          >
            <text class="tab-item__text">{{ tab }}</text>
          </view>
        </scroll-view>
      </view>

      <!-- 楼栋列表 -->
      <view v-if="overviewCardState === 'default'" class="assets__list">
        <BuildingCard
          v-for="building in filteredBuildings"
          :key="building.id"
          :building="building"
          :occupancy="occupancyOf(building.id)"
          @select="onBuildingTap"
        />
        <!-- 空结果提示 -->
        <view v-if="filteredBuildings.length === 0" class="assets__empty">
          <text class="assets__empty-text">未找到匹配的楼栋</text>
        </view>
      </view>
    </view>

    <!-- 导出抽屉 -->
    <BottomSheet
      v-model="showExportSheet"
      title="导出资产台账"
    >
      <view class="export-sheet">
        <view class="export-sheet__section">
          <text class="export-sheet__label">选择导出业态</text>
          <view
            v-for="type in TYPE_LIST"
            :key="type.key"
            class="export-sheet__option"
            @tap="toggleExport(type.key)"
          >
            <view class="export-sheet__check" :class="{ 'export-sheet__check--on': exportTypes[type.key] }">
              <text v-if="exportTypes[type.key]" class="export-sheet__check-mark">✓</text>
            </view>
            <text class="export-sheet__option-name">{{ type.label }}</text>
            <text class="export-sheet__option-meta">
              {{ store.typeStats[type.key]?.units ?? 0 }}套 · {{ formatGfa(store.typeStats[type.key]?.gfa ?? 0) }}万㎡
            </text>
          </view>
        </view>
        <view class="export-sheet__hint">
          <text class="export-sheet__hint-text">导出内容：楼栋信息、单元编号、面积、业态、出租状态、合同到期日、月租金</text>
        </view>
        <view class="export-sheet__btn" :class="{ 'export-sheet__btn--disabled': !hasExportType }" @tap="onExport">
          <text class="export-sheet__btn-text">导出 Excel</text>
        </view>
      </view>
    </BottomSheet>
  </AppShell>
</template>

<script setup lang="ts">
import type { BuildingOccupancy, PropertyType } from '@/types/assets'
import { computed, onMounted, ref } from 'vue'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import BottomSheet from '@/components/base/BottomSheet.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import AssetOverviewPanel from '@/components/assets/AssetOverviewPanel.vue'
import BuildingCard from '@/components/assets/BuildingCard.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAssetOverviewStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useAssetOverviewStore()

// ── 本地 UI 状态 ─────────────────────────────────────────────────────────────
const search = ref('')
const activeTab = ref('全部')
const showExportSheet = ref(false)
const exportTypes = ref<Record<string, boolean>>({ office: true, retail: true, apartment: true })

// ── 业态列表常量 ──────────────────────────────────────────────────────────────
const TYPE_LIST: Array<{ key: PropertyType; label: string }> = [
  { key: 'office', label: '写字楼' },
  { key: 'retail', label: '商铺' },
  { key: 'apartment', label: '公寓' },
]

const TABS = ['全部', '写字楼', '商铺', '公寓']

const TYPE_LABEL_MAP: Record<string, PropertyType> = {
  '写字楼': 'office',
  '商铺': 'retail',
  '公寓': 'apartment',
}

// ── 计算属性 ──────────────────────────────────────────────────────────────────
const overviewCardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading && store.list.length === 0) return 'loading'
  if (store.error) return 'error'
  if (store.list.length === 0) return 'empty'
  return 'default'
})

const filteredBuildings = computed(() => {
  const typeFilter = activeTab.value !== '全部' ? TYPE_LABEL_MAP[activeTab.value] : null
  const q = search.value.trim().toLowerCase()
  return store.list.filter((b) => {
    if (typeFilter && b.property_type !== typeFilter) return false
    if (q && !b.name.toLowerCase().includes(q) && !b.address.toLowerCase().includes(q)) return false
    return true
  })
})

const hasExportType = computed(() => Object.values(exportTypes.value).some(v => v))

// ── 工具函数 ──────────────────────────────────────────────────────────────────
const EMPTY_OCCUPANCY: BuildingOccupancy = { total: 0, leased: 0, vacant: 0, rate: 0 }

/**
 * 返回楼栋出租率占位数据。
 * 概览接口（/api/assets/overview）仅提供业态级聚合，不含楼栋粒度数据；
 * 精确楼栋出租率在楼栋详情页（useBuildingDetailStore）加载后展示。
 */
function occupancyOf(_buildingId: string): BuildingOccupancy {
  return EMPTY_OCCUPANCY
}

function onBuildingTap(buildingId: string) {
  uni.navigateTo({ url: `/pages/assets/floors?building_id=${buildingId}` })
}

function toggleExport(type: string) {
  exportTypes.value[type] = !exportTypes.value[type]
}

function onExport() {
  if (!hasExportType.value) return
  showExportSheet.value = false
  uni.showToast({ title: '导出请求已提交', icon: 'success' })
}

function formatGfa(gfa: number): string {
  return (gfa / 10000).toFixed(1)
}

function vacancyClass(rate: number): string {
  if (rate > 15) return 'type-card__vacancy--danger'
  if (rate > 5) return 'type-card__vacancy--warn'
  return 'type-card__vacancy--ok'
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

/* 顶部操作按钮组 */
.header-actions {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.header-btn {
  display: flex;
  align-items: center;
  padding: 10rpx 20rpx;
  border-radius: 999rpx;
  background: var(--color-muted);
}

.header-btn--primary {
  background: var(--color-primary-soft);
}

.header-btn__text {
  font-size: 24rpx;
  font-weight: 500;
  color: var(--color-muted-foreground);
}

.header-btn__text--primary {
  color: var(--color-primary);
}

/* 搜索框 */
.search-bar {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 0 $space-page-x 20rpx;
}

.search-bar__icon {
  font-size: 28rpx;
  flex-shrink: 0;
}

.search-bar__input {
  flex: 1;
  height: 64rpx;
  padding: 0 24rpx;
  background: var(--color-muted);
  border: 1px solid var(--color-border);
  border-radius: $radius-control;
  font-size: 26rpx;
  color: var(--color-foreground);
}

.search-bar__placeholder {
  color: var(--color-muted-foreground);
  font-size: 26rpx;
}

/* 业态对比卡片 */
.type-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16rpx;
}

.type-card {
  @include card-base;
  padding: 24rpx;
  display: flex;
  flex-direction: column;
  gap: 8rpx;
}

.type-card--office {
  border-left: 4rpx solid var(--color-primary);
}

.type-card--retail {
  border-left: 4rpx solid var(--color-warning);
}

.type-card--apartment {
  border-left: 4rpx solid var(--color-info);
}

.type-card__head {
  display: flex;
  align-items: center;
  gap: 8rpx;
  margin-bottom: 4rpx;
}

.type-card__name {
  font-size: 22rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.type-card__area {
  font-size: 18rpx;
  color: var(--color-muted-foreground);
}

.type-card__vacancy {
  font-size: 24rpx;
  font-weight: 700;
}

.type-card__vacancy--danger { color: var(--color-destructive); }
.type-card__vacancy--warn { color: var(--color-warning); }
.type-card__vacancy--ok { color: var(--color-success); }

/* Tab 筛选条 */
.tab-bar {
  margin: 0 -#{$space-page-x};
  padding: 0 $space-page-x;
}

.tab-bar__scroll {
  white-space: nowrap;
}

.tab-item {
  display: inline-flex;
  align-items: center;
  padding: 12rpx 28rpx;
  margin-right: 16rpx;
  border-radius: 999rpx;
  background: var(--color-background);
  border: 1px solid var(--color-border);
}

.tab-item--active {
  background: var(--color-primary);
  border-color: var(--color-primary);
}

.tab-item__text {
  font-size: 24rpx;
  font-weight: 500;
  color: var(--color-muted-foreground);
}

.tab-item--active .tab-item__text {
  color: var(--color-primary-foreground);
  font-weight: 600;
}

/* 楼栋列表 */
.assets__list {
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

.assets__empty {
  padding: 80rpx 0;
  text-align: center;
}

.assets__empty-text {
  @include text-caption;
}

/* 导出抽屉 */
.export-sheet {
  padding: 0 $space-page-x;
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

.export-sheet__section {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.export-sheet__label {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
  margin-bottom: 4rpx;
}

.export-sheet__option {
  display: flex;
  align-items: center;
  gap: $space-gap-md;
  padding: $space-gap-md $space-gap-md;
  background: var(--color-muted);
  border: 1px solid var(--color-border);
  border-radius: $radius-control;
}

.export-sheet__check {
  width: 40rpx;
  height: 40rpx;
  border-radius: 8rpx;
  border: 2px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.export-sheet__check--on {
  background: var(--color-primary);
  border-color: var(--color-primary);
}

.export-sheet__check-mark {
  font-size: 22rpx;
  color: var(--color-primary-foreground);
  font-weight: 700;
}

.export-sheet__option-name {
  font-size: 28rpx;
  font-weight: 500;
  color: var(--color-foreground);
  flex: 1;
}

.export-sheet__option-meta {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
}

.export-sheet__hint {
  background: var(--color-primary-soft);
  border-radius: $radius-control;
  padding: $space-gap-md;
}

.export-sheet__hint-text {
  font-size: 24rpx;
  color: var(--color-muted-foreground);
  line-height: 1.6;
}

.export-sheet__btn {
  padding: 28rpx;
  border-radius: $radius-control;
  background: var(--color-primary);
  text-align: center;
  margin-bottom: $space-gap-md;
}

.export-sheet__btn--disabled {
  opacity: 0.4;
}

.export-sheet__btn-text {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--color-primary-foreground);
}
</style>
