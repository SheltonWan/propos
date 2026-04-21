import { apiPost, apiGet, setTokens, clearTokens } from '../client'
import type { LoginResponse, TokenResponse, CurrentUser } from '@/types/auth'
import { AUTH_LOGIN, AUTH_ME, AUTH_LOGOUT, AUTH_CHANGE_PASSWORD, AUTH_FORGOT_PASSWORD, AUTH_RESET_PASSWORD } from '@/constants/api_paths'

export function login(email: string, password: string): Promise<LoginResponse> {
  return apiPost<LoginResponse>(AUTH_LOGIN, { email, password })
}

export function fetchMe(): Promise<CurrentUser> {
  return apiGet<CurrentUser>(AUTH_ME)
}

export function logout(): Promise<void> {
  return apiPost<void>(AUTH_LOGOUT).finally(() => clearTokens())
}

export function changePassword(oldPassword: string, newPassword: string): Promise<void> {
  return apiPost<void>(AUTH_CHANGE_PASSWORD, {
    old_password: oldPassword,
    new_password: newPassword,
  })
}

/// 发送 OTP 验证码邮件。后端防枚举，无论邮箱是否存在均返回 200。
export function forgotPassword(email: string): Promise<{ message: string }> {
  return apiPost<{ message: string }>(AUTH_FORGOT_PASSWORD, { email })
}

/// 通过 OTP 验证码重置密码（忘记密码第二步）。
export function resetPassword(
  email: string,
  otp: string,
  newPassword: string,
): Promise<{ message: string }> {
  return apiPost<{ message: string }>(AUTH_RESET_PASSWORD, {
    email,
    otp,
    new_password: newPassword,
  })
}

export { setTokens, clearTokens }
