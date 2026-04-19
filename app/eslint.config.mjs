import antfu from '@antfu/eslint-config'

export default antfu({
  vue: true,
  typescript: true,
  markdown: false,

  stylistic: {
    quotes: 'single',
    semi: false,
  },

  rules: {
    'no-console': 'warn',
    'vue/block-order': ['error', { order: ['template', 'script', 'style'] }],
  },

  languageOptions: {
    globals: {
      uni: 'readonly',
      UniApp: 'readonly',
      getCurrentPages: 'readonly',
      getApp: 'readonly',
      plus: 'readonly',
      wx: 'readonly',
    },
  },

  ignores: [
    'uni_modules/',
    'dist/',
    'unpackage/',
    'node_modules/',
    'docs/',
    'scripts/',
  ],
})
