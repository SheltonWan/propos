import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './styles/apple-design.css'
import './styles/floor-map.scss'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores'

const app = createApp(App)

// 注册 Element Plus 图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.use(createPinia())
app.use(router)
app.use(ElementPlus, { locale: undefined }) // locale 通过 ConfigProvider 按需设置

// 应用挂载前预拉取当前用户信息
const authStore = useAuthStore()
authStore.fetchMe().finally(() => {
  app.mount('#app')
})
