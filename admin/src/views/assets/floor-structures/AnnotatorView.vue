<template>
  <div class="annotator">
    <header class="topbar">
      <div class="crumbs">
        <el-button text :icon="ArrowLeft" @click="onBack">返回</el-button>
        <el-divider direction="vertical" />
        <span class="title">楼层结构标注</span>
        <span class="meta">{{ floorIdShort }}</span>
        <el-tag v-if="store.dirty" size="small" type="warning">未保存</el-tag>
      </div>
    </header>

    <Toolbar
      :floor-id="floorId"
      :mode="canvasMode"
      @mode-change="onModeChange"
      @save="onSave"
    />

    <div v-loading="store.loading" class="body">
      <!-- 楼层不存在或后端加载失败（错误详情见底部错误栏） -->
      <div v-if="!store.loading && !store.draft" class="empty-state">
        <el-empty description="楼层数据不可用">
          <template #description>
            <p>无法加载楼层数据。</p>
            <p>请确认楼层已存在，或返回楼栋详情页重试。</p>
          </template>
        </el-empty>
      </div>
      <template v-else>
        <CandidatesPanel />
        <CanvasStage ref="canvasRef" />
        <InspectorPanel />
      </template>
    </div>

    <el-alert
      v-if="store.error"
      :title="store.error"
      type="error"
      show-icon
      class="error-bar"
      @close="store.error = null"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import Toolbar from './components/Toolbar.vue'
import CandidatesPanel from './components/CandidatesPanel.vue'
import CanvasStage from './components/CanvasStage.vue'
import InspectorPanel from './components/InspectorPanel.vue'
import type { CanvasMode } from './composables/useCanvasInteraction'

const route = useRoute()
const router = useRouter()
const store = useFloorStructuresStore()

const floorId = computed(() => route.params.floorId as string)
const buildingId = computed(() => route.params.buildingId as string)
const floorIdShort = computed(() => floorId.value.slice(0, 8))

const canvasRef = ref<InstanceType<typeof CanvasStage> | null>(null)
const canvasMode = ref<CanvasMode>('select')

function onModeChange(m: CanvasMode): void {
  canvasMode.value = m
  canvasRef.value?.setMode(m)
}

async function onSave(): Promise<void> {
  const ok = await store.save(floorId.value)
  if (ok) ElMessage.success('已保存')
  else if (store.error) ElMessage.error(store.error)
}

function onBack(): void {
  router.push({ name: 'building-detail', params: { id: buildingId.value } })
}

// ── 双重 dirty 守卫 ───────────────────
async function confirmLeave(): Promise<boolean> {
  if (!store.dirty) return true
  try {
    await ElMessageBox.confirm(
      '存在未保存修改，确认离开？未保存的更改将丢失。',
      '离开页面',
      { type: 'warning', confirmButtonText: '离开', cancelButtonText: '取消' },
    )
    return true
  } catch {
    return false
  }
}

onBeforeRouteLeave(async () => (await confirmLeave()))

function onBeforeUnload(e: BeforeUnloadEvent): void {
  if (store.dirty) {
    e.preventDefault()
    e.returnValue = ''
  }
}

onMounted(() => {
  window.addEventListener('beforeunload', onBeforeUnload)
  void store.load(floorId.value)
})
onBeforeUnmount(() => window.removeEventListener('beforeunload', onBeforeUnload))

watch(floorId, (id) => {
  if (id) void store.load(id)
})
</script>

<style scoped>
.annotator {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: var(--el-bg-color-page);
}
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background: var(--el-bg-color);
  border-bottom: 1px solid var(--el-border-color-light);
}
.crumbs {
  display: flex;
  align-items: center;
  gap: 8px;
}
.title { font-weight: 600; }
.meta {
  font-family: monospace;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.body {
  flex: 1;
  display: flex;
  overflow: hidden;
}
.empty-state {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}
.error-bar {
  position: fixed;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2000;
  min-width: 320px;
  max-width: 60vw;
}
</style>
