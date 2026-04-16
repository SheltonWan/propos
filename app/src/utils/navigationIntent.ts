/**
 * Tab 导航意图模块
 *
 * 解决 AppTabBar 在新建 webview 中首次挂载时，getCurrentPages() 可能尚未
 * 包含目标页面的竞态问题。
 *
 * 用法：
 *   - 调用 switchTab 前：setIntendedTabPath(targetPath)
 *   - 新页面 AppTabBar setup() 中：consumeIntendedTabPath() 取走意图路径
 */

let intendedTabPath: string | null = null

export function setIntendedTabPath(path: string): void {
  intendedTabPath = path
}

export function consumeIntendedTabPath(): string | null {
  const path = intendedTabPath
  intendedTabPath = null
  return path
}
