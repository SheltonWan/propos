<template>
  <div class="assets-view">
    <div class="page-header">
      <h2 class="page-title">资产管理</h2>
      <div class="actions">
        <el-button :icon="Plus" type="primary" @click="showCreate = true">新建楼栋</el-button>
        <el-button :icon="Upload" @click="goImport">批量导入</el-button>
        <el-button :icon="Download" :loading="exporting" @click="onExport">导出 Excel</el-button>
      </div>
    </div>

    <el-alert v-if="store.error" type="error" :title="store.error" show-icon :closable="false" />

    <!-- ① 三业态统计卡片 -->
    <el-row v-loading="store.loading" :gutter="24" class="stat-row">
      <el-col v-for="stat in propertyTypeStats" :key="stat.property_type" :span="8">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-title">{{ propertyTypeLabel(stat.property_type) }}</div>
          <div class="stat-value">{{ stat.total_units }} 套</div>
          <div class="stat-sub">
            出租率
            <span class="stat-rate">{{ formatRate(stat.occupancy_rate) }}</span>
            （已租 {{ stat.leased_units }} / 空置 {{ stat.vacant_units }} / 即将到期 {{ stat.expiring_soon_units }}）
          </div>
          <el-progress
            :percentage="Math.round(stat.occupancy_rate * 100)"
            :stroke-width="8"
            :show-text="false"
            :color="rateColor(stat.occupancy_rate)"
          />
        </el-card>
      </el-col>
    </el-row>

    <!-- ② 总计 -->
    <el-card v-if="store.overview" class="total-card" shadow="never">
      <el-descriptions :column="5" border>
        <el-descriptions-item label="总单元数">{{ store.overview.total_units }}</el-descriptions-item>
        <el-descriptions-item label="可租套数">{{ store.overview.total_leasable_units }}</el-descriptions-item>
        <el-descriptions-item label="整体出租率">
          {{ formatRate(store.overview.total_occupancy_rate) }}
        </el-descriptions-item>
        <el-descriptions-item label="WALE（收入加权）">
          {{ store.overview.wale_income_weighted.toFixed(2) }} 年
        </el-descriptions-item>
        <el-descriptions-item label="WALE（面积加权）">
          {{ store.overview.wale_area_weighted.toFixed(2) }} 年
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- ③ 楼栋列表 -->
    <el-card class="buildings-card" header="楼栋列表" shadow="never">
      <el-table v-loading="store.loading" :data="store.list" stripe @row-click="goBuilding">
        <el-table-column prop="name" label="楼栋名称" min-width="160" />
        <el-table-column label="主业态" width="120">
          <template #default="{ row }">
            <el-tag :type="propertyTypeTag(row.property_type)">
              {{ propertyTypeLabel(row.property_type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="total_floors" label="总层数" width="100" align="right" />
        <el-table-column label="建筑面积 (m²)" width="140" align="right">
          <template #default="{ row }">{{ formatArea(row.gfa) }}</template>
        </el-table-column>
        <el-table-column label="净可租面积 (m²)" width="140" align="right">
          <template #default="{ row }">{{ formatArea(row.nla) }}</template>
        </el-table-column>
        <el-table-column label="出租率" min-width="220">
          <template #default="{ row }">
            <div class="rate-cell">
              <el-progress
                :percentage="ratePct(store.buildingOccupancy[row.id]?.rate ?? 0)"
                :color="rateColor(store.buildingOccupancy[row.id]?.rate ?? 0)"
                :stroke-width="10"
                :show-text="false"
                style="flex: 1"
              />
              <span class="rate-text">{{ formatRate(store.buildingOccupancy[row.id]?.rate ?? 0) }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="address" label="地址" min-width="180" show-overflow-tooltip />
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="goBuilding(row)">详情</el-button>
            <el-button type="primary" link @click.stop="openEdit(row)">编辑</el-button>
            <el-button type="danger" link :loading="deletingId === row.id" @click.stop="onDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <BuildingCreateDialog v-model="showCreate" @created="store.fetchAll()" />
    <BuildingEditDialog v-model="showEdit" :building="editingBuilding" @updated="store.fetchAll()" />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Upload, Download, Plus } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAssetOverviewStore } from '@/stores'
import { deleteBuilding } from '@/api/modules/assets'
import { ApiError } from '@/types/api'
import type { Building, BuildingPropertyType } from '@/types/asset'
import BuildingCreateDialog from './components/BuildingCreateDialog.vue'
import BuildingEditDialog from './components/BuildingEditDialog.vue'

const store = useAssetOverviewStore()
const router = useRouter()
const exporting = ref(false)
const showCreate = ref(false)
const showEdit = ref(false)
const editingBuilding = ref<Building | null>(null)
const deletingId = ref<string | null>(null)

const propertyTypeStats = computed(() => store.overview?.by_property_type ?? [])

onMounted(() => {
  store.fetchAll()
})

function goBuilding(row: Building): void {
  router.push({ name: 'building-detail', params: { id: row.id } })
}

function openEdit(row: Building): void {
  editingBuilding.value = row
  showEdit.value = true
}

async function onDelete(row: Building): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确定删除楼栋「${row.name}」吗？同时会删除该楼栋下的所有楼层及图纸。\n\n该操作不可逆。仅未关联单元/工单/账单的楼栋可删除。`,
      '删除确认',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return // 用户取消
  }
  deletingId.value = row.id
  try {
    await deleteBuilding(row.id)
    ElMessage.success(`楼栋「${row.name}」已删除`)
    await store.fetchAll()
  } catch (e) {
    const msg = e instanceof ApiError ? e.message : '删除失败，请重试'
    ElMessage.error(msg)
  } finally {
    deletingId.value = null
  }
}

function goImport(): void {
  router.push({ name: 'unit-import' })
}

async function onExport(): Promise<void> {
  exporting.value = true
  try {
    await store.exportUnits()
    ElMessage.success('导出已开始下载')
  } catch {
    // 错误已写入 store.error
  } finally {
    exporting.value = false
  }
}

function propertyTypeLabel(t: BuildingPropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓', mixed: '综合体' } as const)[t]
}

function propertyTypeTag(t: BuildingPropertyType): 'primary' | 'success' | 'warning' | 'info' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning', mixed: 'info' } as const)[t]
}

function formatRate(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`
}

function ratePct(rate: number): number {
  return Math.round(rate * 100)
}

function formatArea(v: number | null): string {
  if (v == null) return '—'
  return v.toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}

function rateColor(rate: number): string {
  if (rate >= 0.9) return 'var(--el-color-success)'
  if (rate >= 0.7) return 'var(--apple-blue)'
  if (rate >= 0.5) return 'var(--el-color-warning)'
  return 'var(--el-color-danger)'
}
</script>

<style scoped>
.assets-view { padding: 24px 28px; }

/* 页头 */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin: 0 0 24px;
}

.page-title {
  font-family: var(--apple-font-display);
  font-size: 26px;
  font-weight: 600;
  letter-spacing: -0.5px;
  color: var(--apple-near-black);
  margin: 0;
}

.actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

/* 统计行 */
.stat-row { margin-bottom: 20px; }

.stat-card { height: 100%; }

.stat-title {
  font-size: 11px;
  font-weight: 600;
  color: var(--apple-text-secondary);
  letter-spacing: 0.06em;
  text-transform: uppercase;
  margin-bottom: 8px;
}

.stat-value {
  font-family: var(--apple-font-display);
  font-size: 32px;
  font-weight: 600;
  letter-spacing: -0.5px;
  color: var(--apple-near-black);
  margin-bottom: 6px;
}

.stat-sub {
  font-size: 12px;
  color: var(--apple-text-secondary);
  margin-bottom: 12px;
  letter-spacing: -0.1px;
}

.stat-rate {
  color: var(--apple-blue);
  font-weight: 600;
}

/* 汇总卡片 */
.total-card { margin-bottom: 20px; }

/* 楼栋表格 */
.buildings-card :deep(.el-table) { cursor: pointer; }

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
