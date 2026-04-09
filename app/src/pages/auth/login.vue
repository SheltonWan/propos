<template>
  <view class="login-page">
    <view class="logo">
      <text class="logo-text">PropOS</text>
      <text class="logo-sub">物业运营管理系统</text>
    </view>

    <view class="form">
      <view class="form-item">
        <input
          v-model="form.username"
          class="input"
          type="text"
          placeholder="用户名"
          :disabled="authStore.loading"
        />
      </view>
      <view class="form-item">
        <input
          v-model="form.password"
          class="input"
          type="password"
          placeholder="密码"
          :disabled="authStore.loading"
        />
      </view>

      <view v-if="authStore.error" class="error-msg">
        {{ authStore.error }}
      </view>

      <button
        class="btn-login"
        :loading="authStore.loading"
        :disabled="authStore.loading"
        @tap="handleLogin"
      >
        登 录
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { reactive } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const form = reactive({
  username: '',
  password: '',
})

async function handleLogin() {
  if (!form.username || !form.password) {
    uni.showToast({ title: '请输入用户名和密码', icon: 'none' })
    return
  }
  await authStore.login({ username: form.username, password: form.password })
  if (!authStore.error) {
    uni.switchTab({ url: '/pages/dashboard/index' })
  }
}
</script>

<style scoped>
.login-page {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: #f0f2f5;
  padding: 40rpx;
}
.logo { text-align: center; margin-bottom: 80rpx; }
.logo-text { font-size: 64rpx; font-weight: 700; color: var(--color-primary); display: block; }
.logo-sub { font-size: 28rpx; color: #8c8c8c; display: block; margin-top: 8rpx; }
.form { width: 100%; max-width: 600rpx; background: #fff; border-radius: 16rpx; padding: 48rpx 40rpx; box-shadow: 0 4rpx 24rpx rgba(0,0,0,0.08); }
.form-item { margin-bottom: 32rpx; }
.input { width: 100%; height: 88rpx; border: 2rpx solid #d9d9d9; border-radius: 8rpx; padding: 0 24rpx; font-size: 28rpx; box-sizing: border-box; }
.error-msg { color: var(--color-danger); font-size: 24rpx; margin-bottom: 24rpx; text-align: center; }
.btn-login { width: 100%; height: 88rpx; background: var(--color-primary); color: #fff; font-size: 32rpx; border-radius: 8rpx; border: none; }
</style>
