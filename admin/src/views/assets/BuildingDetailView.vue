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
        <el-table-column label="业态" width="160">
          <template #default="{ row }">
            <!-- 混合体楼栋显示行内编辑下拉；其他楼栋仅显示标签 -->
            <template v-if="store.item?.property_type === 'mixed'">
              <el-select
                :model-value="row.property_type"
                size="small"
                placeholder="待定"
                clearable
                style="width: 110px"
                @change="(val: string) => onFloorPropertyTypeChange(row, val)"
                @click.stop
              >
                <el-option label="写字楼" value="office" />
                <el-option label="商铺" value="retail" />
                <el-option label="公寓" value="apartment" />
              </el-select>
            </template>
            <el-tag
              v-else-if="row.property_type"
              :type="propertyTypeTag(row.property_type)"
              size="small"
            >{{ floorPropertyTypeLabel(row.property_type) }}</el-tag>
            <span v-else style="color: var(--el-text-color-placeholder)">—</span>
          </template>
        </el-table-column>
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
        <el-table-column label="渲染模式" width="120">
          <template #default="{ row }">
            <el-tag
              v-if="row.render_mode"
              :type="row.render_mode === 'vector' ? 'primary' : 'success'"
              size="small"
            >{{ row.render_mode === 'vector' ? 'vector' : 'semantic' }}</el-tag>
            <el-tag v-else type="info" size="small">未标注</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="goFloor(row)">查看热区图</el-button>
            <el-button type="success" link @click.stop="goStructures(row)">结构标注</el-button>
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
import { ElMessage } from 'element-plus'
import { useBuildingDetailStore } from '@/stores'
import type { Floor, BuildingPropertyType, PropertyType } from '@/types/asset'
import { patchFloor } from '@/api/modules/assets'
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

function goStructures(row: Floor): void {
  router.push({
    name: 'FloorStructureAnnotator',
    params: { buildingId: row.building_id, floorId: row.id },
  })
}

function propertyTypeLabel(t: BuildingPropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓', mixed: '综合体' } as const)[t]
}
function propertyTypeTag(t: BuildingPropertyType | PropertyType): 'primary' | 'success' | 'warning' | 'info' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning', mixed: 'info' } as const)[t as BuildingPropertyType] ?? 'info'
}
function floorPropertyTypeLabel(t: PropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓' } as const)[t] ?? t
}
async function onFloorPropertyTypeChange(floor: Floor, val: string): Promise<void> {
  try {
    const updated = await patchFloor(floor.id, { property_type: val as PropertyType })
    // 就地更新 store.floors 中对应楼层，避免重担请求
    const idx = store.floors.findIndex((f) => f.id === floor.id)
    if (idx !== -1) store.floors.splice(idx, 1, { ...store.floors[idx], property_type: updated.property_type })
    const n = updated.updated_unit_count ?? 0
    ElMessage.success(`楼层业态已更新，共更新了 ${n} 个单元`)
  } catch {
    ElMessage.error('业态更新失败，请重试')
  }
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
  if (rate >= 0.7) return 'var(--apple-blue)'
  if (rate >= 0.5) return 'var(--el-color-warning)'
  return 'var(--el-color-danger)'
}
</script>

<style scoped>
.building-detail { padding: 24px 28px; }

.header { margin-bottom: 20px; }

.title {
  font-family: var(--apple-font-display);
  font-size: 22px;
  font-weight: 600;
  letter-spacing: -0.4px;
  color: var(--apple-near-black);
}

.info { margin-bottom: 20px; }

.floors :deep(.el-table) { cursor: pointer; }

.floors-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.section-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--apple-near-black);
  letter-spacing: -0.2px;
}

.rate-value {
  font-weight: 600;
  color: var(--apple-blue);
}

.rate-sub {
  margin-left: 8px;
  font-size: 12px;
  color: var(--apple-text-secondary);
}

.rate-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rate-text {
  font-size: 12px;
  font-weight: 500;
  color: var(--apple-near-black);
  min-width: 48px;
  text-align: right;
}
</style>
