<template>
  <div class="ext-fields-form">
    <!-- 写字楼 -->
    <template v-if="propertyType === 'office'">
      <el-form-item label="工位数">
        <el-input-number
          v-model="officeFields.workstation_count"
          :min="0"
          :precision="0"
          :step="1"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="分隔间数">
        <el-input-number
          v-model="officeFields.partition_count"
          :min="0"
          :precision="0"
          :step="1"
          style="width: 100%"
        />
      </el-form-item>
    </template>

    <!-- 商铺 -->
    <template v-else-if="propertyType === 'retail'">
      <el-form-item label="门面宽度 (m)">
        <el-input-number
          v-model="retailFields.frontage_width"
          :min="0"
          :precision="2"
          :step="0.1"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="是否临街">
        <el-switch v-model="retailFields.street_facing" />
      </el-form-item>
      <el-form-item label="商铺层高 (m)">
        <el-input-number
          v-model="retailFields.retail_ceiling_height"
          :min="0"
          :precision="2"
          :step="0.1"
          style="width: 100%"
        />
      </el-form-item>
    </template>

    <!-- 公寓 -->
    <template v-else-if="propertyType === 'apartment'">
      <el-form-item label="卧室数">
        <el-input-number
          v-model="apartmentFields.bedroom_count"
          :min="0"
          :precision="0"
          :step="1"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="独立卫生间">
        <el-switch v-model="apartmentFields.en_suite_bathroom" />
      </el-form-item>
    </template>
  </div>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'
import type {
  ApartmentExtFields,
  OfficeExtFields,
  PropertyType,
  RetailExtFields,
} from '@/types/asset'

interface Props {
  /** 当前业态，决定渲染哪一组字段 */
  propertyType: PropertyType
  /** 后端 ext_fields 原始 object */
  modelValue: Record<string, unknown>
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:modelValue': [value: Record<string, unknown>]
}>()

// 三组本地响应式字段（按业态切换时不互相覆盖）
const officeFields = reactive<OfficeExtFields>({
  workstation_count: null,
  partition_count: null,
})
const retailFields = reactive<RetailExtFields>({
  frontage_width: null,
  street_facing: null,
  retail_ceiling_height: null,
})
const apartmentFields = reactive<ApartmentExtFields>({
  bedroom_count: null,
  en_suite_bathroom: null,
})

function loadFromValue(v: Record<string, unknown>): void {
  if (props.propertyType === 'office') {
    officeFields.workstation_count = (v.workstation_count as number | null) ?? null
    officeFields.partition_count = (v.partition_count as number | null) ?? null
  } else if (props.propertyType === 'retail') {
    retailFields.frontage_width = (v.frontage_width as number | null) ?? null
    retailFields.street_facing = (v.street_facing as boolean | null) ?? null
    retailFields.retail_ceiling_height =
      (v.retail_ceiling_height as number | null) ?? null
  } else if (props.propertyType === 'apartment') {
    apartmentFields.bedroom_count = (v.bedroom_count as number | null) ?? null
    apartmentFields.en_suite_bathroom = (v.en_suite_bathroom as boolean | null) ?? null
  }
}

watch(
  () => [props.propertyType, props.modelValue] as const,
  ([, v]) => loadFromValue(v ?? {}),
  { immediate: true, deep: true },
)

function pickCurrent(): Record<string, unknown> {
  if (props.propertyType === 'office') return { ...officeFields }
  if (props.propertyType === 'retail') return { ...retailFields }
  if (props.propertyType === 'apartment') return { ...apartmentFields }
  return {}
}

// 任一组字段变更，向上抛出当前业态对应的对象
watch(
  [officeFields, retailFields, apartmentFields],
  () => {
    emit('update:modelValue', pickCurrent())
  },
  { deep: true },
)
</script>

<style scoped>
.ext-fields-form { width: 100%; }
</style>
