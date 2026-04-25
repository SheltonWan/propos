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
      <el-descriptions-item label="建筑面积">
        {{ store.item ? `${formatArea(store.item.gfa)} m²` : '—' }}
      </el-descriptions-item>
      <el-descriptions-item label="净可租面积">
        {{ store.item ? `${formatArea(store.item.nla)} m²` : '—' }}
      </el-descriptions-item>
      <el-descriptions-item label="地址" :span="2">
        {{ store.item?.address ?? '—' }}
      </el-descriptions-item>
    </el-descriptions>

    <!-- 楼层列表 -->
    <el-card class="floors" header="楼层列表" shadow="never">
      <el-table
        v-loading="store.loading"
        :data="sortedFloors"
        stripe
        @row-click="goFloor"
      >
        <el-table-column label="楼层" width="120">
          <template #default="{ row }">{{ row.floor_name ?? `${row.floor_number}F` }}</template>
        </el-table-column>
        <el-table-column prop="floor_number" label="楼层号" width="120" align="right" />
        <el-table-column label="净可租面积 (m²)" min-width="160" align="right">
          <template #default="{ row }">{{ formatArea(row.nla) }}</template>
        </el-table-column>
        <el-table-column label="图纸状态" width="160">
          <template #default="{ row }">
            <el-tag v-if="row.svg_path" type="success">已上传</el-tag>
            <el-tag v-else type="info">未上传</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="goFloor(row)">查看热区图</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useBuildingDetailStore } from '@/stores'
import type { Floor, PropertyType } from '@/types/asset'

const store = useBuildingDetailStore()
const route = useRoute()
const router = useRouter()

const buildingId = computed(() => route.params.id as string)

const sortedFloors = computed(() =>
  [...store.floors].sort((a, b) => b.floor_number - a.floor_number),
)

onMounted(() => {
  store.fetchDetail(buildingId.value)
})

watch(buildingId, (id) => {
  if (id) store.fetchDetail(id)
})

function goBack(): void {
  router.push({ name: 'assets' })
}

function goFloor(row: Floor): void {
  router.push({
    name: 'floor-plan',
    params: { buildingId: row.building_id, floorId: row.id },
  })
}

function propertyTypeLabel(t: PropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓' } as const)[t]
}
function propertyTypeTag(t: PropertyType): 'primary' | 'success' | 'warning' {
  return ({ office: 'primary', retail: 'success', apartment: 'warning' } as const)[t]
}
function formatArea(v: number | null): string {
  if (v == null) return '—'
  return v.toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}
</script>

<style scoped>
.building-detail { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.info { margin-bottom: 24px; }
.floors :deep(.el-table) { cursor: pointer; }
</style>
