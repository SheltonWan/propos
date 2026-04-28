/**
 * LoginView.vue 组件测试
 *
 * 覆盖范围：
 * - 渲染：邮箱、密码输入框、登录按钮、忘记密码链接
 * - loading 状态：按钮禁用（authStore.loading=true）
 * - 错误展示：authStore.error 非空时显示 el-alert
 */

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/vue'
import userEvent from '@testing-library/user-event'
import { createTestingPinia } from '@pinia/testing'
import { createRouter, createMemoryHistory } from 'vue-router'
import ElementPlus from 'element-plus'
import LoginView from '@/views/auth/LoginView.vue'
import { useAuthStore } from '@/stores'

// 刷新所有挂起的 Promise 微任务（async-validator 是 Promise-based，需要此函数确保状态同步到 DOM）
const flushAsync = () => new Promise<void>((resolve) => setTimeout(resolve))

// ── 路由 mock ──────────────────────────────────────────

const testRouter = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: '/', component: { template: '<div />' } },
    { path: '/login', component: LoginView },
    { path: '/forgot-password', component: { template: '<div />' } },
    { path: '/dashboard', component: { template: '<div />' } },
  ],
})

// ── 辅助：渲染 LoginView ────────────────────────────────

function renderLoginView(storeState: Record<string, unknown> = {}) {
  return render(LoginView, {
    global: {
      plugins: [
        // Element Plus 必须在此注册，测试环境 unplugin 不生效
        ElementPlus,
        createTestingPinia({
          createSpy: vi.fn,
          initialState: {
            auth: {
              profile: null,
              loading: false,
              error: null,
              ...storeState,
            },
          },
        }),
        testRouter,
      ],
    },
  })
}

// ── 测试套件 ───────────────────────────────────────────

describe('LoginView', () => {
  beforeEach(async () => {
    await testRouter.push('/login')
    await testRouter.isReady()
  })

  describe('渲染', () => {
    it('显示"PropOS 管理平台"标题', () => {
      renderLoginView()
      expect(screen.getByText('PropOS 管理平台')).toBeTruthy()
    })

    it('渲染邮箱输入框', () => {
      renderLoginView()
      expect(screen.getByPlaceholderText('请输入账号邮箱')).toBeTruthy()
    })

    it('渲染密码输入框', () => {
      renderLoginView()
      expect(screen.getByPlaceholderText('请输入密码')).toBeTruthy()
    })

    it('渲染"登录"提交按钮', () => {
      renderLoginView()
      expect(screen.getByRole('button', { name: /登录/ })).toBeTruthy()
    })

    it('渲染"忘记密码？"链接', () => {
      renderLoginView()
      expect(screen.getByText('忘记密码？')).toBeTruthy()
    })
  })

  describe('错误展示', () => {
    it('authStore.error 为 null 时不显示 el-alert', () => {
      renderLoginView({ error: null })
      expect(screen.queryByRole('alert')).toBeNull()
    })

    it('authStore.error 非空时显示对应错误文字', async () => {
      renderLoginView({ error: '用户名或密码错误' })
      await waitFor(() => {
        expect(screen.getByRole('alert')).toBeTruthy()
        expect(screen.getByText('用户名或密码错误')).toBeTruthy()
      })
    })
  })

  describe('loading 状态', () => {
    it('authStore.loading=true 时按钮禁用', async () => {
      renderLoginView({ loading: true })
      const btn = screen.getByRole('button', { name: /登录/ })
      // Element Plus loading 按钮会设置 disabled 或 is-loading class
      await waitFor(() => {
        expect(btn.hasAttribute('disabled') || btn.classList.contains('is-loading')).toBe(true)
      })
    })
  })

  describe('表单校验', () => {
    // 注：jsdom 环境下 el-form 的异步 validate() 机制不完整（el-form-item 注册链断裂），
    // 空提交阻断和 blur 错误文字的完整行为由 E2E (Playwright) 测试覆盖。
    // 此处测试 Element Plus 在渲染时根据 rules.required 添加的 is-required 标记，
    // 以及字段必填配置被组件正确接收。

    it('必填字段渲染 is-required 标记（邮箱和密码均有 required 规则）', () => {
      renderLoginView()
      // el-form-item 在渲染时根据 required: true 规则添加 is-required class（不依赖校验触发）
      const requiredItems = document.querySelectorAll('.el-form-item.is-required')
      expect(requiredItems.length).toBeGreaterThanOrEqual(2)
    })

    it('邮箱字段接收了校验规则（is-required class 存在）', () => {
      renderLoginView()
      const emailInput = screen.getByPlaceholderText('请输入账号邮箱')
      const formItem = emailInput.closest('.el-form-item')
      // required: true 规则触发 is-required class，视觉上显示红色必填星号
      expect(formItem?.classList.contains('is-required')).toBe(true)
    })
  })

  describe('表单交互', () => {
    it('填写有效表单提交 → authStore.login 以正确参数被调用', async () => {
      const user = userEvent.setup()
      renderLoginView()
      // createTestingPinia 安装后，useAuthStore() 返回同一 store 实例，actions 已被 vi.fn() 替换
      const authStore = useAuthStore()

      await user.type(screen.getByPlaceholderText('请输入账号邮箱'), 'test@propos.com')
      await user.type(screen.getByPlaceholderText('请输入密码'), 'password123')

      // 直接触发 form submit，确保 handleLogin 被调用
      const form = document.querySelector('form')!
      fireEvent.submit(form)

      await waitFor(() => {
        expect(authStore.login).toHaveBeenCalledWith('test@propos.com', 'password123')
      })
    })

    it('点击"忘记密码" → router.push 到 /forgot-password', async () => {
      const user = userEvent.setup()
      // 在渲染前注入 spy，确保捕获组件内 useRouter() 触发的 push 调用
      const pushSpy = vi.spyOn(testRouter, 'push').mockResolvedValue(undefined as never)

      renderLoginView()
      await user.click(screen.getByText('忘记密码？'))

      expect(pushSpy).toHaveBeenCalledWith('/forgot-password')
      pushSpy.mockRestore()
    })
  })
})
