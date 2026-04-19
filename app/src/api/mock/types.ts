export interface MockResult {
  delay: number
  data?: unknown
  error?: { code: string, message: string, status: number }
}

export type MockMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'

export interface MockHandler {
  method: MockMethod
  url: string
  handler: (url: string, body?: unknown) => MockResult
}
