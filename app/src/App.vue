<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app'
import { useAuthStore } from '@/stores/auth'

// ── 路由守卫：全局拦截未登录跳转 ────────────────────────
// uni-app 中路由守卫通过 addInterceptor 实现（无 vue-router）
const PUBLIC_PAGES = ['/pages/auth/login']

function isPublicPage(url: string): boolean {
  return PUBLIC_PAGES.some((p) => url.startsWith(p))
}

function guardNavigate(args: { url: string }, next: () => void) {
  if (isPublicPage(args.url)) {
    next()
    return
  }
  const token = uni.getStorageSync('access_token') as string | undefined
  if (!token) {
    uni.reLaunch({ url: '/pages/auth/login' })
    return
  }
  next()
}

// 拦截所有导航 API
;(['navigateTo', 'redirectTo', 'reLaunch', 'switchTab'] as const).forEach((method) => {
  uni.addInterceptor(method, {
    invoke(args: { url: string }) {
      let navigated = false
      guardNavigate(args, () => {
        navigated = true
      })
      // 返回 false 阻止原始跳转（由守卫内部处理）
      return navigated
    },
  })
})

onLaunch(async () => {
  const token = uni.getStorageSync('access_token') as string | undefined
  if (token) {
    // 应用启动时静默拉取用户信息
    const authStore = useAuthStore()
    await authStore.fetchMe()
  }
})
</script>

<style>
/* 全局样式：CSS 自定义属性语义色 Token */
/* 与 docs/frontend/PAGE_SPEC_v1.7.md 状态色约定对齐 */
page {
  --color-success: #52c41a;   /* leased / paid — 已租 / 已核销 */
  --color-warning: #faad14;   /* expiring_soon / warning — 即将到期 / 预警 */
  --color-danger: #ff4d4f;    /* vacant / overdue / error — 空置 / 逾期 / 错误 */
  --color-neutral: #8c8c8c;   /* non_leasable — 非可租区域 */
  --color-primary: #1677ff;   /* 主色 */
}
</style>

