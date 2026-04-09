/**
 * 后端 API 响应信封类型定义（与 app/ 保持一致）
 */

export interface PaginationMeta {
  page: number
  pageSize: number
  total: number
}

export interface ApiResponse<T> {
  data: T
  meta?: PaginationMeta
}

export interface ApiListResponse<T> {
  data: T[]
  meta: PaginationMeta
}

export interface ApiErrorBody {
  error: {
    code: string
    message: string
  }
}

export class ApiError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode?: number,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export const ErrorCode = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
} as const
