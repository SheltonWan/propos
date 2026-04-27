<template>
  <el-dialog
    v-model="visible"
    title="编辑楼栋"
    width="560px"
    :close-on-click-modal="false"
    @closed="handleClosed"
  >
    <el-form
      ref="formRef"
      :model="form"
      :rules="rules"
      label-width="140px"
      label-position="right"
    >
      <el-form-item label="楼栋名称" prop="name">
        <el-input v-model="form.name" placeholder="如：融创智汇大厦A座" maxlength="64" />
      </el-form-item>

      <el-form-item label="标签业态" prop="property_type">
        <el-select v-model="form.property_type" placeholder="请选择" style="width: 100%">
          <el-option label="写字楼 (office)" value="office" />
          <el-option label="商铺 (retail)" value="retail" />
          <el-option label="公寓 (apartment)" value="apartment" />
          <el-option label="综合体 (mixed) — 一栋楼多种业态" value="mixed" />
        </el-select>
        <div class="tip">仅作楼栋统计/筛选标签，不限制单元业态。</div>
      </el-form-item>

      <el-form-item label="地上层数" prop="total_floors">
        <el-input-number
          v-model="form.total_floors"
          :min="currentAbove"
          :max="200"
          :step="1"
          style="width: 100%"
        />
        <div class="tip">
          当前已存在 {{ currentAbove }} 个地上楼层。仅可增加，新增部分会自动创建 {{ currentAbove + 1 }}F ~ {{ form.total_floors }}F。<br />
          如需减少请先手动删除对应楼层及其下单元。
        </div>
      </el-form-item>

      <el-form-item label="地下层数" prop="basement_floors">
        <el-input-number
          v-model="form.basement_floors"
          :min="currentBelow"
          :max="20"
          :step="1"
          style="width: 100%"
        />
        <div class="tip">
          当前已存在 {{ currentBelow }} 个地下楼层。仅可增加，新增部分会自动创建 B{{ currentBelow + 1 }} ~ B{{ form.basement_floors }}。
        </div>
      </el-form-item>

      <el-form-item label="建筑面积 (m²)" prop="gfa">
        <el-input-number
          v-model="form.gfa"
          :min="0.01"
          :precision="2"
          :step="100"
          style="width: 100%"
        />
      </el-form-item>

      <el-form-item label="净可租面积 (m²)" prop="nla">
        <el-input-number
          v-model="form.nla"
          :min="0.01"
          :precision="2"
          :step="100"
          style="width: 100%"
        />
      </el-form-item>

      <el-form-item label="地址">
        <el-input v-model="form.address" placeholder="选填" maxlength="200" />
      </el-form-item>

      <el-form-item label="建成年份">
        <el-input-number
          v-model="form.built_year"
          :min="1900"
          :max="2100"
          :step="1"
          placeholder="选填"
          style="width: 100%"
        />
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="submitting" @click="onSubmit">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { fetchFloors, updateBuilding } from '@/api/modules/assets'
import { ApiError } from '@/types/api'
import type { Building, BuildingPropertyType } from '@/types/asset'

interface Props {
  modelValue: boolean
  building: Building | null
}
interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'updated'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const visible = ref(props.modelValue)
watch(
  () => props.modelValue,
  (v) => (visible.value = v),
)
watch(visible, (v) => emit('update:modelValue', v))

const formRef = ref<FormInstance>()
const submitting = ref(false)

interface FormState {
  name: string
  property_type: BuildingPropertyType
  total_floors: number
  basement_floors: number
  gfa: number
  nla: number
  address: string
  built_year: number | null
}

function defaultForm(): FormState {
  return {
    name: '',
    property_type: 'mixed',
    total_floors: 1,
    basement_floors: 0,
    gfa: 1000,
    nla: 800,
    address: '',
    built_year: null,
  }
}

const form = reactive<FormState>(defaultForm())

// 当前楼栋已有的地上/地下层数（用于提示 + 作为表单下限）
const currentAbove = ref(0)
const currentBelow = ref(0)

async function loadFloorCounts(buildingId: string): Promise<void> {
  try {
    const floors = await fetchFloors(buildingId)
    currentAbove.value = floors.filter((f) => f.floor_number > 0).length
    currentBelow.value = floors.filter((f) => f.floor_number < 0).length
  } catch {
    currentAbove.value = 0
    currentBelow.value = 0
  }
}

// 当父组件传入 building 时，回填表单 + 加载当前层数
watch(
  () => props.building,
  async (b) => {
    if (!b) return
    form.name = b.name
    form.property_type = b.property_type
    form.total_floors = b.total_floors
    // basement_floors 直接来自 API 字段（migration 025 新增），不再需要从 floors 表推断
    form.basement_floors = b.basement_floors
    form.gfa = b.gfa
    form.nla = b.nla
    form.address = b.address ?? ''
    form.built_year = b.built_year ?? null
    // 仍调用 fetchFloors 以获取 currentAbove/currentBelow，用于表单 :min 约束
    await loadFloorCounts(b.id)
    // 极少见情况：buildings 表字段与实际楼层行不一致，以实际为准
    if (form.total_floors < currentAbove.value) {
      form.total_floors = currentAbove.value
    }
    if (form.basement_floors < currentBelow.value) {
      form.basement_floors = currentBelow.value
    }
  },
  { immediate: true },
)

const rules: FormRules<FormState> = {
  name: [{ required: true, message: '请输入楼栋名称', trigger: 'blur' }],
  property_type: [{ required: true, message: '请选择标签业态', trigger: 'change' }],
  total_floors: [{ required: true, type: 'number', min: 1, max: 200, message: '地上层数 1-200', trigger: 'change' }],
  basement_floors: [{ required: true, type: 'number', min: 0, max: 20, message: '地下层数 0-20', trigger: 'change' }],
  gfa: [{ required: true, type: 'number', min: 0.01, message: '请填写建筑面积', trigger: 'blur' }],
  nla: [{ required: true, type: 'number', min: 0.01, message: '请填写净可租面积', trigger: 'blur' }],
}

async function onSubmit(): Promise<void> {
  if (!props.building) return
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  if (form.nla > form.gfa) {
    ElMessage.warning('净可租面积通常应不大于建筑面积，请确认后再提交')
    return
  }

  submitting.value = true
  try {
    await updateBuilding(props.building.id, {
      name: form.name.trim(),
      property_type: form.property_type,
      total_floors: form.total_floors,
      basement_floors: form.basement_floors,
      gfa: form.gfa,
      nla: form.nla,
      address: form.address.trim() || null,
      built_year: form.built_year,
    })
    ElMessage.success('楼栋已更新')
    visible.value = false
    emit('updated')
  } catch (e) {
    const msg = e instanceof ApiError ? e.message : '保存失败，请重试'
    ElMessage.error(msg)
  } finally {
    submitting.value = false
  }
}

function handleClosed(): void {
  formRef.value?.clearValidate()
}
</script>

<style scoped>
.tip {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  line-height: 1.4;
  margin-top: 4px;
}
</style>
