<template>
  <div class="photo-cell">
    <div v-if="paths.length === 0" class="empty">暂无</div>
    <div v-else class="thumbs">
      <el-image
        v-for="(p, idx) in paths"
        :key="p"
        :src="srcOf(p)"
        :preview-src-list="paths.map(srcOf)"
        :initial-index="idx"
        fit="cover"
        class="thumb"
        preview-teleported
      />
    </div>

    <el-upload
      :auto-upload="false"
      :show-file-list="false"
      accept="image/jpeg,image/png"
      :on-change="onPick"
    >
      <el-button size="small" :icon="Upload" :loading="uploading">{{ uploadLabel }}</el-button>
    </el-upload>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { Upload } from '@element-plus/icons-vue'
import type { UploadFile } from 'element-plus'
import { ElMessage } from 'element-plus'
import { API_FILES } from '@/constants/api_paths'
import type { RenovationPhotoStage } from '@/types/asset'

interface Props {
  paths: string[]
  stage: RenovationPhotoStage
}
const props = defineProps<Props>()
const emit = defineEmits<{
  upload: [file: File, stage: RenovationPhotoStage]
}>()

const uploading = ref(false)

const uploadLabel = computed(() =>
  props.stage === 'before' ? '+ 改造前' : '+ 改造后',
)

function srcOf(storagePath: string): string {
  // 后端文件代理：GET /api/files/{path}
  return `${API_FILES}/${storagePath}`
}

async function onPick(file: UploadFile): Promise<void> {
  const raw = file.raw
  if (!raw) return
  const maxMb = 5
  if (raw.size > maxMb * 1024 * 1024) {
    ElMessage.warning(`照片不能超过 ${maxMb} MB`)
    return
  }
  uploading.value = true
  try {
    emit('upload', raw, props.stage)
  } finally {
    uploading.value = false
  }
}
</script>

<style scoped>
.photo-cell {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: flex-start;
}

.empty {
  color: var(--apple-text-secondary);
  font-size: 12px;
}

.thumbs {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.thumb {
  width: 36px;
  height: 36px;
  border-radius: 6px;
  border: 1px solid var(--apple-border);
  object-fit: cover;
}
</style>
