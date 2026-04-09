/**
 * 认证模块 API
 */

import { apiGet, apiPost } from '@/api/client'
import {
  API_AUTH_LOGIN,
  API_AUTH_LOGOUT,
  API_AUTH_ME,
  API_AUTH_CHANGE_PASSWORD,
} from '@/constants/api_paths'

export interface LoginPayload {
  username: string
  password: string
}

export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface UserProfile {
  id: string
  username: string
  displayName: string
  role: string
  boundContractId?: string
}

export interface ChangePasswordPayload {
  oldPassword: string
  newPassword: string
}

export const authApi = {
  login: (payload: LoginPayload) => apiPost<AuthTokens>(API_AUTH_LOGIN, payload),
  logout: () => apiPost<void>(API_AUTH_LOGOUT),
  me: () => apiGet<UserProfile>(API_AUTH_ME),
  changePassword: (payload: ChangePasswordPayload) =>
    apiPost<void>(API_AUTH_CHANGE_PASSWORD, payload),
}
