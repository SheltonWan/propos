import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import { resolve } from 'path'

export default defineConfig(({ mode }) => {
  // 显式加载 .env.[mode] 及 .env.[mode].local，使代理目标可通过环境文件配置
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      vue(),
      // Element Plus 按需自动导入（减少打包体积）
      AutoImport({
        resolvers: [ElementPlusResolver()],
        imports: ['vue', 'vue-router', 'pinia'],
        dts: 'src/auto-imports.d.ts',
      }),
      Components({
        resolvers: [ElementPlusResolver()],
        dts: 'src/components.d.ts',
      }),
    ],
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src'),
      },
    },
    server: {
      port: 5173,
      proxy: {
        '/api': {
          // 优先读取 env 文件中的变量，回退到 OS 环境变量，最后默认本地
          target: env.VITE_API_BASE_URL ?? process.env.VITE_API_BASE_URL ?? 'http://localhost:8080',
          changeOrigin: true,
        },
      },
    },
    build: {
      outDir: 'dist',
      assetsDir: '_assets',
      sourcemap: false,
    },
  }
})
