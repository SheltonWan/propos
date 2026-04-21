<template>
  <div class="forgot-container">
    <el-card class="forgot-card" shadow="always">

      <!-- 成功状态 -->
      <el-result
        v-if="step === 'success'"
        icon="success"
        title="密码已重置"
        sub-title="请使用新密码重新登录"
      >
        <template #extra>
          <el-button type="primary" @click="router.push('/login')">前往登录</el-button>
        </template>
      </el-result>

      <!-- 第一步：输入邮箱 -->
      <template v-else-if="step === 1">
        <div class="forgot-header">
          <el-link :underline="false" @click="router.push('/login')" class="back-link">
            ← 返回登录
          </el-link>
          <h2 class="forgot-title">重置密码</h2>
          <p class="forgot-subtitle">输入账号邮箱，我们将向您发送 6 位验证码</p>
        </div>

        <el-form
          ref="form1Ref"
          :model="form1"
          :rules="rules1"
          label-position="top"
          size="large"
          @submit.prevent="handleSendOtp"
        >
          <el-form-item label="邮箱地址" prop="email">
            <el-input
              v-model="form1.email"
              placeholder="example@company.com"
              autocomplete="email"
            />
          </el-form-item>

          <el-alert
            v-if="error"
            :title="error"
            type="error"
            :closable="false"
            style="margin-bottom: 16px"
          />

          <el-form-item>
            <el-button
              type="primary"
              native-type="submit"
              :loading="loading"
              style="width: 100%"
            >
              发送验证码
            </el-button>
          </el-form-item>
        </el-form>
      </template>

      <!-- 第二步：输入 OTP + 新密码 -->
      <template v-else-if="step === 2">
        <div class="forgot-header">
          <el-link :underline="false" @click="step = 1" class="back-link">
            ← 返回
          </el-link>
          <h2 class="forgot-title">输入验证码</h2>
          <p class="forgot-subtitle">验证码已发送至 {{ form1.email }}，10 分钟内有效</p>
        </div>

        <el-form
          ref="form2Ref"
          :model="form2"
          :rules="rules2"
          label-position="top"
          size="large"
          @submit.prevent="handleReset"
        >
          <el-form-item label="6 位验证码" prop="otp">
            <el-input
              v-model="form2.otp"
              placeholder="请输入邮件中的 6 位数字"
              maxlength="6"
              autocomplete="one-time-code"
            />
          </el-form-item>

          <el-form-item label="新密码" prop="newPassword">
            <el-input
              v-model="form2.newPassword"
              type="password"
              placeholder="至少 8 位，含大小写字母和数字"
              show-password
              autocomplete="new-password"
            />
          </el-form-item>

          <el-form-item label="确认新密码" prop="confirmPassword">
            <el-input
              v-model="form2.confirmPassword"
              type="password"
              placeholder="再次输入新密码"
              show-password
              autocomplete="new-password"
            />
          </el-form-item>

          <el-alert
            v-if="error"
            :title="error"
            type="error"
            :closable="false"
            style="margin-bottom: 16px"
          />

          <el-form-item>
            <el-button
              type="primary"
              native-type="submit"
              :loading="loading"
              style="width: 100%"
            >
              重置密码
            </el-button>
          </el-form-item>

          <el-form-item>
            <el-button
              :disabled="loading || countdown > 0"
              style="width: 100%"
              @click="handleResend"
            >
              {{ countdown > 0 ? `重新发送验证码（${countdown} 秒）` : '重新发送验证码' }}
            </el-button>
          </el-form-item>
        </el-form>
      </template>

    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { forgotPassword, resetPassword } from '@/api/modules/auth'
import { ApiError } from '@/types/api'

const router = useRouter()

// ── 步骤控制 ───────────────────────────────────────────────────────────
const step = ref<1 | 2 | 'success'>(1)

// ── 第一步：邮箱表单 ───────────────────────────────────────────────────
const form1Ref = ref<FormInstance>()
const form1 = reactive({ email: '' })
const rules1: FormRules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' },
  ],
}

// ── 第二步：OTP + 密码表单 ─────────────────────────────────────────────
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

// ── 公共状态 ───────────────────────────────────────────────────────────
const loading = ref(false)
const error = ref<string | null>(null)
// ── 重发倒计时 (防频繁发送验证码) ────────────────────────────────────
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
// ── 处理器 ─────────────────────────────────────────────────────────────
async function handleSendOtp() {
  if (!form1Ref.value) return
  const valid = await form1Ref.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  error.value = null
  try {
    await forgotPassword(form1.email.trim().toLowerCase())
    // 防枚举：无论邮箱是否存在均进入第二步
    step.value = 2    startCountdown()  } catch (e) {
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
    await resetPassword(
      form1.email.trim().toLowerCase(),
      form2.otp.trim(),
      form2.newPassword,
    )
    step.value = 'success'
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '操作失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

/// 重新发送验证码（倒计时结束后才可点击）
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
.forgot-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--el-bg-color-page);
}
.forgot-card {
  width: 420px;
}
.forgot-header {
  margin-bottom: 24px;
}
.back-link {
  font-size: 14px;
  color: var(--el-text-color-secondary);
}
.forgot-title {
  margin: 16px 0 4px;
  font-size: 22px;
  font-weight: 600;
}
.forgot-subtitle {
  margin: 0;
  color: var(--el-text-color-secondary);
  font-size: 14px;
}
</style>
