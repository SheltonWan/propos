<template>
  <div class="unit-detail">
    <el-page-header class="header" @back="goBack">
      <template #content>
        <span class="title">
          {{ store.item ? `${store.item.building_name ?? ''} · ${store.item.unit_number}` : '房源详情' }}
        </span>
      </template>
    </el-page-header>

    <el-alert v-if="store.error" type="error" :title="store.error" show-icon :closable="false" />

    <div v-loading="store.loading">
      <!-- 状态条 -->
      <div v-if="store.item" class="status-bar">
        <el-tag :type="statusTag(store.item.current_status)" size="large">
          {{ statusLabel(store.item.current_status) }}
        </el-tag>
        <el-tag :type="propertyTypeTag(store.item.property_type)" size="large">
          {{ propertyTypeLabel(store.item.property_type) }}
        </el-tag>
        <el-tag v-if="store.item.archived_at" type="info" size="large">已归档</el-tag>
      </div>

      <!-- 基本信息 -->
      <el-descriptions class="block" :column="2" border title="基本信息">
        <el-descriptions-item label="单元编号">{{ store.item?.unit_number ?? '—' }}</el-descriptions-item>
        <el-descriptions-item label="楼层">
          {{ store.item?.floor_name ?? '—' }}
        </el-descriptions-item>
        <el-descriptions-item label="建筑面积">
          {{ formatArea(store.item?.gross_area) }} m²
        </el-descriptions-item>
        <el-descriptions-item label="套内面积">
          {{ formatArea(store.item?.net_area) }} m²
        </el-descriptions-item>
        <el-descriptions-item label="朝向">
          {{ orientationLabel(store.item?.orientation ?? null) }}
        </el-descriptions-item>
        <el-descriptions-item label="层高">
          {{ store.item?.ceiling_height != null ? `${store.item.ceiling_height} m` : '—' }}
        </el-descriptions-item>
        <el-descriptions-item label="装修状态">
          {{ decorationLabel(store.item?.decoration_status ?? 'blank') }}
        </el-descriptions-item>
        <el-descriptions-item label="参考市场租金">
          {{
            store.item?.market_rent_reference != null
              ? `¥${store.item.market_rent_reference}/m²/月`
              : '—'
          }}
        </el-descriptions-item>
        <el-descriptions-item label="可租赁">
          <el-tag :type="store.item?.is_leasable ? 'success' : 'info'">
            {{ store.item?.is_leasable ? '可租' : '不可租' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="前序单元">
          {{
            store.item && store.item.predecessor_unit_ids.length > 0
              ? store.item.predecessor_unit_ids.join('、')
              : '—'
          }}
        </el-descriptions-item>
      </el-descriptions>

      <!-- 业态扩展字段 -->
      <el-descriptions
        v-if="extFieldsList.length > 0"
        class="block"
        :column="2"
        border
        title="业态扩展信息"
      >
        <el-descriptions-item v-for="kv in extFieldsList" :key="kv.key" :label="kv.key">
          {{ kv.value }}
        </el-descriptions-item>
      </el-descriptions>

      <!-- 当前合同 -->
      <el-card
        v-if="store.item?.current_contract_id"
        class="block"
        shadow="never"
        header="当前合同"
      >
        <el-button type="primary" link @click="goContract">
          查看合同 #{{ store.item.current_contract_id.slice(0, 8) }}
        </el-button>
      </el-card>

      <!-- 改造记录 -->
      <el-card class="block" shadow="never" header="改造记录">
        <el-table :data="store.renovations" stripe>
          <el-table-column prop="renovation_type" label="改造类型" min-width="160" />
          <el-table-column label="开始日期" width="140">
            <template #default="{ row }">{{ formatDate(row.started_at) }}</template>
          </el-table-column>
          <el-table-column label="完成日期" width="140">
            <template #default="{ row }">{{ formatDate(row.completed_at) }}</template>
          </el-table-column>
          <el-table-column label="造价 (元)" width="140" align="right">
            <template #default="{ row }">
              {{ row.cost != null ? row.cost.toLocaleString('zh-CN') : '—' }}
            </template>
          </el-table-column>
          <el-table-column prop="contractor" label="施工方" min-width="160" />
          <el-table-column prop="description" label="说明" min-width="200" show-overflow-tooltip />
          <template #empty>暂无改造记录</template>
        </el-table>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import dayjs from 'dayjs'
import { useUnitDetailStore } from '@/stores'
import type {
  DecorationStatus,
  Orientation,
  PropertyType,
  UnitStatus,
} from '@/types/asset'

const store = useUnitDetailStore()
const route = useRoute()
const router = useRouter()

const unitId = computed(() => route.params.id as string)

const extFieldsList = computed(() => {
  const ext = store.item?.ext_fields ?? {}
  return Object.entries(ext)
    .filter(([k]) => k !== 'svg_polygon' && k !== 'svg_coords')
    .map(([key, value]) => ({ key, value: String(value ?? '—') }))
})

onMounted(() => {
  store.fetchDetail(unitId.value)
})

watch(unitId, (id) => {
  if (id) store.fetchDetail(id)
})

function goBack(): void {
  router.back()
}

function goContract(): void {
  if (store.item?.current_contract_id) {
    router.push({ name: 'contract-detail', params: { id: store.item.current_contract_id } })
  }
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
function propertyTypeTag(t: PropertyType): 'primary' | 'success' | 'warning' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning' } as const)[t]
}
function decorationLabel(d: DecorationStatus): string {
  return ({ blank: '毛坯', simple: '简装', refined: '精装', raw: '原始' } as const)[d]
}
function orientationLabel(o: Orientation | null): string {
  if (o == null) return '—'
  return ({ east: '东', south: '南', west: '西', north: '北' } as const)[o]
}
function formatArea(v: number | null | undefined): string {
  if (v == null) return '—'
  return v.toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}
function formatDate(v: string | null): string {
  return v ? dayjs(v).format('YYYY-MM-DD') : '—'
}
</script>

<style scoped>
.unit-detail { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.status-bar { display: flex; gap: 12px; margin-bottom: 16px; }
.block { margin-bottom: 24px; }
</style>
