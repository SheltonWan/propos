/**
 * 用户管理 Pinia stores（setup 风格）
 *   - useUsersStore        列表 + CRUD + 启停 + 角色/部门变更
 *   - useUserDetailStore   用户详情
 *   - useUserImportStore   批量导入（dry_run + commit）
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ApiError } from '@/types/api'
import type { PaginationMeta } from '@/types/api'
import type {
  UserSummary,
  UserDetail,
  UserListParams,
  UserCreateRequest,
  UserUpdateRequest,
  UserRole,
  UserImportResult,
} from '@/types/user'
import {
  fetchUsers,
  fetchUser,
  createUser,
  updateUser,
  updateUserStatus,
  updateUserRole,
  updateUserDepartment,
  importUsers,
} from '@/api/modules/users'

function _msg(e: unknown, fallback: string): string {
  return e instanceof ApiError ? e.message : fallback
}

// ─── 1. 列表 + CRUD ────────────────────────────────────

export const useUsersStore = defineStore('users', () => {
  const list = ref<UserSummary[]>([])
  const meta = ref<PaginationMeta | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const filters = ref<UserListParams>({ page: 1, pageSize: 20 })

  async function load(params?: UserListParams): Promise<void> {
    if (params) filters.value = { ...filters.value, ...params }
    loading.value = true
    error.value = null
    try {
      const res = await fetchUsers(filters.value)
      list.value = res.data
      meta.value = res.meta
    } catch (e) {
      error.value = _msg(e, '加载用户列表失败')
    } finally {
      loading.value = false
    }
  }

  async function create(payload: UserCreateRequest): Promise<UserDetail | null> {
    loading.value = true
    error.value = null
    try {
      const detail = await createUser(payload)
      await load()
      return detail
    } catch (e) {
      error.value = _msg(e, '创建用户失败')
      throw e
    } finally {
      loading.value = false
    }
  }

  async function update(id: string, payload: UserUpdateRequest): Promise<void> {
    try {
      await updateUser(id, payload)
      await load()
    } catch (e) {
      error.value = _msg(e, '更新用户失败')
      throw e
    }
  }

  async function toggleStatus(id: string, isActive: boolean): Promise<void> {
    try {
      await updateUserStatus(id, isActive)
      await load()
    } catch (e) {
      error.value = _msg(e, '启停用失败')
      throw e
    }
  }

  async function changeRole(
    id: string,
    role: UserRole,
    boundContractId?: string | null,
  ): Promise<void> {
    try {
      await updateUserRole(id, role, boundContractId)
      await load()
    } catch (e) {
      error.value = _msg(e, '变更角色失败')
      throw e
    }
  }

  async function changeDepartment(id: string, departmentId: string): Promise<void> {
    try {
      await updateUserDepartment(id, departmentId)
      await load()
    } catch (e) {
      error.value = _msg(e, '变更部门失败')
      throw e
    }
  }

  function resetFilters(): void {
    filters.value = { page: 1, pageSize: 20 }
  }

  return {
    list,
    meta,
    loading,
    error,
    filters,
    load,
    create,
    update,
    toggleStatus,
    changeRole,
    changeDepartment,
    resetFilters,
  }
})

// ─── 2. 详情 ───────────────────────────────────────────

export const useUserDetailStore = defineStore('userDetail', () => {
  const item = ref<UserDetail | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function load(id: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      item.value = await fetchUser(id)
    } catch (e) {
      error.value = _msg(e, '加载用户详情失败')
    } finally {
      loading.value = false
    }
  }

  function reset(): void {
    item.value = null
    error.value = null
  }

  return { item, loading, error, load, reset }
})

// ─── 3. 批量导入 ───────────────────────────────────────

export const useUserImportStore = defineStore('userImport', () => {
  const file = ref<File | null>(null)
  const dryRunResult = ref<UserImportResult | null>(null)
  const commitResult = ref<UserImportResult | null>(null)
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
      dryRunResult.value = await importUsers(file.value, true)
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
      commitResult.value = await importUsers(file.value, false)
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
