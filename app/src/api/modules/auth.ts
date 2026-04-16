import { apiPost, apiGet, setTokens, clearTokens } from '../client'
import type { LoginResponse, TokenResponse, CurrentUser } from '@/types/auth'
import { AUTH_LOGIN, AUTH_ME, AUTH_LOGOUT, AUTH_CHANGE_PASSWORD } from '@/constants/api_paths'

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

export { setTokens, clearTokens }
