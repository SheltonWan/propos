import type { CurrentUser, LoginResponse } from '@/types/auth'
import { AUTH_CHANGE_PASSWORD, AUTH_LOGIN, AUTH_LOGOUT, AUTH_ME } from '@/constants/api_paths'
import { apiGet, apiPost, clearTokens, setTokens } from '../client'

export function login(email: string, password: string): Promise<LoginResponse> {
  return apiPost<LoginResponse>(AUTH_LOGIN, { email, password })
}

export function fetchMe(): Promise<CurrentUser> {
  return apiGet<CurrentUser>(AUTH_ME)
}

export function logout(): Promise<void> {
  return apiPost<void>(AUTH_LOGOUT)
}

export function changePassword(oldPassword: string, newPassword: string): Promise<void> {
  return apiPost<void>(AUTH_CHANGE_PASSWORD, {
    old_password: oldPassword,
    new_password: newPassword,
  })
}

export { clearTokens, setTokens }
