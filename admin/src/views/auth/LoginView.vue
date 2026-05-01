<template>
  <div class="login-page">
    <!-- 左侧：品牌区域（深色）-->
    <div class="login-brand">
      <div class="brand-content">
        <div class="brand-logo">PropOS</div>
        <h1 class="brand-headline">智慧物业<br />运营管理平台</h1>
        <p class="brand-desc">
          覆盖写字楼、商铺、公寓三大业态<br />
          约 40,000 m² · 639 套房源统一管控
        </p>
      </div>
      <div class="brand-footer">
        <p class="brand-legal">© 2026 PropOS. 内部系统，严禁外泄。</p>
      </div>
    </div>

    <!-- 右侧：登录表单 -->
    <div class="login-form-area">
      <div class="login-form-card">
        <div class="form-header">
          <h2 class="form-title">登录</h2>
          <p class="form-subtitle">使用账号邮箱登录管理平台</p>
        </div>

        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          @submit.prevent="handleLogin"
        >
          <el-form-item label="邮箱" prop="email">
            <el-input
              v-model="form.email"
              placeholder="example@propos.cn"
              autocomplete="email"
              size="large"
            />
          </el-form-item>

          <el-form-item label="密码" prop="password">
            <el-input
              v-model="form.password"
              type="password"
              placeholder="请输入密码"
              autocomplete="current-password"
              size="large"
              show-password
            />
          </el-form-item>

          <div class="form-options">
            <a class="forgot-link" @click="router.push('/forgot-password')">忘记密码？</a>
          </div>

          <el-alert
            v-if="authStore.error"
            :title="authStore.error"
            type="error"
            :closable="false"
            class="form-alert"
          />

          <el-button
            type="primary"
            native-type="submit"
            size="large"
            :loading="authStore.loading"
            class="submit-btn"
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { useAuthStore } from '@/stores'

const router = useRouter()
const authStore = useAuthStore()
const formRef = ref<FormInstance>()

const form = reactive({ email: '', password: '' })

const rules: FormRules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码不少于6位', trigger: 'blur' },
  ],
}

async function handleLogin() {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  await authStore.login(form.email, form.password)
}
</script>

<style scoped>
/* ─── 整体布局 ─── */
.login-page {
  min-height: 100vh;
  display: flex;
}

/* ─── 左侧品牌区 ─── */
.login-brand {
  width: 420px;
  min-width: 420px;
  background: var(--apple-near-black);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 48px 48px 40px;
}

.brand-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.brand-logo {
  font-family: var(--apple-font-display);
  font-size: 22px;
  font-weight: 700;
  color: var(--apple-link-dark);
  letter-spacing: -0.5px;
  margin-bottom: 48px;
}

.brand-headline {
  font-family: var(--apple-font-display);
  font-size: 40px;
  font-weight: 600;
  line-height: 1.1;
  letter-spacing: -0.8px;
  color: #ffffff;
  margin: 0 0 20px;
}

.brand-desc {
  font-family: var(--apple-font-text);
  font-size: 15px;
  line-height: 1.6;
  color: rgba(255, 255, 255, 0.5);
  letter-spacing: -0.2px;
  margin: 0;
}

.brand-footer {
  flex-shrink: 0;
}

.brand-legal {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.24);
  letter-spacing: -0.05px;
  margin: 0;
}

/* ─── 右侧表单区 ─── */
.login-form-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--apple-light-gray);
  padding: 48px;
}

.login-form-card {
  width: 100%;
  max-width: 400px;
  background: var(--apple-white);
  border-radius: 16px;
  border: 1px solid var(--apple-border);
  padding: 40px;
  box-shadow: var(--apple-shadow-subtle);
}

.form-header {
  margin-bottom: 32px;
}

.form-title {
  font-family: var(--apple-font-display);
  font-size: 28px;
  font-weight: 600;
  letter-spacing: -0.5px;
  color: var(--apple-near-black);
  margin: 0 0 8px;
}

.form-subtitle {
  font-size: 15px;
  color: var(--apple-text-secondary);
  margin: 0;
  letter-spacing: -0.2px;
}

.form-options {
  display: flex;
  justify-content: flex-end;
  margin-top: -8px;
  margin-bottom: 20px;
}

.forgot-link {
  font-size: 14px;
  color: var(--apple-link-light);
  cursor: pointer;
  text-decoration: none;
  letter-spacing: -0.2px;
}

.forgot-link:hover {
  text-decoration: underline;
}

.form-alert {
  margin-bottom: 16px;
}

.submit-btn {
  width: 100%;
  border-radius: 8px !important;
  font-size: 15px !important;
  font-weight: 400 !important;
  height: 44px;
}

/* ─── Element Plus 表单标签本地微调 ─── */
:deep(.el-form-item__label) {
  font-weight: 500;
  font-size: 13px;
  color: var(--apple-near-black);
  letter-spacing: -0.1px;
  padding-bottom: 6px;
}

:deep(.el-input.el-input--large .el-input__wrapper) {
  border-radius: 8px !important;
  height: 44px;
}

/* ─── 响应式：小屏隐藏品牌区 ─── */
@media (max-width: 768px) {
  .login-brand {
    display: none;
  }

  .login-form-area {
    padding: 24px;
  }
}
</style>
