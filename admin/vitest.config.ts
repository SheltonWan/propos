import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  plugins: [vue()],
  test: {
    // 使用 jsdom 模拟浏览器环境（Element Plus 依赖 DOM API）
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-utils/setup.ts'],
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts', 'src/**/*.vue'],
      exclude: [
        'src/test-utils/**',
        'src/**/*.d.ts',
        'src/env.d.ts',
        'src/auto-imports.d.ts',
        'src/components.d.ts',
        'src/main.ts',
      ],
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
})
