import uni from '@dcloudio/vite-plugin-uni'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [uni()],
  // 测试时通过 VITE_TEST_PORT=5174 区分端口，避免与开发服务器冲突
  server: {
    port: Number(process.env.VITE_TEST_PORT) || 5173,
    strictPort: !!process.env.VITE_TEST_PORT,
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
