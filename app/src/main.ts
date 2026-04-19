import { createPinia } from 'pinia'
import { createSSRApp } from 'vue'
import App from './App.vue'
import { ApiError } from './types/api'

export function createApp() {
  const app = createSSRApp(App)
  app.use(createPinia())

  app.config.errorHandler = (err, _instance, info) => {
    console.error(`[Global Error] ${info}:`, err)

    // API 错误：向用户展示可理解的消息
    if (err instanceof ApiError) {
      // 401 已由响应拦截器处理跳转，无需重复提示
      if (err.statusCode === 401)
        return

      uni.showToast({
        title: err.message || '请求失败',
        icon: 'none',
        duration: 2500,
      })
      return
    }

    // 未知运行时错误
    uni.showToast({
      title: '系统异常，请稍后重试',
      icon: 'none',
      duration: 2500,
    })
  }

  return {
    app,
  }
}
