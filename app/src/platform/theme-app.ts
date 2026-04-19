/**
 * App-plus 平台：WebView evalJS 注入 CSS 变量 + 原生背景色
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

export function applyThemeToDom(vars: Record<string, string>): void {
  // #ifdef APP-PLUS
  const bodyBg = vars['--color-surface-light'] || vars['--color-background'] || '#f5f5f7'
  const propStatements = Object.entries(vars)
    .map(([key, value]) => {
      const k = key.replace(/\\/g, '\\\\').replace(/'/g, '\\\'')
      const v = value.replace(/\\/g, '\\\\').replace(/'/g, '\\\'')
      return `r.style.setProperty('${k}','${v}');`
    })
    .join('')

  if (!propStatements)
    return

  const safeBg = bodyBg.replace(/\\/g, '\\\\').replace(/'/g, '\\\'')
  const jsCode = [
    'try{',
    `var r=document.documentElement;`,
    propStatements,
    `var b=document.body;if(b){`,
    propStatements.replace(/r\.style/g, 'b.style'),
    `b.style.background='${safeBg}';`,
    `}`,
    `var ps=document.querySelectorAll('page');`,
    `for(var i=0;i<ps.length;i++){var p=ps[i];`,
    propStatements.replace(/r\.style/g, 'p.style'),
    `p.style.background='${safeBg}';`,
    `}`,
    '}catch(e){}',
  ].join('')

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
    }
    catch { /* plus 未就绪 */ }
  }

  function injectToCurrentPage() {
    try {
      const pages = getCurrentPages()
      if (!pages.length)
        return
      const currentPage = pages[pages.length - 1] as Record<string, any>
      const wv = currentPage?.$getAppWebview?.()
      if (wv && typeof wv.evalJS === 'function') {
        wv.evalJS(jsCode)
      }
    }
    catch { /* 页面栈为空 */ }
  }

  injectToAllWebviews()
  injectToCurrentPage()

  setTimeout(() => {
    injectToAllWebviews()
    injectToCurrentPage()
  }, 150)
  // #endif
}

export function applyThemeToNative(vars: Record<string, string>, isDark: boolean): void {
  // #ifdef APP-PLUS
  const background = vars['--color-surface-light'] ?? vars['--color-background']
  if (!background)
    return

  try {
    const plusObj = (typeof plus !== 'undefined' ? plus : undefined) as any
    plusObj?.nativeUI?.setUIStyle?.(isDark ? 'dark' : 'light')
  }
  catch { /* plus 未就绪 */ }

  function applyToAllWebviews() {
    try {
      const plusObj = (typeof plus !== 'undefined' ? plus : undefined) as any
      const allWvs: Record<string, any>[] | undefined = plusObj?.webview?.all?.()
      if (Array.isArray(allWvs)) {
        allWvs.forEach((wv) => {
          setWebviewBackground(wv, background)
          try {
            const children: Record<string, any>[] | undefined = wv?.children?.()
            if (Array.isArray(children)) {
              children.forEach((child: Record<string, any>) => setWebviewBackground(child, background))
            }
          }
          catch { /* 无子 webview */ }
        })
      }
    }
    catch { /* plus 未就绪 */ }
  }

  function applyToCurrentPage() {
    try {
      const pages = getCurrentPages()
      if (!pages.length)
        return
      const currentPage = pages[pages.length - 1] as Record<string, any>
      const wv = currentPage?.$getAppWebview?.()
      setWebviewBackground(wv, background)
    }
    catch { /* 页面栈为空 */ }
  }

  applyToAllWebviews()
  applyToCurrentPage()

  setTimeout(() => {
    applyToAllWebviews()
    applyToCurrentPage()
  }, 150)
  // #endif
}
