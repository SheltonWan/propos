<template>
  <el-tooltip
    :disabled="!disabledReason"
    :content="disabledReason ?? ''"
    placement="bottom"
  >
    <span class="render-mode-switch">
      <span class="label">渲染模式</span>
      <el-switch
        :model-value="store.renderMode === 'semantic'"
        :loading="loading"
        :disabled="!!disabledReason"
        active-text="语义"
        inactive-text="矢量"
        @change="(v: string | number | boolean) => onChange(Boolean(v))"
      />
    </span>
  </el-tooltip>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'

const props = defineProps<{
  floorId: string
}>()

const store = useFloorStructuresStore()
const loading = ref(false)

const disabledReason = computed<string | null>(() => {
  if (store.dirty) return '存在未保存修改，请先保存或重置后再切换'
  if (!store.confirmed || store.confirmed.structures.length === 0) {
    return '尚未保存任何结构，无法切换为语义模式'
  }
  return null
})

async function onChange(toSemantic: boolean): Promise<void> {
  loading.value = true
  try {
    const ok = await store.setRenderMode(props.floorId, toSemantic ? 'semantic' : 'vector')
    if (ok) ElMessage.success('渲染模式已切换')
    else ElMessage.error(store.error ?? '切换失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.render-mode-switch {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
}
</style>
