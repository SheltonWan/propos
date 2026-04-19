/**
 * H5 平台：DOM CSS 变量注入
 */
export function applyThemeToDom(vars: Record<string, string>): void {
  // #ifdef H5
  if (typeof document !== 'undefined') {
    const root = document.documentElement
    const body = document.body
    Object.entries(vars).forEach(([key, value]) => {
      root.style.setProperty(key, value)
      body?.style.setProperty(key, value)
    })
  }
  // #endif
}

export function applyThemeToNative(_vars: Record<string, string>, _isDark: boolean): void {
  // H5 平台无需原生背景色处理
}
