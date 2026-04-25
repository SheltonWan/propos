import uni from '@dcloudio/vite-plugin-uni'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [uni()],
  // 测试时通过 VITE_TEST_PORT=5174 区分端口，避免与开发服务器冲突
  server: {
    port: Number(process.env.VITE_TEST_PORT) || 5173,
    strictPort: !!process.env.VITE_TEST_PORT,
    // 将 /api/** 代理到真实后端，避免浏览器跨域（CORS）限制
    // 使用非 VITE_ 前缀的 API_PROXY_TARGET，避免被 Vite 注入到客户端包
    // VITE_USE_MOCK=false 时生效；mock 测试通过 page.route() 拦截，不经过此代理
    proxy: process.env.API_PROXY_TARGET
      ? {
          '/api': {
            target: process.env.API_PROXY_TARGET,
            changeOrigin: true,
          },
        }
      : undefined,
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/styles/tokens.scss"; @import "@/styles/mixins.scss";`,
        silenceDeprecations: ['legacy-js-api', 'import', 'global-builtin'],
      },
    },
  },
})
