<template>
  <div class="reset-container">
    <el-card class="reset-card" shadow="always">
      <!-- token 无效/已过期 -->
      <el-result
        v-if="tokenError"
        icon="error"
        title="重置链接已失效"
        sub-title="该链接已使用或已超过 2 小时有效期，请重新申请密码重置。"
      >
        <template #extra>
          <el-button type="primary" @click="router.push('/forgot-password')">重新申请</el-button>
          <el-button @click="router.push('/login')">返回登录</el-button>
        </template>
      </el-result>

      <!-- 重置成功 -->
      <el-result
        v-else-if="success"
        icon="success"
        title="密码已成功重置"
        sub-title="正在跳转到登录页…"
      />

      <!-- 重置表单 -->
      <template v-else>
        <div class="reset-header">
          <h2 class="reset-title">设置新密码</h2>
          <p class="reset-subtitle">请输入您的新密码</p>
        </div>

        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          size="large"
          @submit.prevent="handleSubmit"
        >
          <el-form-item label="新密码" prop="newPassword">
            <el-input
              v-model="form.newPassword"
              type="password"
              placeholder="请输入新密码"
              show-password
              autocomplete="new-password"
            />
          </el-form-item>

          <el-form-item label="确认新密码" prop="confirmPassword">
            <el-input
              v-model="form.confirmPassword"
              type="password"
              placeholder="再次输入新密码"
              show-password
              autocomplete="new-password"
            />
          </el-form-item>

          <p class="password-hint">密码要求：8位以上，含大小写字母 + 数字</p>

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
              确认重置密码
            </el-button>
          </el-form-item>
        </el-form>
      </template>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { resetPassword } from '@/api/modules/auth'
import { ApiError } from '@/types/api'

const router = useRouter()
const route = useRoute()

const formRef = ref<FormInstance>()
const form = reactive({ newPassword: '', confirmPassword: '' })
const loading = ref(false)
const error = ref<string | null>(null)
const tokenError = ref(false)
const success = ref(false)
let token = ''

// 密码一致性校验器
const validateConfirmPassword = (_rule: unknown, value: string, callback: (e?: Error) => void) => {
  if (value !== form.newPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const rules: FormRules = {
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 8, message: '密码至少 8 位', trigger: 'blur' },
    {
      pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/,
      message: '密码必须包含大小写字母和数字',
      trigger: 'blur',
    },
  ],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' },
  ],
}

onMounted(() => {
  // 从 URL query 参数中读取 token
  const rawToken = route.query.token
  if (!rawToken || typeof rawToken !== 'string' || rawToken.trim() === '') {
    // token 缺失 — 立即跳转登录
    router.replace('/login')
    return
  }
  token = rawToken.trim()
})

async function handleSubmit() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  error.value = null
  try {
    await resetPassword(token, form.newPassword)
    success.value = true
    // 2s 后跳转登录页
    setTimeout(() => router.push('/login'), 2000)
  } catch (e) {
    if (e instanceof ApiError) {
      if (e.code === 'RESET_TOKEN_INVALID' || e.code === 'RESET_TOKEN_EXPIRED') {
        tokenError.value = true
      } else {
        error.value = e.message
      }
    } else {
      error.value = '操作失败，请稍后再试'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.reset-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--el-bg-color-page);
}
.reset-card {
  width: 420px;
}
.reset-header {
  margin-bottom: 24px;
}
.reset-title {
  margin: 0 0 4px;
  font-size: 22px;
  font-weight: 600;
}
.reset-subtitle {
  margin: 0;
  color: var(--el-text-color-secondary);
  font-size: 14px;
}
.password-hint {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin: -8px 0 16px;
}
</style>
