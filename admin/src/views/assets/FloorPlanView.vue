<template>
  <div class="floor-plan">
    <el-page-header class="header" @back="goBack">
      <template #content>
        <span class="title">
          {{ store.item ? `${store.item.building_name ?? ''} ${store.item.floor_name ?? store.item.floor_number + 'F'} 热区图` : '楼层热区图' }}
        </span>
      </template>
      <template #extra>
        <el-select
          v-if="store.plans.length > 0"
          :model-value="currentPlanId"
          placeholder="切换图纸版本"
          style="width: 220px"
          @change="onChangePlan"
        >
          <el-option
            v-for="p in store.plans"
            :key="p.id"
            :value="p.id"
            :label="`${p.version_label}${p.is_current ? '（当前）' : ''}`"
          />
        </el-select>
      </template>
    </el-page-header>

    <el-alert v-if="store.error" type="error" :title="store.error" show-icon :closable="false" />

    <div v-loading="store.loading" class="layout">
      <!-- 单元列表 -->
      <div class="unit-list">
        <div class="list-header">单元（{{ store.heatmap?.units.length ?? 0 }}）</div>
        <el-input v-model="keyword" placeholder="搜索单元号" clearable size="default" />
        <el-table
          :data="filteredUnits"
          height="calc(100vh - 280px)"
          stripe
          highlight-current-row
          :row-class-name="rowClass"
          @row-click="onUnitRowClick"
        >
          <el-table-column prop="unit_number" label="单元" min-width="100" />
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <el-tag :type="statusTag(row.current_status)" size="small">
                {{ statusLabel(row.current_status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="租户" min-width="120" show-overflow-tooltip>
            <template #default="{ row }">{{ row.tenant_name ?? '—' }}</template>
          </el-table-column>
        </el-table>
      </div>

      <!-- SVG 热区 -->
      <div class="svg-container">
        <div v-if="!store.heatmap?.svg_path" class="empty">该楼层暂未上传图纸</div>
        <img v-else :src="svgUrl" class="svg-image" alt="楼层平面图" />

        <!-- 图例 -->
        <div class="legend">
          <span><i class="dot leased"></i>已租</span>
          <span><i class="dot expiring"></i>即将到期</span>
          <span><i class="dot vacant"></i>空置</span>
          <span><i class="dot non-leasable"></i>非可租</span>
        </div>
      </div>
    </div>

    <!-- 单元详情弹窗 -->
    <el-dialog
      v-model="showUnitDialog"
      :title="`单元 ${selectedUnit?.unit_number ?? ''}`"
      width="420"
    >
      <el-descriptions v-if="selectedUnit" :column="1" border>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTag(selectedUnit.current_status)">
            {{ statusLabel(selectedUnit.current_status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="业态">
          {{ propertyTypeLabel(selectedUnit.property_type) }}
        </el-descriptions-item>
        <el-descriptions-item label="租户">
          {{ selectedUnit.tenant_name ?? '—' }}
        </el-descriptions-item>
        <el-descriptions-item label="合同到期日">
          {{ formatDate(selectedUnit.contract_end_date) }}
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="showUnitDialog = false">关闭</el-button>
        <el-button v-if="selectedUnit" type="primary" @click="goUnitDetail">
          查看详情
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import dayjs from 'dayjs'
import { useFloorMapStore } from '@/stores'
import type { HeatmapUnit, PropertyType, UnitStatus } from '@/types/asset'
import { API_FILES } from '@/constants/api_paths'

const store = useFloorMapStore()
const route = useRoute()
const router = useRouter()

const floorId = computed(() => route.params.floorId as string)
const buildingId = computed(() => route.params.buildingId as string)

const keyword = ref('')
const showUnitDialog = ref(false)
const selectedUnit = ref<HeatmapUnit | null>(null)

const currentPlanId = computed(() => store.plans.find((p) => p.is_current)?.id ?? '')

const filteredUnits = computed(() => {
  const all = store.heatmap?.units ?? []
  const k = keyword.value.trim().toLowerCase()
  if (!k) return all
  return all.filter((u) => u.unit_number.toLowerCase().includes(k))
})

const svgUrl = computed(() => {
  const p = store.heatmap?.svg_path
  return p ? `${API_FILES}/${p}` : ''
})

onMounted(() => {
  store.fetchMap(floorId.value)
})

watch(floorId, (id) => {
  if (id) store.fetchMap(id)
})

function goBack(): void {
  router.push({ name: 'building-detail', params: { id: buildingId.value } })
}

function onUnitRowClick(row: HeatmapUnit): void {
  selectedUnit.value = row
  showUnitDialog.value = true
}

function goUnitDetail(): void {
  if (!selectedUnit.value) return
  router.push({ name: 'unit-detail', params: { id: selectedUnit.value.unit_id } })
}

async function onChangePlan(planId: string): Promise<void> {
  try {
    await store.setCurrentPlan(planId)
  } catch {
    // 错误已写入 store.error
  }
}

function rowClass({ row }: { row: HeatmapUnit }): string {
  return `row-${row.current_status}`
}

function statusLabel(s: UnitStatus): string {
  return ({
    leased: '已租',
    vacant: '空置',
    expiring_soon: '即将到期',
    non_leasable: '非可租',
    renovating: '改造中',
    pre_lease: '预租',
  } as const)[s]
}

function statusTag(s: UnitStatus): 'success' | 'warning' | 'danger' | 'info' {
  switch (s) {
    case 'leased':
      return 'success'
    case 'expiring_soon':
    case 'renovating':
    case 'pre_lease':
      return 'warning'
    case 'vacant':
      return 'danger'
    case 'non_leasable':
    default:
      return 'info'
  }
}

function propertyTypeLabel(t: PropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓' } as const)[t]
}

function formatDate(v: string | null): string {
  return v ? dayjs(v).format('YYYY-MM-DD') : '—'
}
</script>

<style scoped>
.floor-plan { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.layout {
  display: flex;
  gap: 16px;
  margin-top: 16px;
  min-height: calc(100vh - 220px);
}
.unit-list {
  width: 320px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.list-header { font-size: 14px; font-weight: 600; padding: 4px 0; }
.svg-container {
  flex: 1;
  position: relative;
  background: var(--el-fill-color-lighter);
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 4px;
  overflow: auto;
  display: flex;
  align-items: center;
  justify-content: center;
}
.svg-image {
  max-width: 100%;
  max-height: 100%;
  display: block;
}
.empty {
  color: var(--el-text-color-secondary);
  padding: 60px 20px;
  text-align: center;
}
.legend {
  position: absolute;
  bottom: 12px;
  left: 12px;
  display: flex;
  gap: 16px;
  background: rgba(255, 255, 255, 0.92);
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
}
.legend .dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 2px;
  margin-right: 6px;
  vertical-align: middle;
}
.legend .leased { background: var(--el-color-success); }
.legend .expiring { background: var(--el-color-warning); }
.legend .vacant { background: var(--el-color-danger); }
.legend .non-leasable { background: var(--el-color-info); }
</style>
