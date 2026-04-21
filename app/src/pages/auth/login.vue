<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell
    variant="light"
    :scroll="false"
    :safe-bottom="true"
    :with-tabbar="false"
    :background-style="loginShellBackground"
  >
    <view class="login">
      <view class="login__center">
        <!-- Card -->
        <view class="login__card">
          <!-- Logo & Title -->
          <view class="login__brand">
            <view class="login__icon-box">
              <image class="login__icon-svg" src="/static/icons/logo-building.svg" mode="aspectFit" />
            </view>
            <text class="login__title">
              PropOS
            </text>
            <text class="login__tagline">
              物业运营管理平台
            </text>
          </view>

          <!-- Form -->
          <view class="login__form">
            <!-- Email -->
            <view class="login__field">
              <text class="login__label">
                邮箱
              </text>
              <view class="login__input-wrap">
                <wd-icon name="mail" size="36rpx" custom-class="login__input-icon" />
                <input
                  v-model="email"
                  type="text"
                  placeholder="请输入邮箱地址"
                  placeholder-class="login__placeholder"
                  class="login__input"
                  :disabled="loading"
                >
              </view>
            </view>

            <!-- Password -->
            <view class="login__field">
              <text class="login__label">
                密码
              </text>
              <view class="login__input-wrap">
                <wd-icon name="lock-on" size="36rpx" custom-class="login__input-icon" />
                <input
                  v-model="password"
                  :type="showPwd ? 'text' : 'password'"
                  :password="!showPwd"
                  placeholder="请输入密码"
                  placeholder-class="login__placeholder"
                  class="login__input login__input--pwd"
                  :disabled="loading"
                  confirm-type="done"
                  @confirm="handleLogin"
                >
                <view class="login__eye-btn" @tap="showPwd = !showPwd">
                  <wd-icon :name="showPwd ? 'view' : 'eye-close'" size="36rpx" custom-class="login__input-icon" />
                </view>
              </view>
            </view>

            <!-- Forgot password -->

            <view class="login__forgot" @tap="handleForgotPassword">
              <text class="login__forgot-text">忘记密码？</text>
            </view>

            <!-- Submit -->
            <view class="login__btn-wrap">
              <wd-button
                type="primary"
                block
                size="large"
                :loading="loading"
                :disabled="!canSubmit"
                @click="handleLogin"
              >
                {{ loading ? '登录中…' : '登 录' }}
              </wd-button>
            </view>

            <!-- Error alert -->
            <view v-if="errorMsg" class="login__error">
              <wd-icon name="warning" size="32rpx" custom-class="login__error-icon" />
              <text class="login__error-text">
                {{ errorMsg }}
              </text>
            </view>
          </view>
        </view>

        <LoginThemeSwitcher />
      </view>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import LoginThemeSwitcher from '@/components/auth/LoginThemeSwitcher.vue'
import AppShell from '@/components/base/AppShell.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const loginShellBackground = 'linear-gradient(135deg, var(--color-primary-soft), var(--color-background) 50%, var(--color-muted-soft))'
const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta(loginShellBackground)

const email = ref('')
const password = ref('')
const showPwd = ref(false)
const loading = ref(false)
const errorMsg = ref('')

const canSubmit = computed(() => email.value.trim() !== '' && password.value !== '' && !loading.value)

async function handleLogin() {
  if (!canSubmit.value)
    return

  loading.value = true
  errorMsg.value = ''
  try {
    await authStore.login(email.value.trim(), password.value)
    uni.switchTab({ url: '/pages/dashboard/index' })
  }
  catch {
    errorMsg.value = authStore.error || '登录失败，请重试'
  }
  finally {
    loading.value = false
  }
}

function handleForgotPassword() {
  uni.navigateTo({ url: '/pages/auth/forgot-password' })
}
</script>

<style lang="scss" scoped>
.login {
  display: flex;
  flex: 1;
  width: 100%;
  align-items: center;
  justify-content: center;
  min-height: 100%;
}

.login__center {
  width: 100%;
  flex: 1;
  padding: 0 $space-page-x;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.login__card {
  width: 100%;
  @include card-base;
  padding: $space-card * 2 $space-card;
}

.login__brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 64rpx;
}

.login__icon-box {
  width: 128rpx;
  height: 128rpx;
  border-radius: $radius-control;
  background: $color-primary;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  box-shadow: $shadow-card;
}

.login__icon-svg {
  width: 64rpx;
  height: 64rpx;
}

.login__title {
  font-size: 48rpx;
  font-weight: 700;
  color: $color-foreground;
  letter-spacing: 2rpx;
}

.login__tagline {
  font-size: 26rpx;
  color: $color-muted-foreground;
  margin-top: 8rpx;
}

.login__form {
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

.login__field {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.login__label {
  font-size: 28rpx;
  font-weight: 500;
  color: $color-foreground;
}

.login__input-wrap {
  display: flex;
  align-items: center;
  background: $color-muted-strong;
  border: 2rpx solid $color-border;
  border-radius: $radius-control;
  padding: 0 24rpx;
  height: 96rpx;
  transition: border-color 0.2s;

  &:focus-within {
    border-color: $color-primary;
    box-shadow: 0 0 0 4rpx $color-primary-focus-ring;
  }
}

:deep(.login__input-icon) {
  color: $color-muted-foreground !important;
  flex-shrink: 0;
}

.login__input {
  flex: 1;
  height: 100%;
  margin-left: 16rpx;
  font-size: 30rpx;
  color: $color-foreground;
  background: transparent;
}

.login__input--pwd {
  margin-right: 16rpx;
}

.login__placeholder {
  color: $color-muted-foreground-soft;
  font-size: 30rpx;
}

.login__eye-btn {
  flex-shrink: 0;
  padding: 12rpx;
  margin-right: -12rpx;
}

.login__forgot {
  display: flex;
  justify-content: flex-end;
}

.login__forgot-text {
  font-size: 26rpx;
  color: $color-primary;
}

.login__btn-wrap {
  margin-top: 8rpx;

  :deep(.wd-button) {
    border-radius: 48rpx !important;
    height: 96rpx !important;
    font-size: 30rpx !important;
    font-weight: 600;
  }

  :deep(.wd-button.is-disabled) {
    opacity: 1 !important;
    background: $color-primary-disabled !important;
    color: $color-primary-foreground !important;
    border-color: transparent !important;
  }
}

.login__error {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 20rpx 24rpx;
  background: $color-destructive-soft;
  border: 2rpx solid $color-destructive-border-soft;
  border-radius: $radius-control;
}

:deep(.login__error-icon) {
  color: $color-destructive !important;
}

.login__error-text {
  font-size: 26rpx;
  color: $color-destructive;
  flex: 1;
}
</style>
