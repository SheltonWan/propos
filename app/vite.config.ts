import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'

export default defineConfig({
  plugins: [uni()],
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/styles/tokens.scss"; @import "@/styles/mixins.scss";`,
        silenceDeprecations: ['legacy-js-api', 'import', 'global-builtin'],
      },
    },
  },
})
