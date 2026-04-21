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
      <!-- 发送成功状态 -->
      <view v-if="sent" class="forgot-password__result">
        <wd-icon name="check-circle" size="120rpx" class="forgot-password__result-icon" />
        <text class="forgot-password__result-title">重置链接已发送</text>
        <text class="forgot-password__result-desc">
          若该邮箱已注册，您将收到一封密码重置邮件，链接有效期 2 小时。
          请在电脑浏览器中打开链接完成密码重置。
        </text>
        <view class="forgot-password__result-btn">
          <wd-button type="primary" block @click="handleBack">返回登录</wd-button>
        </view>
      </view>

      <!-- 表单 -->
      <view v-else class="forgot-password__form">
        <text class="forgot-password__desc">
          输入账号邮箱，我们将向您发送密码重置链接
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
              @confirm="handleSubmit"
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
            :disabled="!canSubmit"
            @click="handleSubmit"
          >
            {{ loading ? '发送中…' : '发送重置链接' }}
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
const email = ref('')
const loading = ref(false)
const errorMsg = ref('')
const sent = ref(false)

const canSubmit = computed(() => email.value.trim() !== '' && !loading.value)

const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

async function handleSubmit() {
  if (!canSubmit.value) return
  const trimmed = email.value.trim()
  if (!emailRegex.test(trimmed)) {
    errorMsg.value = '请输入有效的邮箱地址'
    return
  }
  loading.value = true
  errorMsg.value = ''
  try {
    await authStore.forgotPassword(trimmed)
    // 防枚举：无论邮箱是否存在均显示成功状态
    sent.value = true
  } catch {
    errorMsg.value = authStore.error || '请求失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

function handleBack() {
  uni.navigateBack({ delta: 2 })
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
