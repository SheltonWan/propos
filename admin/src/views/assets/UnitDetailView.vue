<template>
  <div class="unit-detail">
    <el-page-header class="header" @back="goBack">
      <template #content>
        <span class="title">
          {{ store.item ? `${store.item.building_name ?? ''} · ${store.item.unit_number}` : '房源详情' }}
        </span>
      </template>
      <template #extra>
        <el-button :icon="Edit" :disabled="!store.item" @click="openEdit">编辑</el-button>
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

      <!-- 当前租赁 -->
      <el-card
        v-if="store.item?.current_contract_id"
        class="block"
        shadow="never"
      >
        <template #header>
          <div class="card-header">
            <span>当前租赁</span>
            <el-button type="primary" link @click="goContract">查看合同详情 →</el-button>
          </div>
        </template>
        <el-descriptions :column="3" border>
          <el-descriptions-item label="合同编号">
            {{ store.currentContract?.contract_number ?? store.item.current_contract_id.slice(0, 8) }}
          </el-descriptions-item>
          <el-descriptions-item label="租户">
            {{ store.currentContract?.tenant_name ?? '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="月租金">
            {{
              store.currentContract?.monthly_rent != null
                ? `¥${store.currentContract.monthly_rent.toLocaleString('zh-CN')}`
                : '—'
            }}
          </el-descriptions-item>
          <el-descriptions-item label="起始日">
            {{ formatDate(store.currentContract?.start_date ?? null) }}
          </el-descriptions-item>
          <el-descriptions-item label="到期日">
            {{ formatDate(store.currentContract?.end_date ?? null) }}
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            {{ store.currentContract?.status ?? '—' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 改造记录 -->
      <el-card class="block" shadow="never">
        <template #header>
          <div class="card-header">
            <span>改造记录</span>
            <el-button type="primary" :icon="Plus" @click="openRenovation">新增改造</el-button>
          </div>
        </template>
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

    <!-- 编辑单元弹窗 -->
    <el-dialog v-model="showEdit" title="编辑房源" width="560">
      <el-form ref="editFormRef" :model="editForm" label-width="120px">
        <el-form-item label="装修状态">
          <el-select v-model="editForm.decoration_status" style="width: 100%">
            <el-option label="毛坯" value="blank" />
            <el-option label="原始" value="raw" />
            <el-option label="简装" value="simple" />
            <el-option label="精装" value="refined" />
          </el-select>
        </el-form-item>
        <el-form-item label="朝向">
          <el-select v-model="editForm.orientation" clearable style="width: 100%">
            <el-option label="东" value="east" />
            <el-option label="南" value="south" />
            <el-option label="西" value="west" />
            <el-option label="北" value="north" />
          </el-select>
        </el-form-item>
        <el-form-item label="层高 (m)">
          <el-input-number v-model="editForm.ceiling_height" :min="0" :precision="2" :step="0.1" />
        </el-form-item>
        <el-form-item label="参考市场租金">
          <el-input-number
            v-model="editForm.market_rent_reference"
            :min="0"
            :precision="2"
            :step="1"
          />
          <span class="form-suffix">元 / m² / 月</span>
        </el-form-item>
        <el-form-item label="可租赁">
          <el-switch v-model="editForm.is_leasable" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEdit = false">取消</el-button>
        <el-button type="primary" :loading="store.saving" @click="onSubmitEdit">保存</el-button>
      </template>
    </el-dialog>

    <!-- 新增改造记录弹窗 -->
    <el-dialog v-model="showRenovation" title="新增改造记录" width="560">
      <el-form ref="renovationFormRef" :model="renovationForm" :rules="renovationRules" label-width="120px">
        <el-form-item label="改造类型" prop="renovation_type">
          <el-input v-model="renovationForm.renovation_type" placeholder="如：精装修改造、空调更换" />
        </el-form-item>
        <el-form-item label="开始日期" prop="started_at">
          <el-date-picker
            v-model="renovationForm.started_at"
            type="date"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="完成日期">
          <el-date-picker
            v-model="renovationForm.completed_at"
            type="date"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="造价 (元)">
          <el-input-number v-model="renovationForm.cost" :min="0" :precision="2" :step="100" />
        </el-form-item>
        <el-form-item label="施工方">
          <el-input v-model="renovationForm.contractor" />
        </el-form-item>
        <el-form-item label="说明">
          <el-input v-model="renovationForm.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRenovation = false">取消</el-button>
        <el-button type="primary" :loading="store.saving" @click="onSubmitRenovation">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import dayjs from 'dayjs'
import { Edit, Plus } from '@element-plus/icons-vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { useUnitDetailStore } from '@/stores'
import type {
  DecorationStatus,
  Orientation,
  PropertyType,
  RenovationCreateRequest,
  UnitStatus,
  UnitUpdateRequest,
} from '@/types/asset'

const store = useUnitDetailStore()
const route = useRoute()
const router = useRouter()

const unitId = computed(() => route.params.id as string)

// ── 编辑表单 ─────────────────────────────────────────
const showEdit = ref(false)
const editFormRef = ref<FormInstance>()
const editForm = reactive<UnitUpdateRequest>({
  decoration_status: 'blank',
  orientation: null,
  ceiling_height: null,
  market_rent_reference: null,
  is_leasable: true,
})

function openEdit(): void {
  if (!store.item) return
  editForm.decoration_status = store.item.decoration_status
  editForm.orientation = store.item.orientation
  editForm.ceiling_height = store.item.ceiling_height
  editForm.market_rent_reference = store.item.market_rent_reference
  editForm.is_leasable = store.item.is_leasable
  showEdit.value = true
}

async function onSubmitEdit(): Promise<void> {
  if (!unitId.value) return
  try {
    await store.updateUnit(unitId.value, { ...editForm })
    ElMessage.success('房源信息已更新')
    showEdit.value = false
  } catch {
    // 错误已写入 store.error，由顶部 alert 展示
  }
}

// ── 新增改造记录表单 ─────────────────────────────────
const showRenovation = ref(false)
const renovationFormRef = ref<FormInstance>()
const renovationForm = reactive<RenovationCreateRequest>({
  unit_id: '',
  renovation_type: '',
  started_at: '',
  completed_at: null,
  cost: null,
  contractor: null,
  description: null,
})

const renovationRules: FormRules = {
  renovation_type: [{ required: true, message: '请输入改造类型', trigger: 'blur' }],
  started_at: [{ required: true, message: '请选择开始日期', trigger: 'change' }],
}

function openRenovation(): void {
  renovationForm.unit_id = unitId.value
  renovationForm.renovation_type = ''
  renovationForm.started_at = dayjs().format('YYYY-MM-DD')
  renovationForm.completed_at = null
  renovationForm.cost = null
  renovationForm.contractor = null
  renovationForm.description = null
  showRenovation.value = true
}

async function onSubmitRenovation(): Promise<void> {
  if (!renovationFormRef.value) return
  await renovationFormRef.value.validate(async (valid) => {
    if (!valid) return
    try {
      await store.addRenovation({ ...renovationForm })
      ElMessage.success('改造记录已新增')
      showRenovation.value = false
    } catch {
      // 错误已写入 store.error
    }
  })
}

// ── 业态扩展字段 ─────────────────────────────────────
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
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.form-suffix {
  margin-left: 8px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
</style>
