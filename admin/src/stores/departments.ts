/**
 * 组织架构 Pinia stores（setup 风格）
 *   - useDepartmentsStore       部门树 + 增删改
 *   - useDepartmentImportStore  批量导入
 */

import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { ApiError } from '@/types/api'
import type {
  DepartmentTree,
  DepartmentCreateRequest,
  DepartmentUpdateRequest,
  DepartmentImportResult,
} from '@/types/department'
import {
  fetchDepartmentTree,
  createDepartment,
  updateDepartment,
  deactivateDepartment,
  importDepartments,
} from '@/api/modules/departments'

function _msg(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

/** 将树拍平为列表（含层级路径），便于级联选择器使用 */
function flatten(tree: DepartmentTree[], parentPath = ''): {
  id: string
  name: string
  fullName: string
  level: number
  is_active: boolean
}[] {
  const out: { id: string; name: string; fullName: string; level: number; is_active: boolean }[] = []
  for (const node of tree) {
    const fullName = parentPath ? `${parentPath} / ${node.name}` : node.name
    out.push({
      id: node.id,
      name: node.name,
      fullName,
      level: node.level,
      is_active: node.is_active,
    })
    if (node.children?.length) {
      out.push(...flatten(node.children, fullName))
    }
  }
  return out
}

// ─── 1. 部门树 + CRUD ──────────────────────────────────

export const useDepartmentsStore = defineStore('departments', () => {
  const tree = ref<DepartmentTree[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  /** 拍平选项列表（用于「父部门」级联选择 / 用户列表「部门」过滤） */
  const flatOptions = computed(() => flatten(tree.value))

  /** 仅活跃部门 */
  const activeOptions = computed(() => flatOptions.value.filter((n) => n.is_active))

  async function load(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      tree.value = await fetchDepartmentTree()
    } catch (e) {
      error.value = _msg(e, '加载部门树失败')
    } finally {
      loading.value = false
    }
  }

  async function create(payload: DepartmentCreateRequest): Promise<void> {
    try {
      await createDepartment(payload)
      await load()
    } catch (e) {
      error.value = _msg(e, '创建部门失败')
      throw e
    }
  }

  async function update(id: string, payload: DepartmentUpdateRequest): Promise<void> {
    try {
      await updateDepartment(id, payload)
      await load()
    } catch (e) {
      error.value = _msg(e, '更新部门失败')
      throw e
    }
  }

  async function deactivate(id: string): Promise<void> {
    try {
      await deactivateDepartment(id)
      await load()
    } catch (e) {
      error.value = _msg(e, '停用部门失败')
      throw e
    }
  }

  return { tree, loading, error, flatOptions, activeOptions, load, create, update, deactivate }
})

// ─── 2. 批量导入 ───────────────────────────────────────

export const useDepartmentImportStore = defineStore('departmentImport', () => {
  const file = ref<File | null>(null)
  const dryRunResult = ref<DepartmentImportResult | null>(null)
  const commitResult = ref<DepartmentImportResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  function setFile(f: File | null): void {
    file.value = f
    dryRunResult.value = null
    commitResult.value = null
    error.value = null
  }

  async function dryRun(): Promise<void> {
    if (!file.value) return
    loading.value = true
    error.value = null
    try {
      dryRunResult.value = await importDepartments(file.value, true)
    } catch (e) {
      error.value = _msg(e, '预校验失败')
    } finally {
      loading.value = false
    }
  }

  async function commit(): Promise<void> {
    if (!file.value) return
    loading.value = true
    error.value = null
    try {
      commitResult.value = await importDepartments(file.value, false)
    } catch (e) {
      error.value = _msg(e, '导入失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    file.value = null
    dryRunResult.value = null
    commitResult.value = null
    error.value = null
  }

  return { file, dryRunResult, commitResult, loading, error, setFile, dryRun, commit, reset }
})
