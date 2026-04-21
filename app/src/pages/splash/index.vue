<template>
  <!-- 纯背景色占位，避免 token 校验期间出现业务页面内容 -->
  <view class="splash" />
</template>

<script setup lang="ts">
import { onLoad } from '@dcloudio/uni-app'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onLoad(async () => {
  const token = uni.getStorageSync('access_token')

  // 无 token，直接跳转登录页（同步，无闪烁）
  if (!token) {
    uni.reLaunch({ url: '/pages/auth/login' })
    return
  }

  // token 存在，向后端验证有效性
  // 401 场景：响应拦截器自动尝试 refresh，refresh 失败则清 token 并跳转登录页
  await authStore.fetchMe()

  if (authStore.user) {
    uni.reLaunch({ url: '/pages/dashboard/index' })
  }
  else {
    // fetchMe 未能填充 user（token 无效 / 网络错误兜底）
    uni.reLaunch({ url: '/pages/auth/login' })
  }
})
</script>

<style lang="scss" scoped>
.splash {
  width: 100vw;
  height: 100vh;
  background: var(--color-background, #ffffff);
}
</style>
