import type { CurrentUser, LoginResponse } from '@/types/auth'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { ApiError } from '@/types/api'
import { login as apiLogin, fetchMe as apiFetchMe, logout as apiLogout, forgotPassword as apiForgotPassword, resetPassword as apiResetPassword, setTokens, clearTokens } from '@/api/modules/auth'


export const useAuthStore = defineStore('auth', () => {
  // ─── State ─────────────────────────────────────────────────────────────
  const user = ref<CurrentUser | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // ─── Getters ───────────────────────────────────────────────────────────
  const isLoggedIn = computed(() => !!user.value)
  const role = computed(() => user.value?.role ?? null)
  const permissions = computed(() => user.value?.permissions ?? [])

  // ─── Actions ───────────────────────────────────────────────────────────
  async function login(email: string, password: string) {
    loading.value = true
    error.value = null
    try {
      const res: LoginResponse = await apiLogin(email, password)
      setTokens(res.access_token, res.refresh_token)
      // 立即获取完整用户信息（含 permissions）
      try {
        user.value = await apiFetchMe()
      } catch (meErr) {
        // /api/auth/me 调用失败：清除已存 token，避免进入半登录状态
        clearTokens()
        const msg = meErr instanceof ApiError ? meErr.message : '获取用户信息失败，请重试'
        throw new ApiError('FETCH_ME_FAILED', msg, (meErr instanceof ApiError ? meErr.statusCode : 0))
      }
    } catch (e) {

      error.value = e instanceof ApiError ? e.message : '登录失败，请重试'
      throw e
    }
    finally {
      loading.value = false
    }
  }

  async function fetchMe() {
    loading.value = true
    error.value = null
    try {
      user.value = await apiFetchMe()
    }
    catch (e) {
      error.value = e instanceof ApiError ? e.message : '获取用户信息失败'
      user.value = null
    }
    finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      await apiLogout()
    }
    catch {
      // 静默处理
    }
    finally {
      user.value = null
      clearTokens()
      uni.reLaunch({ url: '/pages/auth/login' })
    }
  }

  /** 统一处理认证错误（401/token 过期），由 API 层抛出后在页面调用 */
  function handleAuthError() {
    user.value = null
    clearTokens()
    uni.reLaunch({ url: '/pages/auth/login' })
  }

  async function forgotPassword(email: string) {
    loading.value = true
    error.value = null
    try {
      await apiForgotPassword(email.trim().toLowerCase())
      // 防枚举：无论邮箱是否存在均视为成功，调用方直接展示"已发送"提示
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '操作失败，请重试'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function resetPassword(email: string, otp: string, newPassword: string) {
    loading.value = true
    error.value = null
    try {
      await apiResetPassword(email.trim().toLowerCase(), otp.trim(), newPassword)
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '操作失败，请重试'
      throw e
    } finally {
      loading.value = false
    }

  }

  function hasPermission(perm: string): boolean {
    return permissions.value.includes(perm as never)
  }

  return {
    user,
    loading,
    error,
    isLoggedIn,
    role,
    permissions,
    login,
    fetchMe,
    logout,
    forgotPassword,
    resetPassword,
    hasPermission,
    handleAuthError,
  }
})
