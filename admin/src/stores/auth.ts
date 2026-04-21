import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import router from '@/router'
import { ApiError } from '@/types/api'
import { apiGet } from '@/api/client'
import { login as apiLogin, logout as apiLogout, clearTokens } from '@/api/modules/auth'
import { API_AUTH_ME } from '@/constants/api_paths'

export interface UserProfile {
  id: string
  name: string
  email: string
  role: string
  departmentId: string | null
}

export const useAuthStore = defineStore('auth', () => {
  const profile = ref<UserProfile | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isLoggedIn = computed(() => !!profile.value)
  const role = computed(() => profile.value?.role ?? null)

  async function login(email: string, password: string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const res = await apiLogin(email, password)
      localStorage.setItem('access_token', res.access_token)
      localStorage.setItem('refresh_token', res.refresh_token)
      await fetchMe()
      const redirect = (router.currentRoute.value.query.redirect as string) || '/dashboard'
      await router.replace(redirect)
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '登录失败，请重试'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchMe(): Promise<void> {
    const token = localStorage.getItem('access_token')
    if (!token) return
    loading.value = true
    error.value = null
    try {
      profile.value = await apiGet<UserProfile>(API_AUTH_ME)
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '获取用户信息失败'
      await logout(false)
    } finally {
      loading.value = false
    }
  }

  async function logout(revokeSession = true): Promise<void> {
    const refreshToken = localStorage.getItem('refresh_token')

    loading.value = true
    error.value = null

    try {
      if (revokeSession && refreshToken) {
        await apiLogout(refreshToken)
      }
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '退出登录失败，请重试'
    } finally {
      profile.value = null
      clearTokens()
      loading.value = false
      await router.replace('/login')
    }
  }

  return { profile, loading, error, isLoggedIn, role, login, fetchMe, logout }
})
