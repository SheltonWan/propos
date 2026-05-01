<template>
  <div class="forgot-page">
    <div class="forgot-card">

      <!-- 成功状态 -->
      <div v-if="step === 'success'" class="success-state">
        <div class="success-icon">✓</div>
        <h2 class="success-title">密码已重置</h2>
        <p class="success-desc">请使用新密码重新登录</p>
        <el-button type="primary" size="large" class="full-btn" @click="router.push('/login')">
          前往登录
        </el-button>
      </div>

      <!-- 第一步：输入邮箱 -->
      <template v-else-if="step === 1">
        <div class="card-header">
          <a class="back-link" @click="router.push('/login')">← 返回登录</a>
          <h2 class="card-title">重置密码</h2>
          <p class="card-subtitle">输入账号邮箱，我们将向您发送 6 位验证码</p>
        </div>

        <el-form
          ref="form1Ref"
          :model="form1"
          :rules="rules1"
          label-position="top"
          @submit.prevent="handleSendOtp"
        >
          <el-form-item label="邮箱地址" prop="email">
            <el-input
              v-model="form1.email"
              placeholder="example@propos.cn"
              autocomplete="email"
              size="large"
            />
          </el-form-item>

          <el-alert
            v-if="error"
            :title="error"
            type="error"
            :closable="false"
            class="form-alert"
          />

          <el-button
            type="primary"
            size="large"
            :loading="loading"
            class="full-btn"
            @click="handleSendOtp"
          >
            发送验证码
          </el-button>
        </el-form>
      </template>

      <!-- 第二步：输入 OTP + 新密码 -->
      <template v-else-if="step === 2">
        <div class="card-header">
          <a class="back-link" @click="step = 1">← 返回</a>
          <h2 class="card-title">输入验证码</h2>
          <p class="card-subtitle">验证码已发送至 {{ form1.email }}，10 分钟内有效</p>
        </div>

        <el-form
          ref="form2Ref"
          :model="form2"
          :rules="rules2"
          label-position="top"
          @submit.prevent="handleReset"
        >
          <el-form-item label="6 位验证码" prop="otp">
            <el-input
              v-model="form2.otp"
              placeholder="请输入邮件中的 6 位数字"
              maxlength="6"
              autocomplete="one-time-code"
              size="large"
            />
          </el-form-item>

          <el-form-item label="新密码" prop="newPassword">
            <el-input
              v-model="form2.newPassword"
              type="password"
              placeholder="至少 8 位，含大小写字母和数字"
              show-password
              autocomplete="new-password"
              size="large"
            />
          </el-form-item>

          <el-form-item label="确认新密码" prop="confirmPassword">
            <el-input
              v-model="form2.confirmPassword"
              type="password"
              placeholder="再次输入新密码"
              show-password
              autocomplete="new-password"
              size="large"
            />
          </el-form-item>

          <el-alert
            v-if="error"
            :title="error"
            type="error"
            :closable="false"
            class="form-alert"
          />

          <el-button
            type="primary"
            size="large"
            :loading="loading"
            class="full-btn"
            @click="handleReset"
          >
            重置密码
          </el-button>

          <el-button
            size="large"
            :disabled="loading || countdown > 0"
            class="full-btn secondary-btn"
            @click="handleResend"
          >
            {{ countdown > 0 ? `重新发送验证码（${countdown} 秒）` : '重新发送验证码' }}
          </el-button>
        </el-form>
      </template>

    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { forgotPassword, resetPassword } from '@/api/modules/auth'
import { ApiError } from '@/types/api'

const router = useRouter()

/* ── 步骤控制 ── */
const step = ref<1 | 2 | 'success'>(1)

/* ── 第一步：邮箱表单 ── */
const form1Ref = ref<FormInstance>()
const form1 = reactive({ email: '' })
const rules1: FormRules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' },
  ],
}

/* ── 第二步：OTP + 密码表单 ── */
const form2Ref = ref<FormInstance>()
const form2 = reactive({ otp: '', newPassword: '', confirmPassword: '' })
const rules2: FormRules = {
  otp: [
    { required: true, message: '请输入验证码', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '验证码为 6 位数字', trigger: 'blur' },
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 8, message: '密码至少 8 位', trigger: 'blur' },
    {
      validator: (_rule: unknown, value: string, callback: (e?: Error) => void) => {
        if (!/[A-Z]/.test(value)) return callback(new Error('密码须含大写字母'))
        if (!/[a-z]/.test(value)) return callback(new Error('密码须含小写字母'))
        if (!/[0-9]/.test(value)) return callback(new Error('密码须含数字'))
        callback()
      },
      trigger: 'blur',
    },
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (_rule: unknown, value: string, callback: (e?: Error) => void) => {
        if (value !== form2.newPassword) return callback(new Error('两次密码输入不一致'))
        callback()
      },
      trigger: 'blur',
    },
  ],
}

/* ── 公共状态 ── */
const loading = ref(false)
const error = ref<string | null>(null)

/* ── 重发倒计时 ── */
const countdown = ref(0)
let countdownTimer: ReturnType<typeof setInterval> | null = null

function startCountdown() {
  if (countdownTimer) clearInterval(countdownTimer)
  countdown.value = 60
  countdownTimer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) {
      clearInterval(countdownTimer!)
      countdownTimer = null
    }
  }, 1000)
}

onUnmounted(() => {
  if (countdownTimer) clearInterval(countdownTimer)
})

/* ── 处理器 ── */
async function handleSendOtp() {
  if (!form1Ref.value) return
  const valid = await form1Ref.value.validate().catch(() => false)
  if (!valid) return
  loading.value = true
  error.value = null
  try {
    await forgotPassword(form1.email.trim().toLowerCase())
    step.value = 2
    startCountdown()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '请求失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

async function handleReset() {
  if (!form2Ref.value) return
  const valid = await form2Ref.value.validate().catch(() => false)
  if (!valid) return
  loading.value = true
  error.value = null
  try {
    await resetPassword(form1.email.trim().toLowerCase(), form2.otp.trim(), form2.newPassword)
    step.value = 'success'
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '操作失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

async function handleResend() {
  if (countdown.value > 0) return
  form2.otp = ''
  form2.newPassword = ''
  form2.confirmPassword = ''
  error.value = null
  step.value = 1
  await handleSendOtp()
}
</script>

<style scoped>
/* ─── 页面布局 ─── */
.forgot-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--apple-light-gray);
  padding: 24px;
}

/* ─── 卡片 ─── */
.forgot-card {
  width: 100%;
  max-width: 420px;
  background: var(--apple-white);
  border-radius: 16px;
  border: 1px solid var(--apple-border);
  padding: 40px;
  box-shadow: var(--apple-shadow-subtle);
}

/* ─── 卡片头部 ─── */
.card-header {
  margin-bottom: 28px;
}

.back-link {
  display: inline-block;
  font-size: 14px;
  color: var(--apple-link-light);
  cursor: pointer;
  text-decoration: none;
  letter-spacing: -0.2px;
  margin-bottom: 20px;
}

.back-link:hover {
  text-decoration: underline;
}

.card-title {
  font-family: var(--apple-font-display);
  font-size: 28px;
  font-weight: 600;
  letter-spacing: -0.5px;
  color: var(--apple-near-black);
  margin: 0 0 8px;
}

.card-subtitle {
  font-size: 14px;
  color: var(--apple-text-secondary);
  margin: 0;
  letter-spacing: -0.2px;
  line-height: 1.5;
}

/* ─── 表单 ─── */
.form-alert {
  margin-bottom: 16px;
}

.full-btn {
  width: 100%;
  border-radius: 8px !important;
  font-size: 15px !important;
  font-weight: 400 !important;
  height: 44px;
  margin-top: 4px;
}

.secondary-btn {
  margin-top: 10px;
}

/* ─── 成功状态 ─── */
.success-state {
  text-align: center;
  padding: 16px 0;
}

.success-icon {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: rgba(48, 164, 108, 0.1);
  color: #1a7a4a;
  font-size: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
}

.success-title {
  font-family: var(--apple-font-display);
  font-size: 24px;
  font-weight: 600;
  color: var(--apple-near-black);
  margin: 0 0 8px;
  letter-spacing: -0.4px;
}

.success-desc {
  font-size: 15px;
  color: var(--apple-text-secondary);
  margin: 0 0 28px;
  letter-spacing: -0.2px;
}

/* ─── Element Plus 本地微调 ─── */
:deep(.el-form-item__label) {
  font-weight: 500;
  font-size: 13px;
  color: var(--apple-near-black);
  padding-bottom: 6px;
}

:deep(.el-input.el-input--large .el-input__wrapper) {
  border-radius: 8px !important;
  height: 44px;
}
</style>
