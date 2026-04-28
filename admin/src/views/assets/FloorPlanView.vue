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
        <el-button :icon="Upload" type="primary" @click="showUpload = true">
          上传新版本
        </el-button>
      </template>
    </el-page-header>

    <!-- 工具栏：业态筛选 + 缩放 + 重置 -->
    <div class="toolbar">
      <el-select
        v-model="propertyFilter"
        placeholder="业态筛选"
        style="width: 140px"
        clearable
      >
        <el-option label="全部" value="" />
        <el-option label="写字楼" value="office" />
        <el-option label="商铺" value="retail" />
        <el-option label="公寓" value="apartment" />
      </el-select>
      <el-button-group>
        <el-button :icon="ZoomIn" @click="zoom(0.2)" />
        <el-button :icon="ZoomOut" @click="zoom(-0.2)" />
        <el-button :icon="Refresh" @click="resetZoom" />
      </el-button-group>
      <span class="zoom-label">{{ Math.round(zoomLevel * 100) }}%</span>
    </div>

    <el-alert v-if="store.error" type="error" :title="store.error" show-icon :closable="false" />

    <div v-loading="store.loading" class="layout">
      <!-- 单元列表 -->
      <div class="unit-list">
        <div class="list-header">单元（{{ filteredUnits.length }}）</div>
        <el-input v-model="keyword" placeholder="搜索单元号" clearable size="default" />
        <el-table
          :data="filteredUnits"
          height="calc(100vh - 320px)"
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

      <!-- SVG 热区（内联渲染以支持点击） -->
      <div class="svg-container">
        <div v-if="!store.heatmap?.svg_path" class="empty">该楼层暂未上传图纸</div>
        <div
          v-else-if="svgContent"
          ref="svgWrapper"
          class="svg-wrapper"
          :style="{ transform: `scale(${zoomLevel})`, transformOrigin: 'top left' }"
          v-html="svgContent"
        />
        <div v-else class="empty">图纸加载中…</div>

        <!-- 图例 -->
        <div class="legend">
          <span><i class="dot leased" />已租</span>
          <span><i class="dot expiring" />即将到期</span>
          <span><i class="dot vacant" />空置</span>
          <span><i class="dot non-leasable" />非可租</span>
        </div>
      </div>
    </div>

    <!-- 单元详情侧边抽屉 -->
    <el-drawer
      v-model="showDrawer"
      :title="`单元 ${drawerStore.unit?.unit_number ?? selectedHeatmap?.unit_number ?? ''}`"
      size="360px"
      direction="rtl"
    >
      <div v-loading="drawerStore.loading" class="drawer-body">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="状态">
            <el-tag :type="statusTag(drawerUnit?.current_status ?? selectedHeatmap?.current_status ?? 'vacant')">
              {{ statusLabel(drawerUnit?.current_status ?? selectedHeatmap?.current_status ?? 'vacant') }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="业态">
            {{ propertyTypeLabel(drawerUnit?.property_type ?? selectedHeatmap?.property_type ?? 'office') }}
          </el-descriptions-item>
          <el-descriptions-item label="建筑面积">
            {{ drawerUnit?.gross_area != null ? `${drawerUnit.gross_area} m²` : '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="套内面积">
            {{ drawerUnit?.net_area != null ? `${drawerUnit.net_area} m²` : '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="租户">
            {{ drawerStore.contract?.tenant_name ?? selectedHeatmap?.tenant_name ?? '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="月租金">
            {{
              drawerStore.contract?.monthly_rent != null
                ? `¥${drawerStore.contract.monthly_rent.toLocaleString('zh-CN')}`
                : '—'
            }}
          </el-descriptions-item>
          <el-descriptions-item label="到期日">
            {{ formatDate(drawerStore.contract?.end_date ?? selectedHeatmap?.contract_end_date ?? null) }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button @click="showDrawer = false">关闭</el-button>
        <el-button type="primary" @click="goUnitDetail">查看详情</el-button>
        <el-button
          v-if="drawerUnit?.current_contract_id && M2_CONTRACT_ENABLED"
          type="success"
          @click="goContract"
        >
          查看合同
        </el-button>
      </template>
    </el-drawer>

    <!-- 上传新版图纸弹窗 -->
    <el-dialog v-model="showUpload" title="上传楼层图纸" width="520">
      <el-form label-width="120px">
        <el-form-item label="版本标签" required>
          <el-input
            v-model="uploadVersionLabel"
            placeholder="如：原始图纸、2026年改造后"
            maxlength="50"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="CAD 文件" required>
          <el-upload
            drag
            :auto-upload="false"
            :limit="1"
            accept=".svg,.dxf,.SVG,.DXF"
            :file-list="uploadFileList"
            :on-change="onUploadFileChange"
            :on-remove="onUploadFileRemove"
          >
            <el-icon class="upload-icon"><UploadFilled /></el-icon>
            <div class="upload-text">点击或拖拽上传 .svg 或 .dxf 文件</div>
            <template #tip>
              <div class="upload-tip">
                上传 SVG 直接生效；上传 DXF 将在后端转换后自动设为当前生效版本
              </div>
            </template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showUpload = false">取消</el-button>
        <el-button
          type="primary"
          :loading="uploading"
          :disabled="!canSubmitUpload"
          @click="onSubmitUpload"
        >
          上传
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import dayjs from 'dayjs'
import { ZoomIn, ZoomOut, Refresh, Upload, UploadFilled } from '@element-plus/icons-vue'
import { ElMessage, type UploadFile } from 'element-plus'
import { useFloorMapStore, useFloorUnitDrawerStore } from '@/stores'
import type { HeatmapUnit, PropertyType, UnitStatus } from '@/types/asset'
import { API_FILES } from '@/constants/api_paths'
import { M2_CONTRACT_ENABLED } from '@/constants/feature_flags'
import { apiGetRaw } from '@/api/client'

const store = useFloorMapStore()
const drawerStore = useFloorUnitDrawerStore()
const route = useRoute()
const router = useRouter()

const floorId = computed(() => route.params.floorId as string)
const buildingId = computed(() => route.params.buildingId as string)

const keyword = ref('')
const propertyFilter = ref<'' | PropertyType>('')
const showDrawer = ref(false)
const selectedHeatmap = ref<HeatmapUnit | null>(null)
const svgContent = ref<string>('')
const svgWrapper = ref<HTMLElement | null>(null)
const zoomLevel = ref(1)

// ── 上传新版图纸状态 ─────────────────────────────────
const showUpload = ref(false)
const uploading = ref(false)
const uploadVersionLabel = ref<string>('')
const uploadFile = ref<File | null>(null)
const uploadFileList = ref<UploadFile[]>([])

const canSubmitUpload = computed<boolean>(
  () => uploadFile.value != null && uploadVersionLabel.value.trim().length > 0,
)

const drawerUnit = computed(() => drawerStore.unit)

const currentPlanId = computed(() => store.plans.find((p) => p.is_current)?.id ?? '')

const filteredUnits = computed(() => {
  const all = store.heatmap?.units ?? []
  const k = keyword.value.trim().toLowerCase()
  return all.filter((u) => {
    if (propertyFilter.value && u.property_type !== propertyFilter.value) return false
    if (k && !u.unit_number.toLowerCase().includes(k)) return false
    return true
  })
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

// 当 SVG 路径就绪时获取文本内容并注入；同时根据单元状态着色 + 绑定点击
watch(
  svgUrl,
  async (url) => {
    if (!url) {
      svgContent.value = ''
      return
    }
    try {
      // 通过统一 axios 实例 + apiGetRaw 拉取 SVG 文本，复用鉴权 / refresh 拦截器
      const text = await apiGetRaw<string>(url, { responseType: 'text' })
      svgContent.value = text
      await nextTick()
      applyHeatmapStyles()
    } catch {
      svgContent.value = ''
    }
  },
  { immediate: true },
)

// 当 heatmap units 更新时也重新着色
watch(
  () => store.heatmap?.units,
  async () => {
    if (svgContent.value) {
      await nextTick()
      applyHeatmapStyles()
    }
  },
)

function applyHeatmapStyles(): void {
  const wrapper = svgWrapper.value
  if (!wrapper) return
  const units = store.heatmap?.units ?? []
  const byUnitId: Record<string, HeatmapUnit> = {}
  const byUnitNumber: Record<string, HeatmapUnit> = {}
  for (const u of units) {
    byUnitId[u.unit_id] = u
    byUnitNumber[u.unit_number] = u
  }
  // SVG 中 polygon/rect 元素一般以 data-unit-id 或 id 标识单元
  const candidates = wrapper.querySelectorAll<SVGGraphicsElement>(
    '[data-unit-id], [data-unit-number], polygon[id], rect[id], path[id]',
  )
  candidates.forEach((el) => {
    const unitId = el.getAttribute('data-unit-id')
    const unitNumber = el.getAttribute('data-unit-number') ?? el.getAttribute('id')
    const u =
      (unitId ? byUnitId[unitId] : null) ??
      (unitNumber ? byUnitNumber[unitNumber] : null)
    if (!u) return
    const color = statusFillColor(u.current_status)
    el.setAttribute('fill', color)
    el.setAttribute('fill-opacity', '0.55')
    el.setAttribute('stroke', 'rgba(0,0,0,0.4)')
    el.style.cursor = 'pointer'
    el.addEventListener('click', () => onUnitRowClick(u))
  })
}

function onUnitRowClick(row: HeatmapUnit): void {
  selectedHeatmap.value = row
  showDrawer.value = true
  drawerStore.reset()
  drawerStore.load(row.unit_id)
}

function goUnitDetail(): void {
  const id = drawerUnit.value?.id ?? selectedHeatmap.value?.unit_id
  if (id) {
    router.push({ name: 'unit-detail', params: { id } })
  }
}

function goContract(): void {
  const cid = drawerUnit.value?.current_contract_id
  if (cid) {
    router.push({ name: 'contract-detail', params: { id: cid } })
  }
}

async function onChangePlan(planId: string): Promise<void> {
  try {
    await store.setCurrentPlan(planId)
  } catch {
    // 错误已写入 store.error
  }
}

function onUploadFileChange(file: UploadFile): void {
  if (file.raw) {
    uploadFile.value = file.raw as File
    uploadFileList.value = [file]
  }
}

function onUploadFileRemove(): void {
  uploadFile.value = null
  uploadFileList.value = []
}

async function onSubmitUpload(): Promise<void> {
  if (!uploadFile.value || !uploadVersionLabel.value.trim()) return
  uploading.value = true
  try {
    await store.uploadCad(uploadFile.value, uploadVersionLabel.value.trim())
    ElMessage.success('图纸已上传，后端正在转换中')
    showUpload.value = false
    uploadFile.value = null
    uploadFileList.value = []
    uploadVersionLabel.value = ''
  } catch {
    // 错误已写入 store.error
  } finally {
    uploading.value = false
  }
}

function zoom(delta: number): void {
  const next = Math.max(0.4, Math.min(2.5, zoomLevel.value + delta))
  zoomLevel.value = Number(next.toFixed(2))
}

function resetZoom(): void {
  zoomLevel.value = 1
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

function statusFillColor(s: UnitStatus): string {
  switch (s) {
    case 'leased':
      return 'var(--el-color-success)'
    case 'expiring_soon':
    case 'renovating':
    case 'pre_lease':
      return 'var(--el-color-warning)'
    case 'vacant':
      return 'var(--el-color-danger)'
    case 'non_leasable':
    default:
      return 'var(--el-color-info)'
  }
}

function propertyTypeLabel(t: PropertyType): string {
  return ({ office: '写字楼', retail: '商铺', apartment: '公寓', mixed: '综合体' } as const)[t]
}

function formatDate(v: string | null): string {
  return v ? dayjs(v).format('YYYY-MM-DD') : '—'
}

function goBack(): void {
  router.push({ name: 'building-detail', params: { id: buildingId.value } })
}
</script>

<style scoped>
.floor-plan { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}
.zoom-label {
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.layout {
  display: flex;
  gap: 16px;
  margin-top: 16px;
  min-height: calc(100vh - 280px);
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
  padding: 16px;
}
.svg-wrapper {
  display: inline-block;
  transition: transform 0.15s ease;
}
.svg-wrapper :deep(svg) {
  max-width: 100%;
  height: auto;
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
.drawer-body {
  padding: 8px 4px;
}
.upload-icon { font-size: 48px; color: var(--el-color-primary); }
.upload-text { color: var(--el-text-color-regular); margin-top: 8px; font-size: 14px; }
.upload-tip { color: var(--el-text-color-secondary); font-size: 12px; }
</style>
