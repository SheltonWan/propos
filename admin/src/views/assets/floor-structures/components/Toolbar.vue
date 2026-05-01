<template>
  <div class="toolbar">
    <div class="left">
      <el-button-group>
        <el-tooltip content="选择 (Esc)" placement="bottom">
          <el-button :type="mode === 'select' ? 'primary' : 'default'" @click="$emit('mode-change', 'select')">
            <el-icon><Pointer /></el-icon>
          </el-button>
        </el-tooltip>
        <el-tooltip content="新增矩形 (N)" placement="bottom">
          <el-button :type="mode === 'draw' ? 'primary' : 'default'" @click="$emit('mode-change', 'draw')">
            <el-icon><Plus /></el-icon>
          </el-button>
        </el-tooltip>
        <el-tooltip content="平移 (Shift+拖拽)" placement="bottom">
          <el-button :type="mode === 'pan' ? 'primary' : 'default'" @click="$emit('mode-change', 'pan')">
            <el-icon><Rank /></el-icon>
          </el-button>
        </el-tooltip>
      </el-button-group>

      <el-divider direction="vertical" />

      <el-tooltip content="撤销 (Cmd/Ctrl+Z)" placement="bottom">
        <el-button :disabled="!store.canUndo" @click="store.undo()">
          <el-icon><RefreshLeft /></el-icon>
        </el-button>
      </el-tooltip>
      <el-tooltip content="重做 (Shift+Cmd/Ctrl+Z)" placement="bottom">
        <el-button :disabled="!store.canRedo" @click="store.redo()">
          <el-icon><RefreshRight /></el-icon>
        </el-button>
      </el-tooltip>

      <el-tooltip content="删除选中 (Delete)" placement="bottom">
        <el-button
          :disabled="store.selectedIndex === null"
          @click="store.selectedIndex !== null && store.removeStructure(store.selectedIndex)"
        >
          <el-icon><Delete /></el-icon>
        </el-button>
      </el-tooltip>

      <el-divider direction="vertical" />

      <el-tooltip content="重置 draft 到上次加载状态" placement="bottom">
        <el-button :disabled="!store.dirty" @click="store.reset()">重置</el-button>
      </el-tooltip>
    </div>

    <div class="right">
      <RenderModeSwitch :floor-id="floorId" />
      <el-divider direction="vertical" />
      <el-tooltip
        :content="store.validationError ?? '保存草稿到服务器'"
        placement="bottom"
      >
        <el-button
          type="primary"
          :loading="store.saving"
          :disabled="!store.canSave"
          @click="$emit('save')"
        >
          保存
        </el-button>
      </el-tooltip>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Pointer, Plus, Rank, RefreshLeft, RefreshRight, Delete } from '@element-plus/icons-vue'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import RenderModeSwitch from './RenderModeSwitch.vue'
import type { CanvasMode } from '../composables/useCanvasInteraction'

defineProps<{
  floorId: string
  mode: CanvasMode
}>()

defineEmits<{
  (e: 'mode-change', mode: CanvasMode): void
  (e: 'save'): void
}>()

const store = useFloorStructuresStore()
</script>

<style scoped>
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 16px;
  background: var(--el-bg-color);
  border-bottom: 1px solid var(--el-border-color-light);
}
.left, .right {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
