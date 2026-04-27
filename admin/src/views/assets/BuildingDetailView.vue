<template>
  <div class="building-detail">
    <el-page-header class="header" @back="goBack">
      <template #content>
        <span class="title">{{ store.item?.name ?? '楼栋详情' }}</span>
      </template>
    </el-page-header>

    <el-alert v-if="store.error" type="error" :title="store.error" show-icon :closable="false" />

    <!-- 楼栋信息 -->
    <el-descriptions
      v-loading="store.loading"
      class="info"
      :column="2"
      border
      title="楼栋信息"
    >
      <el-descriptions-item label="名称">{{ store.item?.name ?? '—' }}</el-descriptions-item>
      <el-descriptions-item label="主业态">
        <el-tag v-if="store.item" :type="propertyTypeTag(store.item.property_type)">
          {{ propertyTypeLabel(store.item.property_type) }}
        </el-tag>
      </el-descriptions-item>
      <el-descriptions-item label="总层数">
        {{ store.item ? `${store.item.total_floors} 层` : '—' }}
      </el-descriptions-item>
      <el-descriptions-item label="建成年份">{{ store.item?.built_year ?? '—' }}</el-descriptions-item>
      <el-descriptions-item label="建筑面积 (GFA)">
        {{ store.item ? `${formatArea(store.item.gfa)} m²` : '—' }}
      </el-descriptions-item>
      <el-descriptions-item label="净可租面积 (NLA)">
        {{ store.item ? `${formatArea(store.item.nla)} m²` : '—' }}
      </el-descriptions-item>
      <el-descriptions-item label="出租率">
        <span class="rate-value">{{ formatRate(store.overall.rate) }}</span>
        <span class="rate-sub">（已租 {{ store.overall.leased }} / 空置 {{ store.overall.vacant }} / 共 {{ store.overall.total }}）</span>
      </el-descriptions-item>
      <el-descriptions-item label="地址">
        {{ store.item?.address ?? '—' }}
      </el-descriptions-item>
    </el-descriptions>

    <!-- 楼层列表 -->
    <el-card class="floors" shadow="never">
      <template #header>
        <div class="floors-header">
          <span class="section-title">楼层列表</span>
          <el-button type="primary" size="small" :disabled="!store.item" @click="showCadImport = true">
            导入 DXF
          </el-button>
        </div>
      </template>
      <el-table
        v-loading="store.loading"
        :data="sortedFloors"
        stripe
        @row-click="goFloor"
      >
        <el-table-column label="楼层" width="120">
          <template #default="{ row }">{{ row.floor_name ?? `${row.floor_number}F` }}</template>
        </el-table-column>
        <el-table-column prop="floor_number" label="楼层号" width="100" align="right" />
        <el-table-column label="总单元数" width="110" align="right">
          <template #default="{ row }">{{ store.floorOccupancy[row.id]?.total ?? 0 }}</template>
        </el-table-column>
        <el-table-column label="已租" width="90" align="right">
          <template #default="{ row }">{{ store.floorOccupancy[row.id]?.leased ?? 0 }}</template>
        </el-table-column>
        <el-table-column label="空置" width="90" align="right">
          <template #default="{ row }">{{ store.floorOccupancy[row.id]?.vacant ?? 0 }}</template>
        </el-table-column>
        <el-table-column label="出租率" min-width="200">
          <template #default="{ row }">
            <div class="rate-cell">
              <el-progress
                :percentage="ratePct(store.floorOccupancy[row.id]?.rate ?? 0)"
                :color="rateColor(store.floorOccupancy[row.id]?.rate ?? 0)"
                :stroke-width="10"
                :show-text="false"
                style="flex: 1"
              />
              <span class="rate-text">{{ formatRate(store.floorOccupancy[row.id]?.rate ?? 0) }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="净可租面积 (m²)" width="160" align="right">
          <template #default="{ row }">{{ formatArea(row.nla) }}</template>
        </el-table-column>
        <el-table-column label="图纸" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.svg_path" type="success" size="small">已上传</el-tag>
            <el-tag v-else type="info" size="small">未上传</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="goFloor(row)">查看热区图</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <CadImportDialog
      v-model="showCadImport"
      :building-id="buildingId"
      :floors="store.floors"
      @finished="onCadFinished"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useBuildingDetailStore } from '@/stores'
import type { Floor, BuildingPropertyType } from '@/types/asset'
import CadImportDialog from './components/CadImportDialog.vue'

const store = useBuildingDetailStore()
const route = useRoute()
const router = useRouter()

const buildingId = computed(() => route.params.id as string)
const showCadImport = ref(false)

const sortedFloors = computed(() =>
  [...store.floors].sort((a, b) => b.floor_number - a.floor_number),
)

onMounted(() => {
  store.fetchDetail(buildingId.value)
})

watch(buildingId, (id) => {
  if (id) store.fetchDetail(id)
})

function onCadFinished(): void {
  // CAD 导入完成后重拉楼栋明细（楼层 svg_path 可能已更新）
  store.fetchDetail(buildingId.value)
}

function goBack(): void {
  router.push({ name: 'assets' })
}

function goFloor(row: Floor): void {
  router.push({
    name: 'floor-plan',
    params: { buildingId: row.building_id, floorId: row.id },
  })
}

function propertyTypeLabel(t: BuildingPropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓', mixed: '综合体' } as const)[t]
}
function propertyTypeTag(t: BuildingPropertyType): 'primary' | 'success' | 'warning' | 'info' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning', mixed: 'info' } as const)[t]
}
function formatArea(v: number | null): string {
  if (v == null) return '—'
  return v.toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}
function formatRate(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`
}
function ratePct(rate: number): number {
  return Math.round(rate * 100)
}
function rateColor(rate: number): string {
  if (rate >= 0.9) return 'var(--el-color-success)'
  if (rate >= 0.7) return 'var(--el-color-primary)'
  if (rate >= 0.5) return 'var(--el-color-warning)'
  return 'var(--el-color-danger)'
}
</script>

<style scoped>
.building-detail { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.info { margin-bottom: 24px; }
.floors :deep(.el-table) { cursor: pointer; }
.floors-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.section-title {
  font-size: 14px;
  font-weight: 600;
}
.rate-value {
  font-weight: 600;
  color: var(--el-color-primary);
}
.rate-sub {
  margin-left: 8px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.rate-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}
.rate-text {
  font-size: 12px;
  color: var(--el-text-color-regular);
  min-width: 48px;
  text-align: right;
}
</style>
