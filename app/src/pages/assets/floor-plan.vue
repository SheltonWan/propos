<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell content-inset="none">
    <template #header>
      <PageHeader :title="headerTitle" :subtitle="headerSubtitle" :back="true" :animated="false" />
    </template>

    <view class="floor-plan">
      <!-- ① 楼层切换标签栏 -->
      <view class="floor-plan__tabbar">
        <FloorTabBar
          v-if="store.list.length > 0"
          :floors="store.list"
          :active-id="store.item?.id ?? null"
          @select="onFloorSelect"
        />
      </view>

      <!-- ② 图层切换按钮 -->
      <view class="layer-toggle">
        <view
          class="layer-toggle__btn"
          :class="currentLayer === 'status' ? 'layer-toggle__btn--active' : ''"
          @tap="currentLayer = 'status'"
        >
          <text class="layer-toggle__text">出租状态</text>
        </view>
        <view
          class="layer-toggle__btn"
          :class="currentLayer === 'expiry' ? 'layer-toggle__btn--active' : ''"
          @tap="currentLayer = 'expiry'"
        >
          <text class="layer-toggle__text">到期预警</text>
        </view>
      </view>

      <!-- ③ SVG 热区图 / 加载 / 空态 / 错误 -->
      <view class="heatmap-area">
        <!-- 加载骨架 -->
        <view v-if="store.loading" class="heatmap-area__skeleton">
          <view class="skeleton-rect" style="height: 240rpx; border-radius: 20rpx;" />
        </view>

        <!-- 错误状态 -->
        <view v-else-if="store.error" class="heatmap-area__status">
          <text class="heatmap-area__status-text">{{ store.error || '加载失败' }}</text>
          <view class="heatmap-area__retry" @tap="reload">
            <text class="heatmap-area__retry-text">点击重试</text>
          </view>
        </view>

        <!-- 空态 -->
        <view v-else-if="heatmapUnits.length === 0" class="heatmap-area__status">
          <text class="heatmap-area__status-text">该楼层暂无单元数据</text>
        </view>

        <!-- SVG 热区图（H5 / App） -->
        <!-- #ifdef H5 || APP-PLUS -->
        <FloorSvgHeatmap
          v-else
          :units="heatmapUnits"
          :property-type="floorPropertyType"
          :layer="currentLayer"
          :selected-id="selectedUnitId"
          :svg-path="floorSvgPath"
          @unit-tap="onSvgUnitTap"
        />
        <!-- #endif -->

        <!-- 小程序降级：SVG 不支持，回退到房间网格卡片 -->
        <!-- #ifdef MP-WEIXIN || MP-HARMONY -->
        <view v-else class="unit-grid">
          <UnitGridCell
            v-for="unit in heatmapUnits"
            :key="unit.unit_id"
            :unit="unit"
            @tap="onUnitGridTap"
          />
        </view>
        <!-- #endif -->
      </view>

      <!-- ④ 状态图例 -->
      <view class="floor-plan__legend">
        <FloorLegend :layer="currentLayer" />
      </view>

      <!-- ⑤ 楼层统计栏 -->
      <view v-if="heatmapUnits.length > 0" class="stats-bar">
        <view class="stats-bar__item">
          <text class="stats-bar__value stats-bar__value--leased">{{ leasedCount }}</text>
          <text class="stats-bar__label">已租</text>
        </view>
        <view class="stats-bar__divider" />
        <view class="stats-bar__item">
          <text class="stats-bar__value stats-bar__value--vacant">{{ vacantCount }}</text>
          <text class="stats-bar__label">空置</text>
        </view>
        <view class="stats-bar__divider" />
        <view class="stats-bar__item">
          <text class="stats-bar__value">{{ totalLeasable }}</text>
          <text class="stats-bar__label">可租总量</text>
        </view>
        <view class="stats-bar__divider" />
        <view class="stats-bar__item">
          <text class="stats-bar__value stats-bar__value--rate">{{ occupancyRate }}%</text>
          <text class="stats-bar__label">出租率</text>
        </view>
      </view>
    </view>
  </AppShell>

  <!-- 房间详情抽屉（全局遮罩层） -->
  <FloorUnitDrawer
    :unit="selectedUnit"
    :open="drawerOpen"
    @close="closeDrawer"
    @navigate-to-unit="onNavigateToUnit"
  />
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import FloorTabBar from '@/components/assets/FloorTabBar.vue'
import FloorLegend from '@/components/assets/FloorLegend.vue'
import FloorSvgHeatmap from '@/components/assets/FloorSvgHeatmap.vue'
import FloorUnitDrawer from '@/components/assets/FloorUnitDrawer.vue'
import UnitGridCell from '@/components/assets/UnitGridCell.vue'
import type { LayerMode } from '@/types/assets'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useFloorMapStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useFloorMapStore()

// ── 热区图数据 ───────────────────────────────────────────────────────────────

const heatmapUnits = computed(() => store.heatmap?.units ?? [])

/** 后端返回的真实 CAD-SVG 相对路径，非空时组件走 `/api/files/...` 加载 */
const floorSvgPath = computed(() => store.heatmap?.svg_path ?? null)

/** 从房间列表推断楼层业态（优先取第一个可租房源的类型） */
const floorPropertyType = computed(() => {
  const unit = heatmapUnits.value.find(u => u.property_type !== undefined)
  return unit?.property_type ?? 'office'
})

// ── 图层切换 ─────────────────────────────────────────────────────────────────

const currentLayer = ref<LayerMode>('status')

// ── 选中房间（抽屉） ──────────────────────────────────────────────────────────

const selectedUnitId = ref<string | null>(null)

const selectedUnit = computed(
  () => heatmapUnits.value.find(u => u.unit_id === selectedUnitId.value) ?? null,
)

const drawerOpen = computed(() => selectedUnit.value !== null)

function onSvgUnitTap(unitId: string) {
  // 再次点击同一房间 → 关闭抽屉
  selectedUnitId.value = selectedUnitId.value === unitId ? null : unitId
}

function closeDrawer() {
  selectedUnitId.value = null
}

/** 小程序降级：直接跳转房源详情（无抽屉交互） */
function onUnitGridTap(unitId: string) {
  uni.navigateTo({ url: `/pages/assets/unit-detail?id=${unitId}` })
}

function onNavigateToUnit(unitId: string) {
  selectedUnitId.value = null
  uni.navigateTo({ url: `/pages/assets/unit-detail?id=${unitId}` })
}

// ── 统计数据 ─────────────────────────────────────────────────────────────────

/** 出租中（含即将到期） */
const leasedCount = computed(
  () => heatmapUnits.value.filter(u => u.current_status === 'leased' || u.current_status === 'expiring_soon').length,
)

/** 空置（含预租中） */
const vacantCount = computed(
  () => heatmapUnits.value.filter(u => u.current_status === 'vacant' || u.current_status === 'pre_lease').length,
)

/** 可租总量（排除非可租） */
const totalLeasable = computed(
  () => heatmapUnits.value.filter(u => u.current_status !== 'non_leasable').length,
)

/** 出租率（%，整数） */
const occupancyRate = computed(() => {
  if (totalLeasable.value === 0) return 0
  return Math.round((leasedCount.value / totalLeasable.value) * 100)
})

// ── 头部标题 ─────────────────────────────────────────────────────────────────

const headerTitle = computed(() => store.item?.building_name ?? '楼层平面图')
const headerSubtitle = computed(() => store.item?.floor_name ?? '')

// ── 事件 ─────────────────────────────────────────────────────────────────────

async function onFloorSelect(floorId: string) {
  if (floorId === store.item?.id) return
  selectedUnitId.value = null
  await store.selectFloor(floorId)
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
  display: flex;
  flex-direction: column;
  gap: 0;
}

// ── 楼层切换栏 ────────────────────────────────────────────────────────────────

.floor-plan__tabbar {
  padding: $space-page-y $space-page-x 0;
}

// ── 图层切换 ─────────────────────────────────────────────────────────────────

.layer-toggle {
  display: flex;
  align-items: center;
  gap: $space-gap-sm;
  padding: $space-gap-md $space-page-x;
}

.layer-toggle__btn {
  padding: 10rpx 28rpx;
  border-radius: 999rpx;
  border: 1rpx solid var(--color-border);
  background: var(--color-background);
  transition: all 0.15s ease;
}

.layer-toggle__btn--active {
  background: var(--color-primary);
  border-color: var(--color-primary);

  .layer-toggle__text {
    color: var(--color-primary-foreground);
  }
}

.layer-toggle__text {
  font-size: 24rpx;
  font-weight: 500;
  color: var(--color-muted-foreground);
}

// ── 热区图区域 ────────────────────────────────────────────────────────────────

.heatmap-area {
  min-height: 240rpx;
}

.heatmap-area__skeleton {
  padding: 0 $space-page-x;
}

.skeleton-rect {
  background: var(--color-muted);
  animation: skeleton-pulse 1.4s ease-in-out infinite;
}

@keyframes skeleton-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.heatmap-area__status {
  padding: 80rpx $space-page-x 40rpx;
  text-align: center;
}

.heatmap-area__status-text {
  @include text-caption;
  display: block;
}

.heatmap-area__retry {
  margin-top: $space-gap-sm;
}

.heatmap-area__retry-text {
  @include text-caption;
  color: var(--color-primary);
}

// ── 图例 ─────────────────────────────────────────────────────────────────────

.floor-plan__legend {
  padding: $space-gap-sm $space-page-x;
}

// ── 统计栏 ────────────────────────────────────────────────────────────────────

.stats-bar {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: $space-gap-md $space-page-x $space-page-y;
  border-top: 1rpx solid var(--color-border);
  margin-top: 4rpx;
}

.stats-bar__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6rpx;
}

.stats-bar__value {
  font-size: 34rpx;
  font-weight: 700;
  color: var(--color-foreground);
}

.stats-bar__value--leased { color: var(--color-success); }
.stats-bar__value--vacant { color: var(--color-destructive); }
.stats-bar__value--rate { color: var(--color-primary); }

.stats-bar__label {
  font-size: 22rpx;
  color: var(--color-muted-foreground);
}

.stats-bar__divider {
  width: 1rpx;
  height: 48rpx;
  background: var(--color-border);
}

// ── 小程序降级：房间网格 ────────────────────────────────────────────────────────

.unit-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: $space-gap-sm;
  padding: 0 $space-page-x $space-page-y;
}
</style>
