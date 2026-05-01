<template>
  <aside class="candidates-panel">
    <header class="panel-header">
      <span class="title">候选项</span>
      <el-tag size="small" type="info">auto</el-tag>
    </header>

    <div v-if="!store.candidates" class="empty">
      该楼层尚未生成候选项，请先上传 DXF 并运行抽取流程。
    </div>

    <div v-else-if="candidates.length === 0" class="empty">
      候选项为空。
    </div>

    <ul v-else class="candidate-list">
      <li
        v-for="(c, idx) in candidates"
        :key="idx"
        class="candidate-item"
        :class="{ disabled: isAdded(c) }"
        @click="onAdd(c)"
      >
        <span
          class="swatch"
          :style="{ background: STRUCTURE_TYPE_COLORS[c.type] }"
        />
        <div class="meta">
          <div class="line">
            <span class="type-label">{{ STRUCTURE_TYPE_LABELS[c.type] }}</span>
            <el-tag
              v-if="c.confidence !== undefined"
              size="small"
              :type="c.confidence >= 0.5 ? 'info' : 'warning'"
            >
              {{ Math.round(c.confidence * 100) }}%
            </el-tag>
          </div>
          <div class="sub">{{ describe(c) }}</div>
        </div>
        <span v-if="isAdded(c)" class="added">已添加</span>
      </li>
    </ul>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import {
  STRUCTURE_TYPE_COLORS,
  STRUCTURE_TYPE_LABELS,
} from '@/constants/ui_constants'
import type { StructureOrColumn } from '@/types/floorMap'
import { isColumn } from '@/types/floorMap'

const store = useFloorStructuresStore()

const candidates = computed<StructureOrColumn[]>(
  () => store.candidates?.structures ?? [],
)

/** 简单判重：column 用 point；其他用 rect 起点 */
function isAdded(c: StructureOrColumn): boolean {
  if (!store.draft) return false
  return store.draft.structures.some((s) => {
    if (s.type !== c.type) return false
    if (isColumn(c) && isColumn(s)) {
      return s.point[0] === c.point[0] && s.point[1] === c.point[1]
    }
    if (!isColumn(c) && !isColumn(s)) {
      return (
        s.rect.x === c.rect.x &&
        s.rect.y === c.rect.y &&
        s.rect.w === c.rect.w &&
        s.rect.h === c.rect.h
      )
    }
    return false
  })
}

function describe(c: StructureOrColumn): string {
  if (isColumn(c)) return `point(${c.point[0].toFixed(0)}, ${c.point[1].toFixed(0)})`
  return `rect ${c.rect.w.toFixed(0)} × ${c.rect.h.toFixed(0)}`
}

function onAdd(c: StructureOrColumn): void {
  if (isAdded(c)) return
  // 加入 draft 时强制 source=manual，并清空 confidence
  const next = { ...c, source: 'manual' as const, confidence: undefined }
  store.addStructure(next)
}
</script>

<style scoped>
.candidates-panel {
  width: 240px;
  border-right: 1px solid var(--el-border-color-light);
  background: var(--el-bg-color);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--el-border-color-lighter);
}
.title { font-weight: 600; }
.empty {
  padding: 24px 16px;
  color: var(--el-text-color-secondary);
  font-size: 13px;
  text-align: center;
}
.candidate-list {
  list-style: none;
  margin: 0;
  padding: 8px;
}
.candidate-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.15s;
}
.candidate-item:hover { background: var(--el-fill-color-light); }
.candidate-item.disabled {
  cursor: not-allowed;
  opacity: 0.5;
}
.swatch {
  width: 16px;
  height: 16px;
  border-radius: 3px;
  flex-shrink: 0;
  border: 1px solid var(--el-border-color);
}
.meta { flex: 1; min-width: 0; }
.line {
  display: flex;
  align-items: center;
  gap: 6px;
}
.type-label { font-size: 13px; font-weight: 500; }
.sub {
  font-size: 11px;
  color: var(--el-text-color-secondary);
  margin-top: 2px;
}
.added {
  font-size: 11px;
  color: var(--el-text-color-secondary);
}
</style>
