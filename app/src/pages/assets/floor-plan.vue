<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell content-inset="none" :scroll="false">
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

        <!-- SVG 热区图（H5 / App）：横向可滚动，支持放大/缩小/适配 -->
        <!-- #ifdef H5 || APP-PLUS -->
        <scroll-view
          v-else
          scroll-x
          scroll-y
          class="heatmap-scroll"
        >
          <!-- wrap-view：确保 scroll-view 内部内容在 App-Plus 中靠左对齐 -->
          <view class="heatmap-canvas-wrap">
            <FloorSvgHeatmap
              :units="heatmapUnits"
              :property-type="floorPropertyType"
              :layer="currentLayer"
              :selected-id="selectedUnitId"
              :svg-path="floorSvgPath"
              :scale="zoom"
              @unit-tap="onSvgUnitTap"
            />
          </view>
        </scroll-view>
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

        <!-- 缩放控制按钮（H5 / App，仅在有数据时显示，对齐 frontend FloorPlan.tsx） -->
        <!-- #ifdef H5 || APP-PLUS -->
        <view
          v-if="heatmapUnits.length > 0 && !store.loading && !store.error"
          class="zoom-controls"
        >
          <view class="zoom-controls__btn" @tap="zoomIn">
            <text class="zoom-controls__icon">+</text>
          </view>
          <view class="zoom-controls__btn zoom-controls__btn--fit" @tap="zoomFit">
            <text class="zoom-controls__icon zoom-controls__icon--fit">适</text>
          </view>
          <view class="zoom-controls__btn" @tap="zoomOut">
            <text class="zoom-controls__icon">−</text>
          </view>
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
  zoom.value = 1.0 // 切换楼层时重置缩放
  await store.selectFloor(floorId)
}

async function reload() {
  if (store.item?.id) {
    await store.selectFloor(store.item.id)
  } else if (store.buildingId) {
    await store.loadByBuilding(store.buildingId)
  }
}

// ── 缩放控制（H5 / App，对齐 frontend FloorPlan.tsx 放大、缩小、适配功能） ────────────────────────────

const { windowWidth: _screenPx } = uni.getSystemInfoSync()

/** 当前缩放比例（1.0 = 适配屏幕宽度） */
const zoom = ref(1.0)
const ZOOM_MIN = 0.6
const ZOOM_MAX = 2.8
const ZOOM_STEP = 0.3

/** 放大一步 */
function zoomIn() {
  zoom.value = parseFloat(Math.min(zoom.value + ZOOM_STEP, ZOOM_MAX).toFixed(1))
}
/** 缩小一步 */
function zoomOut() {
  zoom.value = parseFloat(Math.max(zoom.value - ZOOM_STEP, ZOOM_MIN).toFixed(1))
}
/** 适配屏幕宽度（重置缩放） */
function zoomFit() {
  zoom.value = 1.0
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
  /* 填满 AppShell static body 分配的全部剩余高度 */
  flex: 1;
  min-height: 0;
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
  /* 伸缩填满楼层标签栏与图例/统计栏之间剩余空间（对齐 frontend flex-1 overflow-auto） */
  flex: 1;
  min-height: 0;
  position: relative; // 供缩放按钮绝对定位
  align-items: flex-start; // 确保 scroll-view 及内容靠左，不被 flex 默认 stretch 居中
}

// 可滚动区域（H5 / App 有效）
.heatmap-scroll {
  width: 100%;
  height: 100%; // 填满 heatmap-area 所有高度
  -webkit-overflow-scrolling: touch; // iOS 惯性滚动
}

// scroll-view 内直接子容器，强制左对齐（App-Plus scroll-view 内容对齐保障）
.heatmap-canvas-wrap {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  min-width: 100%;
  min-height: 100%;
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

// ── 缩放控制按钮（H5 / App，对齐 frontend 右下角三连按钮布局） ─────────────────

.zoom-controls {
  position: absolute;
  bottom: 24rpx;
  right: 24rpx;
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  z-index: 10;
}

.zoom-controls__btn {
  width: 72rpx;
  height: 72rpx;
  background: var(--color-background);
  border: 1rpx solid var(--color-border);
  border-radius: 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.10);
  // 按压态
  &:active {
    background: var(--color-muted);
  }
}

.zoom-controls__btn--fit {
  border-color: var(--color-primary);
  border-opacity: 0.4;
}

.zoom-controls__icon {
  font-size: 34rpx;
  font-weight: 600;
  color: var(--color-muted-foreground);
  line-height: 1;
}

.zoom-controls__icon--fit {
  font-size: 24rpx;
  font-weight: 700;
  color: var(--color-primary);
}

// ── 小程序降级：房间网格 ────────────────────────────────────────────────────────

.unit-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: $space-gap-sm;
  padding: 0 $space-page-x $space-page-y;
}
</style>
