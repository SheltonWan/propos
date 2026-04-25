<template>
  <div class="assets-view">
    <div class="page-header">
      <h2 class="page-title">资产管理</h2>
      <div class="actions">
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
          <div class="stat-value">{{ stat.total }} 套</div>
          <div class="stat-sub">
            出租率
            <span class="stat-rate">{{ formatRate(stat.occupancy_rate) }}</span>
            （已租 {{ stat.leased }} / 空置 {{ stat.vacant }}）
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
      <el-descriptions :column="4" border>
        <el-descriptions-item label="总单元数">{{ store.overview.total_units }}</el-descriptions-item>
        <el-descriptions-item label="已租">{{ store.overview.total_leased }}</el-descriptions-item>
        <el-descriptions-item label="空置">{{ store.overview.total_vacant }}</el-descriptions-item>
        <el-descriptions-item label="整体出租率">
          {{ formatRate(store.overview.occupancy_rate) }}
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
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="goBuilding(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Upload, Download } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useAssetOverviewStore } from '@/stores'
import type { Building, PropertyType } from '@/types/asset'

const store = useAssetOverviewStore()
const router = useRouter()
const exporting = ref(false)

const propertyTypeStats = computed(() => store.overview?.by_property_type ?? [])

onMounted(() => {
  store.fetchAll()
})

function goBuilding(row: Building): void {
  router.push({ name: 'building-detail', params: { id: row.id } })
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

function propertyTypeLabel(t: PropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓' } as const)[t]
}

function propertyTypeTag(t: PropertyType): 'primary' | 'success' | 'warning' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning' } as const)[t]
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
  if (rate >= 0.7) return 'var(--el-color-primary)'
  if (rate >= 0.5) return 'var(--el-color-warning)'
  return 'var(--el-color-danger)'
}
</script>

<style scoped>
.assets-view { padding: 24px; }
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 0 0 16px;
}
.page-title { margin: 0; font-size: 20px; }
.actions { display: flex; gap: 8px; }
.stat-row { margin-bottom: 24px; }
.stat-card { height: 100%; }
.stat-title { font-size: 14px; color: var(--el-text-color-regular); }
.stat-value { font-size: 28px; font-weight: 600; margin: 8px 0 4px; }
.stat-sub { font-size: 12px; color: var(--el-text-color-secondary); margin-bottom: 12px; }
.stat-rate { color: var(--el-color-primary); font-weight: 600; }
.total-card { margin-bottom: 24px; }
.buildings-card :deep(.el-table) { cursor: pointer; }
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
