/**
 * 后端 API 响应信封类型定义
 * 与 backend 约定完全对齐（docs/backend/API_CONTRACT_v1.7.md）
 */

/** 分页元信息 */
export interface PaginationMeta {
  page: number
  pageSize: number
  total: number
}

/** 成功响应（单对象 / 非分页列表） */
export interface ApiResponse<T> {
  data: T
  meta?: PaginationMeta
}

/** 成功响应（分页列表）—— meta 必须存在 */
export interface ApiListResponse<T> {
  data: T[]
  meta: PaginationMeta
}

/** 错误响应 */
export interface ApiErrorBody {
  error: {
    /** SCREAMING_SNAKE_CASE，用于客户端业务判断，不解析 message */
    code: string
    message: string
  }
}

/** 业务异常类，API 层统一 throw；Store catch 后写入 error 字段 */
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

/** 常见业务错误码枚举（与 docs/backend/ERROR_CODE_REGISTRY.md 对齐） */
export const ErrorCode = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  CONTRACT_NOT_FOUND: 'CONTRACT_NOT_FOUND',
  INVOICE_NOT_FOUND: 'INVOICE_NOT_FOUND',
  UNIT_OCCUPIED: 'UNIT_OCCUPIED',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
} as const

export type ErrorCodeType = (typeof ErrorCode)[keyof typeof ErrorCode]
