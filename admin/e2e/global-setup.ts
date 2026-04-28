/**
 * Playwright 全局初始化脚本
 * 在所有 project 运行前执行一次，加载 .env.e2e 中的测试用环境变量
 */
import path from 'node:path'
import * as fs from 'node:fs'

export default function globalSetup() {
  const envFile = path.join(process.cwd(), '.env.e2e')
  if (!fs.existsSync(envFile)) {
    // 未配置 .env.e2e 时仅警告，不中断（Mock 轨道不需要凭据）
    console.warn(
      '[e2e] 未找到 .env.e2e，如需运行真实后端测试请参考 .env.e2e.example 创建该文件',
    )
    return
  }

  const lines = fs.readFileSync(envFile, 'utf-8').split('\n')
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#')) continue
    const eq = trimmed.indexOf('=')
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim()
      const val = trimmed.slice(eq + 1).trim()
      // 系统环境变量优先级更高（CI 环境通过密钥管理注入）
      if (!(key in process.env)) {
        process.env[key] = val
      }
    }
  }
}
