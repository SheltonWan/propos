<template>
  <el-dialog
    v-model="visible"
    title="新建楼栋"
    width="560px"
    :close-on-click-modal="false"
    @closed="handleClosed"
  >
    <el-form
      ref="formRef"
      :model="form"
      :rules="rules"
      label-width="120px"
      label-position="right"
    >
      <el-form-item label="楼栋名称" prop="name">
        <el-input v-model="form.name" placeholder="如：融创智汇大厦A座" maxlength="64" />
      </el-form-item>

      <el-form-item label="主业态" prop="property_type">
        <el-select v-model="form.property_type" placeholder="请选择" style="width: 100%">
          <el-option label="写字楼 (office)" value="office" />
          <el-option label="商铺 (retail)" value="retail" />
          <el-option label="公寓 (apartment)" value="apartment" />
        </el-select>
        <div class="tip">
          综合体（多业态混合）请选「写字楼」作为主业态；具体业态在导入单元时按行指定。
        </div>
      </el-form-item>

      <el-form-item label="总楼层数" prop="total_floors">
        <el-input-number
          v-model="form.total_floors"
          :min="1"
          :max="200"
          :step="1"
          style="width: 100%"
        />
        <div class="tip">提交后将自动创建 1F ~ {{ form.total_floors }}F 共 {{ form.total_floors }} 个楼层。</div>
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
      <el-button type="primary" :loading="submitting" @click="onSubmit">
        创建楼栋及 {{ form.total_floors }} 个楼层
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { createBuildingWithFloors } from '@/api/modules/assets'
import { ApiError } from '@/types/api'

interface Props {
  modelValue: boolean
}
interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'created'): void
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
  property_type: 'office' | 'retail' | 'apartment'
  total_floors: number
  gfa: number
  nla: number
  address: string
  built_year: number | null
}

function defaultForm(): FormState {
  return {
    name: '',
    property_type: 'office',
    total_floors: 1,
    gfa: 1000,
    nla: 800,
    address: '',
    built_year: null,
  }
}

const form = reactive<FormState>(defaultForm())

const rules: FormRules<FormState> = {
  name: [{ required: true, message: '请输入楼栋名称', trigger: 'blur' }],
  property_type: [{ required: true, message: '请选择主业态', trigger: 'change' }],
  total_floors: [{ required: true, type: 'number', min: 1, max: 200, message: '总楼层数 1-200', trigger: 'change' }],
  gfa: [{ required: true, type: 'number', min: 0.01, message: '请填写建筑面积', trigger: 'blur' }],
  nla: [{ required: true, type: 'number', min: 0.01, message: '请填写净可租面积', trigger: 'blur' }],
}

async function onSubmit(): Promise<void> {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  if (form.nla > form.gfa) {
    ElMessage.warning('净可租面积通常应不大于建筑面积，请确认后再提交')
    return
  }

  submitting.value = true
  try {
    const result = await createBuildingWithFloors({
      name: form.name.trim(),
      property_type: form.property_type,
      total_floors: form.total_floors,
      gfa: form.gfa,
      nla: form.nla,
      address: form.address.trim() || null,
      built_year: form.built_year,
    })
    ElMessage.success(
      `已创建楼栋「${result.building.name}」及 ${result.floors.length} 个楼层`,
    )
    visible.value = false
    emit('created')
  } catch (e) {
    const msg = e instanceof ApiError ? e.message : '创建失败，请重试'
    ElMessage.error(msg)
  } finally {
    submitting.value = false
  }
}

function handleClosed(): void {
  // 关闭时重置表单
  Object.assign(form, defaultForm())
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
