import { apiPost } from '@/api/client'
import {
  API_AUTH_LOGIN,
  API_AUTH_ME,
  API_AUTH_LOGOUT,
  API_AUTH_CHANGE_PASSWORD,
  API_AUTH_FORGOT_PASSWORD,
  API_AUTH_RESET_PASSWORD,
} from '@/constants/api_paths'

// ─── 类型定义 ──────────────────────────────────────────────────────────────

export interface LoginResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  user: CurrentUser
}

export interface CurrentUser {
  id: string
  name: string
  email: string
  role: string
  permissions: string[]
}

// ─── API 函数 ──────────────────────────────────────────────────────────────

/** 登录 */
export async function login(email: string, password: string): Promise<LoginResponse> {
  return apiPost<LoginResponse>(API_AUTH_LOGIN, { email, password })
}

/** 获取当前用户信息 */
export async function fetchMe(): Promise<CurrentUser> {
  return apiPost<CurrentUser>(API_AUTH_ME)
}

/** 退出登录 */
export async function logout(refreshToken: string): Promise<void> {
  await apiPost<void>(API_AUTH_LOGOUT, { refresh_token: refreshToken })
}

/** 修改密码（需提供旧密码） */
export async function changePassword(
  oldPassword: string,
  newPassword: string,
): Promise<{ access_token: string; refresh_token: string; expires_in: number }> {
  return apiPost(API_AUTH_CHANGE_PASSWORD, {
    old_password: oldPassword,
    new_password: newPassword,
  })
}

/** 申请密码重置邮件 */
export async function forgotPassword(email: string): Promise<{ message: string }> {
  return apiPost<{ message: string }>(API_AUTH_FORGOT_PASSWORD, { email })
}

/** 通过 OTP 验证码重置密码 */
export async function resetPassword(
  email: string,
  otp: string,
  newPassword: string,
): Promise<{ message: string }> {
  return apiPost<{ message: string }>(API_AUTH_RESET_PASSWORD, {
    email,
    otp,
    new_password: newPassword,
  })
}

/** 本地持久化 token */
export function setTokens(accessToken: string, refreshToken: string): void {
  localStorage.setItem('access_token', accessToken)
  localStorage.setItem('refresh_token', refreshToken)
}

/** 清除本地 token */
export function clearTokens(): void {
  localStorage.removeItem('access_token')
  localStorage.removeItem('refresh_token')
}
