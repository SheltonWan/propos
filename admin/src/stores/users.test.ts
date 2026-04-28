/**
 * useUsersStore 单元测试
 *
 * 覆盖范围：
 * - load()：成功（list + meta）/ 带过滤参数 / 失败
 * - create()：成功（刷新列表）/ 失败（设 error，重新抛出）
 * - update()：成功（刷新列表）/ 失败（设 error，重新抛出）
 * - toggleStatus()：成功 / 失败
 * - changeRole()：成功 / 失败
 * - changeDepartment()：成功 / 失败
 * - resetFilters()：恢复默认分页
 * - useUserDetailStore.load()：成功 / 失败 / loading 变化
 */

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUsersStore, useUserDetailStore } from '@/stores/users'
import { ApiError } from '@/types/api'
import type { UserDetail, UserSummary } from '@/types/user'

// ── Mock API modules ───────────────────────────────────

vi.mock('@/api/modules/users', () => ({
  fetchUsers: vi.fn(),
  fetchUser: vi.fn(),
  createUser: vi.fn(),
  updateUser: vi.fn(),
  updateUserStatus: vi.fn(),
  updateUserRole: vi.fn(),
  updateUserDepartment: vi.fn(),
  importUsers: vi.fn(),
}))

import {
  fetchUsers,
  fetchUser,
  createUser,
  updateUser,
  updateUserStatus,
  updateUserRole,
  updateUserDepartment,
} from '@/api/modules/users'

// ── 测试数据 ───────────────────────────────────────────

const fakeMeta = { page: 1, pageSize: 20, total: 2 }

const fakeUser1: UserSummary = {
  id: 'u1',
  name: '张三',
  email: 'zhang@propos.com',
  role: 'admin',
  department_name: '运营部',
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
} as UserSummary

const fakeUser2: UserSummary = {
  id: 'u2',
  name: '李四',
  email: 'li@propos.com',
  role: 'property_manager',
  department_name: '资产部',
  is_active: true,
  created_at: '2024-01-02T00:00:00Z',
} as UserSummary

const fakeDetail: UserDetail = {
  id: 'u1',
  name: '张三',
  email: 'zhang@propos.com',
  role: 'admin',
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
} as UserDetail

// ── useUsersStore ──────────────────────────────────────

describe('useUsersStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('初始状态', () => {
    it('list 为空，meta 为 null，loading 为 false，error 为 null', () => {
      const store = useUsersStore()
      expect(store.list).toEqual([])
      expect(store.meta).toBeNull()
      expect(store.loading).toBe(false)
      expect(store.error).toBeNull()
    })

    it('默认 filters：page=1，pageSize=20', () => {
      const store = useUsersStore()
      expect(store.filters).toEqual({ page: 1, pageSize: 20 })
    })
  })

  describe('load()', () => {
    it('成功：填充 list 和 meta', async () => {
      vi.mocked(fetchUsers).mockResolvedValue({
        data: [fakeUser1, fakeUser2],
        meta: fakeMeta,
      })

      const store = useUsersStore()
      await store.load()

      expect(store.list).toEqual([fakeUser1, fakeUser2])
      expect(store.meta).toEqual(fakeMeta)
      expect(store.error).toBeNull()
    })

    it('成功：filters 被合并，API 以合并参数调用', async () => {
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: { ...fakeMeta, total: 0 } })

      const store = useUsersStore()
      await store.load({ page: 2, role: 'admin' } as never)

      expect(fetchUsers).toHaveBeenCalledWith(
        expect.objectContaining({ page: 2, role: 'admin', pageSize: 20 }),
      )
    })

    it('成功：loading 最终恢复为 false', async () => {
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: fakeMeta })

      const store = useUsersStore()
      await store.load()

      expect(store.loading).toBe(false)
    })

    it('失败（ApiError）：error.value = e.message', async () => {
      vi.mocked(fetchUsers).mockRejectedValue(
        new ApiError('FORBIDDEN', '无权查看用户列表', 403),
      )

      const store = useUsersStore()
      await store.load()

      expect(store.error).toBe('无权查看用户列表')
      expect(store.loading).toBe(false)
    })

    it('失败（普通 Error）：error.value = 默认消息', async () => {
      vi.mocked(fetchUsers).mockRejectedValue(new Error('Network Error'))

      const store = useUsersStore()
      await store.load()

      expect(store.error).toBe('加载用户列表失败')
    })
  })

  describe('create()', () => {
    it('成功：返回 UserDetail，并调用 load() 刷新列表', async () => {
      vi.mocked(createUser).mockResolvedValue(fakeDetail)
      vi.mocked(fetchUsers).mockResolvedValue({ data: [fakeUser1], meta: fakeMeta })

      const store = useUsersStore()
      const result = await store.create({
        name: '张三',
        email: 'zhang@propos.com',
        password: 'pass123',
        role: 'admin',
      })

      expect(result).toEqual(fakeDetail)
      expect(fetchUsers).toHaveBeenCalled()
    })

    it('失败：error.value 被设置，异常重新抛出', async () => {
      vi.mocked(createUser).mockRejectedValue(
        new ApiError('DUPLICATE_EMAIL', '邮箱已存在', 409),
      )

      const store = useUsersStore()
      await expect(store.create({ email: 'dup@x.com' } as never)).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('邮箱已存在')
    })

    it('失败：loading 恢复为 false', async () => {
      vi.mocked(createUser).mockRejectedValue(new ApiError('ERR', '失败', 500))

      const store = useUsersStore()
      await store.create({} as never).catch(() => {})
      expect(store.loading).toBe(false)
    })
  })

  describe('update()', () => {
    it('成功：调用 load() 刷新列表', async () => {
      vi.mocked(updateUser).mockResolvedValue(fakeDetail)
      vi.mocked(fetchUsers).mockResolvedValue({ data: [fakeUser1], meta: fakeMeta })

      const store = useUsersStore()
      await store.update('u1', { name: '张三改' })

      expect(updateUser).toHaveBeenCalledWith('u1', { name: '张三改' })
      expect(fetchUsers).toHaveBeenCalled()
    })

    it('失败：error.value 被设置，异常重新抛出', async () => {
      vi.mocked(updateUser).mockRejectedValue(new ApiError('NOT_FOUND', '用户不存在', 404))

      const store = useUsersStore()
      await expect(store.update('no-such', {})).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('用户不存在')
    })
  })

  describe('toggleStatus()', () => {
    it('成功：调用 updateUserStatus 并刷新列表', async () => {
      vi.mocked(updateUserStatus).mockResolvedValue(fakeDetail as never)
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: fakeMeta })

      const store = useUsersStore()
      await store.toggleStatus('u1', false)

      expect(updateUserStatus).toHaveBeenCalledWith('u1', false)
      expect(fetchUsers).toHaveBeenCalled()
    })

    it('失败：error.value 被设置，异常重新抛出', async () => {
      vi.mocked(updateUserStatus).mockRejectedValue(new ApiError('ERR', '启停用失败', 500))

      const store = useUsersStore()
      await expect(store.toggleStatus('u1', false)).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('启停用失败')
    })
  })

  describe('changeRole()', () => {
    it('成功：调用 updateUserRole 并刷新列表', async () => {
      vi.mocked(updateUserRole).mockResolvedValue(fakeDetail as never)
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: fakeMeta })

      const store = useUsersStore()
      await store.changeRole('u1', 'property_manager')

      expect(updateUserRole).toHaveBeenCalledWith('u1', 'property_manager', undefined)
      expect(fetchUsers).toHaveBeenCalled()
    })

    it('失败：error.value 被设置', async () => {
      vi.mocked(updateUserRole).mockRejectedValue(new ApiError('ERR', '变更角色失败', 500))

      const store = useUsersStore()
      await expect(store.changeRole('u1', 'admin')).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('变更角色失败')
    })
  })

  describe('changeDepartment()', () => {
    it('成功：调用 updateUserDepartment 并刷新列表', async () => {
      vi.mocked(updateUserDepartment).mockResolvedValue(fakeDetail as never)
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: fakeMeta })

      const store = useUsersStore()
      await store.changeDepartment('u1', 'd2')

      expect(updateUserDepartment).toHaveBeenCalledWith('u1', 'd2')
    })

    it('失败：error.value 被设置', async () => {
      vi.mocked(updateUserDepartment).mockRejectedValue(
        new ApiError('ERR', '变更部门失败', 500),
      )

      const store = useUsersStore()
      await expect(store.changeDepartment('u1', 'd2')).rejects.toBeInstanceOf(ApiError)
      expect(store.error).toBe('变更部门失败')
    })
  })

  describe('resetFilters()', () => {
    it('重置 filters 为初始值', async () => {
      vi.mocked(fetchUsers).mockResolvedValue({ data: [], meta: fakeMeta })

      const store = useUsersStore()
      // 先修改 filters
      await store.load({ page: 5, role: 'admin' } as never)
      store.resetFilters()

      expect(store.filters).toEqual({ page: 1, pageSize: 20 })
    })
  })
})

// ── useUserDetailStore ─────────────────────────────────

describe('useUserDetailStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  describe('load()', () => {
    it('成功：item.value 被填充', async () => {
      vi.mocked(fetchUser).mockResolvedValue(fakeDetail)

      const store = useUserDetailStore()
      await store.load('u1')

      expect(store.item).toEqual(fakeDetail)
      expect(store.error).toBeNull()
      expect(store.loading).toBe(false)
    })

    it('失败：error.value 被设置', async () => {
      vi.mocked(fetchUser).mockRejectedValue(new ApiError('NOT_FOUND', '用户不存在', 404))

      const store = useUserDetailStore()
      await store.load('no-such')

      expect(store.error).toBe('用户不存在')
      expect(store.loading).toBe(false)
    })

    it('loading：调用时为 true，完成后为 false', async () => {
      let capturedLoading = false
      vi.mocked(fetchUser).mockImplementation(async () => {
        capturedLoading = true // 在 await 内部，loading 应为 true
        return fakeDetail
      })

      const store = useUserDetailStore()
      const p = store.load('u1')
      expect(store.loading).toBe(true)
      await p
      expect(store.loading).toBe(false)
      expect(capturedLoading).toBe(true)
    })
  })
})
