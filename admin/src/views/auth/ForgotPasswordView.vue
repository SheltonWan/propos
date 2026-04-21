<template>
  <div class="forgot-container">
    <el-card class="forgot-card" shadow="always">
      <!-- 成功状态 -->
      <el-result
        v-if="sent"
        icon="success"
        title="重置链接已发送"
        sub-title="若该邮箱已注册，您将收到一封密码重置邮件，链接有效期 2 小时。请检查邮件（包括垃圾邮件）。"
      >
        <template #extra>
          <el-button type="primary" @click="router.push('/login')">返回登录</el-button>
        </template>
      </el-result>

      <!-- 表单状态 -->
      <template v-else>
        <div class="forgot-header">
          <el-link :underline="false" @click="router.push('/login')" class="back-link">
            ← 返回登录
          </el-link>
          <h2 class="forgot-title">重置密码</h2>
          <p class="forgot-subtitle">输入账号邮箱，我们将向您发送重置链接</p>
        </div>

        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          size="large"
          @submit.prevent="handleSubmit"
        >
          <el-form-item label="邮箱地址" prop="email">
            <el-input
              v-model="form.email"
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
              发送重置链接
            </el-button>
          </el-form-item>
        </el-form>
      </template>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { forgotPassword } from '@/api/modules/auth'
import { ApiError } from '@/types/api'

const router = useRouter()
const formRef = ref<FormInstance>()

const form = reactive({ email: '' })
const loading = ref(false)
const error = ref<string | null>(null)
const sent = ref(false)

const rules: FormRules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' },
  ],
}

async function handleSubmit() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  error.value = null
  try {
    await forgotPassword(form.email.trim().toLowerCase())
    // 防枚举：无论邮箱是否存在均显示成功状态
    sent.value = true
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '请求失败，请稍后再试'
  } finally {
    loading.value = false
  }
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
