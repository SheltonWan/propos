import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [uni()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    proxy: {
      '/api': {
        // 开发时代理到本地后端
        target: process.env.VITE_API_BASE_URL ?? 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
