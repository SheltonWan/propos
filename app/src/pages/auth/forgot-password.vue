<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell>
    <template #header>
      <PageHeader title="忘记密码" :back="true" />
    </template>

    <view class="forgot-password">

      <!-- 成功状态 -->
      <view v-if="step === 'success'" class="forgot-password__result">
        <wd-icon name="check-circle" size="120rpx" class="forgot-password__result-icon" />
        <text class="forgot-password__result-title">密码已重置</text>
        <text class="forgot-password__result-desc">请使用新密码重新登录</text>
        <view class="forgot-password__result-btn">
          <wd-button type="primary" block @click="handleToLogin">前往登录</wd-button>
        </view>
      </view>

      <!-- 第一步：输入邮箱 -->
      <view v-else-if="step === 1" class="forgot-password__form">
        <text class="forgot-password__desc">
          输入账号邮箱，我们将向您发送 6 位验证码
        </text>

        <view class="forgot-password__field">
          <text class="forgot-password__label">邮箱地址</text>
          <view class="forgot-password__input-wrap">
            <wd-icon name="mail" size="36rpx" custom-class="forgot-password__input-icon" />
            <input
              v-model="email"
              type="text"
              placeholder="请输入邮箱地址"
              placeholder-class="forgot-password__placeholder"
              class="forgot-password__input"
              :disabled="loading"
              confirm-type="done"
              @confirm="handleSendOtp"
            />
          </view>
        </view>

        <!-- 错误提示 -->
        <view v-if="errorMsg" class="forgot-password__error">
          <wd-icon name="warning" size="32rpx" custom-class="forgot-password__error-icon" />
          <text class="forgot-password__error-text">{{ errorMsg }}</text>
        </view>

        <view class="forgot-password__btn-wrap">
          <wd-button
            type="primary"
            block
            size="large"
            :loading="loading"
            :disabled="!canSubmitStep1"
            @click="handleSendOtp"
          >
            {{ loading ? '发送中…' : '发送验证码' }}
          </wd-button>
        </view>
      </view>

      <!-- 第二步：输入 OTP + 新密码 -->
      <view v-else-if="step === 2" class="forgot-password__form">
        <text class="forgot-password__desc">
          验证码已发送至 {{ email }}，10 分钟内有效
        </text>

        <view class="forgot-password__field">
          <text class="forgot-password__label">6 位验证码</text>
          <view class="forgot-password__input-wrap">
            <wd-icon name="pin" size="36rpx" custom-class="forgot-password__input-icon" />
            <input
              v-model="otp"
              type="number"
              :maxlength="6"
              placeholder="请输入邮件中的 6 位数字"
              placeholder-class="forgot-password__placeholder"
              class="forgot-password__input"
              :disabled="loading"
              confirm-type="next"
            />
          </view>
        </view>

        <view class="forgot-password__field">
          <text class="forgot-password__label">新密码</text>
          <view class="forgot-password__input-wrap">
            <wd-icon name="lock-on" size="36rpx" custom-class="forgot-password__input-icon" />
            <input
              v-model="newPassword"
              :type="showNew ? 'text' : 'password'"
              placeholder="至少 8 位，含大小写字母和数字"
              placeholder-class="forgot-password__placeholder"
              class="forgot-password__input"
              :disabled="loading"
              confirm-type="next"
            />
            <wd-icon
              :name="showNew ? 'view' : 'eye-close'"
              size="36rpx"
              custom-class="forgot-password__eye"
              @click="showNew = !showNew"
            />
          </view>
        </view>

        <view class="forgot-password__field">
          <text class="forgot-password__label">确认新密码</text>
          <view class="forgot-password__input-wrap">
            <wd-icon name="lock-on" size="36rpx" custom-class="forgot-password__input-icon" />
            <input
              v-model="confirmPassword"
              :type="showConfirm ? 'text' : 'password'"
              placeholder="再次输入新密码"
              placeholder-class="forgot-password__placeholder"
              class="forgot-password__input"
              :disabled="loading"
              confirm-type="done"
              @confirm="handleReset"
            />
            <wd-icon
              :name="showConfirm ? 'view' : 'eye-close'"
              size="36rpx"
              custom-class="forgot-password__eye"
              @click="showConfirm = !showConfirm"
            />
          </view>
        </view>

        <!-- 错误提示 -->
        <view v-if="errorMsg" class="forgot-password__error">
          <wd-icon name="warning" size="32rpx" custom-class="forgot-password__error-icon" />
          <text class="forgot-password__error-text">{{ errorMsg }}</text>
        </view>

        <view class="forgot-password__btn-wrap">
          <wd-button
            type="primary"
            block
            size="large"
            :loading="loading"
            :disabled="!canSubmitStep2"
            @click="handleReset"
          >
            {{ loading ? '重置中…' : '重置密码' }}
          </wd-button>
        </view>

        <view class="forgot-password__resend">
          <wd-button
            type="text"
            size="small"
            :disabled="loading"
            @click="handleResend"
          >
            重新发送验证码
          </wd-button>
        </view>
      </view>

    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAuthStore } from '@/stores/auth'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const authStore = useAuthStore()

// ── 步骤控制 ───────────────────────────────────────────────────────────
const step = ref<1 | 2 | 'success'>(1)

// ── 表单数据 ───────────────────────────────────────────────────────────
const email = ref('')
const otp = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const showNew = ref(false)
const showConfirm = ref(false)

const loading = ref(false)
const errorMsg = ref('')

const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

const canSubmitStep1 = computed(() => email.value.trim() !== '' && !loading.value)
const canSubmitStep2 = computed(
  () =>
    otp.value.trim().length === 6 &&
    newPassword.value.length >= 8 &&
    confirmPassword.value !== '' &&
    !loading.value,
)

// ── 第一步：发送 OTP ───────────────────────────────────────────────────
async function handleSendOtp() {
  if (!canSubmitStep1.value) return
  const trimmed = email.value.trim().toLowerCase()
  if (!emailRegex.test(trimmed)) {
    errorMsg.value = '请输入有效的邮箱地址'
    return
  }
  loading.value = true
  errorMsg.value = ''
  try {
    await authStore.forgotPassword(trimmed)
    // 防枚举：无论邮箱是否存在均进入第二步
    step.value = 2
  } catch {
    errorMsg.value = authStore.error || '请求失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

// ── 第二步：重置密码 ───────────────────────────────────────────────────
async function handleReset() {
  if (!canSubmitStep2.value) return
  if (newPassword.value !== confirmPassword.value) {
    errorMsg.value = '两次密码输入不一致'
    return
  }
  if (!/[A-Z]/.test(newPassword.value) || !/[a-z]/.test(newPassword.value) || !/[0-9]/.test(newPassword.value)) {
    errorMsg.value = '密码须含大小写字母和数字'
    return
  }
  loading.value = true
  errorMsg.value = ''
  try {
    await authStore.resetPassword(
      email.value.trim().toLowerCase(),
      otp.value.trim(),
      newPassword.value,
    )
    step.value = 'success'
  } catch {
    errorMsg.value = authStore.error || '操作失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

// ── 重新发送 ───────────────────────────────────────────────────────────
async function handleResend() {
  otp.value = ''
  newPassword.value = ''
  confirmPassword.value = ''
  errorMsg.value = ''
  step.value = 1
  await handleSendOtp()
}

function handleToLogin() {
  uni.reLaunch({ url: '/pages/auth/login' })
}
</script>

<style lang="scss" scoped>
.forgot-password {
  padding: $space-page-x;
}

.forgot-password__desc {
  @include text-body;
  color: var(--color-text-secondary);
  display: block;
  margin-bottom: 48rpx;
}

.forgot-password__field {
  margin-bottom: 32rpx;
}

.forgot-password__label {
  @include text-caption;
  color: var(--color-text-secondary);
  display: block;
  margin-bottom: 12rpx;
}

.forgot-password__input-wrap {
  display: flex;
  align-items: center;
  background: var(--color-surface);
  border: 2rpx solid var(--color-border);
  border-radius: 16rpx;
  padding: 0 24rpx;
  height: 96rpx;
}

.forgot-password__input {
  flex: 1;
  @include text-body;
  margin-left: 16rpx;
  height: 96rpx;
  line-height: 96rpx;
}

.forgot-password__placeholder {
  color: var(--color-text-placeholder);
}

.forgot-password__error {
  display: flex;
  align-items: center;
  gap: 8rpx;
  margin-bottom: 24rpx;
}

.forgot-password__error-text {
  @include text-caption;
  color: var(--color-error);
}

.forgot-password__btn-wrap {
  margin-top: 48rpx;
}

.forgot-password__resend {
  display: flex;
  justify-content: center;
  margin-top: 24rpx;
}

// ─── 成功状态 ─────────────────────────────────────────────────────────────
.forgot-password__result {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 120rpx;
}

.forgot-password__result-icon {
  color: var(--color-primary);
  margin-bottom: 40rpx;
}

.forgot-password__result-title {
  @include text-heading;
  margin-bottom: 24rpx;
}

.forgot-password__result-desc {
  @include text-body;
  color: var(--color-text-secondary);
  text-align: center;
  line-height: 1.6;
  margin-bottom: 64rpx;
}

.forgot-password__result-btn {
  width: 100%;
}
</style>
