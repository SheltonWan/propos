import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import router from '@/router'
import { ApiError } from '@/types/api'
import { apiGet, apiPost } from '@/api/client'
import { API_AUTH_LOGIN, API_AUTH_ME } from '@/constants/api_paths'

export interface AuthTokens {
  accessToken: string
  refreshToken: string
}

export interface UserProfile {
  id: string
  name: string
  role: string
  departmentId: string | null
}

export interface LoginPayload {
  username: string
  password: string
}

export const useAuthStore = defineStore('auth', () => {
  const profile = ref<UserProfile | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isLoggedIn = computed(() => !!profile.value)
  const role = computed(() => profile.value?.role ?? null)

  async function login(payload: LoginPayload): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const res = await apiPost<AuthTokens>(API_AUTH_LOGIN, payload)
      localStorage.setItem('access_token', res.accessToken)
      localStorage.setItem('refresh_token', res.refreshToken)
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
      logout()
    } finally {
      loading.value = false
    }
  }

  function logout(): void {
    profile.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.replace('/login')
  }

  return { profile, loading, error, isLoggedIn, role, login, fetchMe, logout }
})
