/**
 * Playwright 全局初始化脚本
 * 在所有 project 运行前执行一次，加载 .env.e2e 中的测试用环境变量
 */
import path from 'node:path'
import * as fs from 'node:fs'

export default function globalSetup() {
  const envFile = path.join(process.cwd(), '.env.e2e')
  if (!fs.existsSync(envFile)) {
    // 未配置 .env.e2e 时仅警告，不中断（部分测试不需要凭据）
    console.warn(
      '[e2e] 未找到 .env.e2e，如需运行认证集成测试请参考 .env.e2e.example 创建该文件',
    )
    return
  }

  const lines = fs.readFileSync(envFile, 'utf-8').split('\n')
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#'))
      continue
    const eq = trimmed.indexOf('=')
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim()
      const val = trimmed.slice(eq + 1).trim()
      // 已存在时不覆盖（CI 环境通过系统环境变量注入优先级更高）
      if (!(key in process.env)) {
        process.env[key] = val
      }
    }
  }
}
