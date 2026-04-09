/**
 * 认证 Store
 * 状态格式约定：{ loading, error, data } 平对象
 * 不使用 Either/Result，catch 后写入 error 字段
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api/modules/auth'
import type { UserProfile, LoginPayload } from '@/api/modules/auth'
import { ApiError } from '@/types/api'

export const useAuthStore = defineStore('auth', () => {
  // ── State ──────────────────────────────────────────────
  const profile = ref<UserProfile | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // ── Getters ────────────────────────────────────────────
  const isLoggedIn = computed(
    () => !!uni.getStorageSync('access_token') && !!profile.value,
  )
  const role = computed(() => profile.value?.role ?? null)

  // ── Actions ────────────────────────────────────────────
  async function login(payload: LoginPayload) {
    loading.value = true
    error.value = null
    try {
      const tokens = await authApi.login(payload)
      uni.setStorageSync('access_token', tokens.accessToken)
      uni.setStorageSync('refresh_token', tokens.refreshToken)
      await fetchMe()
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '登录失败'
    } finally {
      loading.value = false
    }
  }

  async function fetchMe() {
    loading.value = true
    error.value = null
    try {
      profile.value = await authApi.me()
    } catch (e) {
      error.value = e instanceof ApiError ? e.message : '获取用户信息失败'
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    loading.value = true
    try {
      await authApi.logout()
    } catch {
      // 忽略注销接口错误，本地清除即可
    } finally {
      profile.value = null
      uni.removeStorageSync('access_token')
      uni.removeStorageSync('refresh_token')
      loading.value = false
      uni.reLaunch({ url: '/pages/auth/login' })
    }
  }

  return { profile, loading, error, isLoggedIn, role, login, fetchMe, logout }
})
