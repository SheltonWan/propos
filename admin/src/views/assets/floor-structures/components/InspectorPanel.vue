<template>
  <aside class="inspector-panel">
    <header class="panel-header">
      <span class="title">属性</span>
    </header>

    <div v-if="!selected" class="empty">
      在画布中点选结构以编辑属性。
    </div>

    <el-form v-else label-position="top" size="small" class="form">
      <el-form-item label="类型">
        <el-select
          :model-value="selected.type"
          @change="(v: AnyStructureType) => onTypeChange(v)"
        >
          <el-option
            v-for="t in TYPE_OPTIONS"
            :key="t.value"
            :label="t.label"
            :value="t.value"
          />
        </el-select>
      </el-form-item>

      <el-form-item v-if="!isColumn(selected)" label="标签">
        <el-input
          :model-value="selected.label ?? ''"
          placeholder="可选，如：A棟3F-客梯1"
          @update:model-value="(v: string) => onUpdate({ label: v || undefined } as Partial<StructureOrColumn>)"
        />
      </el-form-item>

      <el-form-item v-if="isCodeRequired" label="编号">
        <el-input
          :model-value="(selected as Structure).code ?? ''"
          placeholder="例：E1（字母+1~3位数字）"
          @update:model-value="(v: string) => onUpdate({ code: v || undefined } as Partial<StructureOrColumn>)"
        />
      </el-form-item>

      <el-form-item v-if="isGenderRequired" label="性别">
        <el-radio-group
          :model-value="(selected as Structure).gender ?? 'unknown'"
          @change="(v: string | number | boolean | undefined) => onUpdate({ gender: v as 'M' | 'F' | 'unknown' } as Partial<StructureOrColumn>)"
        >
          <el-radio value="M">男</el-radio>
          <el-radio value="F">女</el-radio>
          <el-radio value="unknown">未知</el-radio>
        </el-radio-group>
      </el-form-item>

      <template v-if="!isColumn(selected)">
        <el-form-item label="X (坐标)">
          <el-input-number
            :model-value="selected.rect.x"
            :step="1"
            @update:model-value="(v: number | undefined) => onRectChange({ x: v ?? 0 })"
          />
        </el-form-item>
        <el-form-item label="Y (坐标)">
          <el-input-number
            :model-value="selected.rect.y"
            :step="1"
            @update:model-value="(v: number | undefined) => onRectChange({ y: v ?? 0 })"
          />
        </el-form-item>
        <el-form-item label="宽度">
          <el-input-number
            :model-value="selected.rect.w"
            :min="1"
            :step="1"
            @update:model-value="(v: number | undefined) => onRectChange({ w: v ?? 1 })"
          />
        </el-form-item>
        <el-form-item label="高度">
          <el-input-number
            :model-value="selected.rect.h"
            :min="1"
            :step="1"
            @update:model-value="(v: number | undefined) => onRectChange({ h: v ?? 1 })"
          />
        </el-form-item>
      </template>

      <template v-else>
        <el-form-item label="X (中心点)">
          <el-input-number
            :model-value="selected.point[0]"
            :step="1"
            @update:model-value="(v: number | undefined) => onPointChange(0, v ?? 0)"
          />
        </el-form-item>
        <el-form-item label="Y (中心点)">
          <el-input-number
            :model-value="selected.point[1]"
            :step="1"
            @update:model-value="(v: number | undefined) => onPointChange(1, v ?? 0)"
          />
        </el-form-item>
      </template>

      <el-form-item label="数据来源">
        <el-tag size="small" :type="selected.source === 'manual' ? 'success' : 'info'">
          {{ selected.source }}
        </el-tag>
        <span v-if="selected.confidence !== undefined" class="confidence">
          置信度 {{ Math.round(selected.confidence * 100) }}%
        </span>
      </el-form-item>
    </el-form>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ElMessageBox } from 'element-plus'
import { useFloorStructuresStore } from '@/stores/floorStructuresStore'
import {
  isColumn,
} from '@/types/floorMap'
import type {
  AnyStructureType,
  Structure,
  StructureOrColumn,
  StructureType,
} from '@/types/floorMap'
import { STRUCTURE_TYPE_LABELS } from '@/constants/ui_constants'

const store = useFloorStructuresStore()

const TYPE_OPTIONS: Array<{ value: AnyStructureType; label: string }> = [
  { value: 'core', label: STRUCTURE_TYPE_LABELS.core },
  { value: 'elevator', label: STRUCTURE_TYPE_LABELS.elevator },
  { value: 'stair', label: STRUCTURE_TYPE_LABELS.stair },
  { value: 'restroom', label: STRUCTURE_TYPE_LABELS.restroom },
  { value: 'equipment', label: STRUCTURE_TYPE_LABELS.equipment },
  { value: 'corridor', label: STRUCTURE_TYPE_LABELS.corridor },
  { value: 'column', label: STRUCTURE_TYPE_LABELS.column },
]

const selected = computed<StructureOrColumn | null>(() => {
  const idx = store.selectedIndex
  if (idx === null || !store.draft) return null
  return store.draft.structures[idx] ?? null
})

const isCodeRequired = computed(
  () => selected.value !== null && !isColumn(selected.value) && selected.value.type === 'elevator',
)
const isGenderRequired = computed(
  () => selected.value !== null && !isColumn(selected.value) && selected.value.type === 'restroom',
)

function onUpdate(patch: Partial<StructureOrColumn>): void {
  if (store.selectedIndex === null) return
  // 任意手动编辑都强制 source=manual + 清 confidence
  store.updateStructure(store.selectedIndex, {
    ...patch,
    source: 'manual',
    confidence: undefined,
  } as Partial<StructureOrColumn>)
}

function onRectChange(patch: Partial<{ x: number; y: number; w: number; h: number }>): void {
  if (!selected.value || isColumn(selected.value)) return
  onUpdate({ rect: { ...selected.value.rect, ...patch } } as Partial<StructureOrColumn>)
}

function onPointChange(i: 0 | 1, v: number): void {
  if (!selected.value || !isColumn(selected.value)) return
  const next: [number, number] = [...selected.value.point]
  next[i] = v
  onUpdate({ point: next } as Partial<StructureOrColumn>)
}

async function onTypeChange(next: AnyStructureType): Promise<void> {
  if (!selected.value || store.selectedIndex === null) return
  const cur = selected.value
  const wasColumn = isColumn(cur)
  const willBeColumn = next === 'column'

  if (cur.type === next) return

  if (wasColumn !== willBeColumn) {
    try {
      await ElMessageBox.confirm(
        `切换类型会重建几何（${wasColumn ? '点 → 矩形' : '矩形 → 点'}），确定继续？`,
        '切换类型',
        { type: 'warning' },
      )
    } catch {
      return
    }
  }

  if (willBeColumn) {
    // 矩形 → 点：取矩形中心
    const center: [number, number] = wasColumn
      ? [cur.point[0], cur.point[1]]
      : [cur.rect.x + cur.rect.w / 2, cur.rect.y + cur.rect.h / 2]
    store.updateStructure(store.selectedIndex, {
      type: 'column',
      point: center,
      source: 'manual',
      confidence: undefined,
    } as Partial<StructureOrColumn>)
  } else {
    // 点 → 矩形 或 矩形 → 矩形（仅换 type）
    const rect = wasColumn
      ? { x: cur.point[0] - 20, y: cur.point[1] - 20, w: 40, h: 40 }
      : cur.rect
    const label = wasColumn ? undefined : cur.label
    store.updateStructure(store.selectedIndex, {
      type: next as StructureType,
      rect,
      label,
      source: 'manual',
      confidence: undefined,
    } as Partial<StructureOrColumn>)
  }
}
</script>

<style scoped>
.inspector-panel {
  width: 320px;
  border-left: 1px solid var(--el-border-color-light);
  background: var(--el-bg-color);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}
.panel-header {
  padding: 12px 16px;
  border-bottom: 1px solid var(--el-border-color-lighter);
  font-weight: 600;
}
.empty {
  padding: 24px 16px;
  color: var(--el-text-color-secondary);
  font-size: 13px;
  text-align: center;
}
.form { padding: 12px 16px; }
.confidence {
  margin-left: 10px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
</style>
