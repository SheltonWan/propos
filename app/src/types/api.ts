/** API 成功响应信封（单对象） */
export interface ApiResponse<T> {
  data: T
}

/** 分页元数据 */
export interface PaginationMeta {
  page: number
  pageSize: number
  total: number
}

/** API 成功响应信封（分页列表） */
export interface ApiListResponse<T> {
  data: T[]
  meta: PaginationMeta
}

/** API 错误响应信封 */
export interface ApiErrorResponse {
  error: {
    code: string
    message: string
  }
}

/** 统一 API 错误类 */
export class ApiError extends Error {
  readonly code: string
  readonly statusCode: number

  constructor(code: string, message: string, statusCode: number) {
    super(message)
    this.name = 'ApiError'
    this.code = code
    this.statusCode = statusCode
  }
}

/** 列表查询通用参数 */
export interface ListParams {
  page?: number
  pageSize?: number
  [key: string]: unknown
}
