import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import {
  DEFAULT_THEME_ID,
  getThemePreset,
  isThemeId,
  THEME_PRESETS,
  THEME_STORAGE_KEY,
  type ThemeId,
} from '@/constants/theme'

/**
 * 将主题 CSS 变量写入 WebView 真实 DOM 的 :root 和 body。
 *
 * ● H5 — 逻辑层即浏览器，直接操作 document
 * ● App-plus — 逻辑层是 JSCore（无 DOM），通过 evalJS() 把 CSS 变量
 *   注入到每个 WKWebView 的视图层 document.documentElement + body。
 *   同时把 body.style.background 设为主题底色，确保 iOS 弹性回弹时
 *   body 背景延伸覆盖安全区，不再暴露原生 WKWebView.backgroundColor。
 */
function applyThemeToDom(vars: Record<string, string>) {
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

  // #ifdef APP-PLUS
  // 构建注入脚本：逐条设置 :root CSS 变量 + body 背景色
  const bodyBg = vars['--color-surface-light'] || vars['--color-background'] || '#f5f5f7'
  const propStatements = Object.entries(vars)
    .map(([key, value]) => {
      const k = key.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
      const v = value.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
      return `r.style.setProperty('${k}','${v}');`
    })
    .join('')

  if (!propStatements) return

  // 同时设置 body.style.background 让 body 参与主题背景渲染
  const safeBg = bodyBg.replace(/\\/g, '\\\\').replace(/'/g, "\\'")
  const jsCode = [
    'try{',
    `var r=document.documentElement;`,
    propStatements,
    `var b=document.body;if(b){`,
    // 把同样的变量也写到 body 上（部分引擎 body 不继承 :root 自定义属性）
    propStatements.replace(/r\.style/g, 'b.style'),
    // 关键：设置 body 背景色为主题底色
    `b.style.background='${safeBg}';`,
    `}`,
    // uni-app 的 <page> 自定义元素在 uni.scss 中有独立的 CSS 变量定义，
    // 其优先级高于从 :root 继承的值，必须逐个覆写才能让 page 的
    // var(--color-surface-light) 等引用解析到新主题的色值。
    `var ps=document.querySelectorAll('page');`,
    `for(var i=0;i<ps.length;i++){var p=ps[i];`,
    propStatements.replace(/r\.style/g, 'p.style'),
    `p.style.background='${safeBg}';`,
    `}`,
    '}catch(e){}',
  ].join('')

  // 向所有已存在的 webview 注入（tab 各自有独立 webview）
  function injectToAllWebviews() {
    try {
      const plusObj = (typeof plus !== 'undefined' ? plus : undefined) as any
      const allWvs: Record<string, any>[] | undefined = plusObj?.webview?.all?.()
      if (Array.isArray(allWvs)) {
        allWvs.forEach((wv) => {
          if (wv && typeof wv.evalJS === 'function') {
            wv.evalJS(jsCode)
          }
        })
      }
    } catch { /* plus 未就绪 */ }
  }

  // 通过当前页面实例注入
  function injectToCurrentPage() {
    try {
      const pages = getCurrentPages()
      if (!pages.length) return
      const currentPage = pages[pages.length - 1] as Record<string, any>
      const wv = currentPage?.$getAppWebview?.()
      if (wv && typeof wv.evalJS === 'function') {
        wv.evalJS(jsCode)
      }
    } catch { /* 页面栈为空 */ }
  }

  injectToAllWebviews()
  injectToCurrentPage()

  // 延迟重试：覆盖 webview 尚未完全加载的时序窗口
  setTimeout(() => {
    injectToAllWebviews()
    injectToCurrentPage()
  }, 150)
  // #endif
}

/**
 * 设置单个 webview 的原生背景色。
 * 传入 plus.webview.WebviewObject 实例。
 */
function setWebviewBackground(wv: Record<string, any>, color: string) {
  if (wv && typeof wv.setStyle === 'function') {
    wv.setStyle({
      background: color,
      backgroundColorBottom: color,
      backgroundColorTop: color,
    })
  }
}

/**
 * 设置原生 WebView 容器背景色（iOS 弹性回弹区 / 状态栏底色 / 底部安全区底色）。
 *
 * iOS 上 position:fixed 元素也会随弹性回弹一起移动，露出底层
 * WKWebView.backgroundColor——因此 **必须** 通过原生 API 修改。
 *
 * 策略：
 *   A. plus.webview.all() → 遍历所有已创建的 webview，逐个 setStyle
 *      （解决 tab 切换时其他页面原生背景未更新的问题）
 *   B. getCurrentPages → 当前页面 $getAppWebview → setStyle
 *   C. plus.nativeUI.setUIStyle() 切换系统级 dark/light 外观
 *      让 manifest safearea.backgroundDark 生效（iOS 原生安全区底色）
 */
function applyThemeToNative(vars: Record<string, string>, isDark: boolean) {
  // #ifdef APP-PLUS
  const background = vars['--color-surface-light'] ?? vars['--color-background']
  if (!background) return

  // 切换系统级 UI 外观：dark 主题时设为 dark，让 iOS 原生安全区底色跟随
  try {
    const plusObj = (typeof plus !== 'undefined' ? plus : undefined) as any
    plusObj?.nativeUI?.setUIStyle?.(isDark ? 'dark' : 'light')
  } catch { /* plus 未就绪 */ }

  /** 策略 A：遍历所有 webview（含子 webview） */
  function applyToAllWebviews() {
    try {
      const plusObj = (typeof plus !== 'undefined' ? plus : undefined) as any
      const allWvs: Record<string, any>[] | undefined = plusObj?.webview?.all?.()
      if (Array.isArray(allWvs)) {
        allWvs.forEach((wv) => {
          setWebviewBackground(wv, background)
          // 子 webview（如 uni-app 内 tab 页面）
          try {
            const children: Record<string, any>[] | undefined = wv?.children?.()
            if (Array.isArray(children)) {
              children.forEach((child: Record<string, any>) => setWebviewBackground(child, background))
            }
          } catch { /* 无子 webview */ }
        })
      }
    } catch { /* plus 未就绪 */ }
  }

  /** 策略 B：通过页面实例获取当前 webview */
  function applyToCurrentPage() {
    try {
      const pages = getCurrentPages()
      if (!pages.length) return
      const currentPage = pages[pages.length - 1] as Record<string, any>
      const wv = currentPage?.$getAppWebview?.()
      setWebviewBackground(wv, background)
    } catch { /* 页面栈为空 */ }
  }

  // 立即执行
  applyToAllWebviews()
  applyToCurrentPage()

  // 延迟重试（覆盖 webview 创建时序差）
  setTimeout(() => {
    applyToAllWebviews()
    applyToCurrentPage()
  }, 150)
// #endif
}

function readStoredThemeId(): ThemeId {
  const storedThemeId = uni.getStorageSync(THEME_STORAGE_KEY)

  if (typeof storedThemeId === 'string' && isThemeId(storedThemeId)) {
    return storedThemeId
  }

  return DEFAULT_THEME_ID
}

export const useThemeStore = defineStore('theme', () => {
  const themeId = ref<ThemeId>(DEFAULT_THEME_ID)
  const initialized = ref(false)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const activeTheme = computed(() => getThemePreset(themeId.value))
  const themeVars = computed(() => activeTheme.value.vars)
  const themeOptions = computed(() => THEME_PRESETS)

  function applyRuntimeTheme() {
    applyThemeToDom(themeVars.value)
    applyThemeToNative(themeVars.value, themeId.value === 'dark')
  }

  function initializeTheme() {
    if (initialized.value) {
      applyRuntimeTheme()
      return
    }

    loading.value = true
    error.value = null

    try {
      themeId.value = readStoredThemeId()
      applyRuntimeTheme()
      initialized.value = true
    } catch {
      themeId.value = DEFAULT_THEME_ID
      error.value = '主题初始化失败'
      applyRuntimeTheme()
      initialized.value = true
    } finally {
      loading.value = false
    }
  }

  function setTheme(nextThemeId: ThemeId) {
    themeId.value = nextThemeId
    uni.setStorageSync(THEME_STORAGE_KEY, nextThemeId)
    applyRuntimeTheme()
  }

  function setThemeById(nextThemeId: string) {
    if (!isThemeId(nextThemeId)) {
      error.value = '主题不存在'
      return false
    }

    error.value = null
    setTheme(nextThemeId)
    return true
  }

  return {
    themeId,
    initialized,
    loading,
    error,
    activeTheme,
    themeVars,
    themeOptions,
    initializeTheme,
    applyRuntimeTheme,
    setTheme,
    setThemeById,
  }
})