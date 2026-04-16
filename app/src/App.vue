<script setup lang="ts">
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'
import { useThemeStore } from '@/stores/theme'

const PUBLIC_PAGES = ['/pages/auth/login', '/pages/auth/change-password']
const themeStore = useThemeStore()

function hideNativeTabBar() {
  if (typeof uni.hideTabBar !== 'function') {
    return
  }

  try {
    uni.hideTabBar({ animation: false })
  } catch {
    // 当前页面不是 tab 页时静默跳过
  }
}

onLaunch(() => {
  themeStore.initializeTheme()
  hideNativeTabBar()

  // plus ready 后再刷一次原生背景（覆盖启动阶段 plus 未就绪的情况）
  // #ifdef APP-PLUS
  const onPlusReady = () => {
    themeStore.applyRuntimeTheme()
  }
  if (typeof plus !== 'undefined') {
    onPlusReady()
  } else if (typeof document !== 'undefined' && typeof document.addEventListener === 'function') {
    document.addEventListener('plusready', onPlusReady, { once: true })
  } else {
    setTimeout(onPlusReady, 150)
  }
  // #endif

  // 路由拦截：未登录时跳转登录页
  uni.addInterceptor('navigateTo', {
    invoke(args: { url: string }) {
      const token = uni.getStorageSync('access_token')
      const path = args.url.split('?')[0]
      if (!token && !PUBLIC_PAGES.includes(path)) {
        uni.reLaunch({ url: '/pages/auth/login' })
        return false
      }
    },
  })

  uni.addInterceptor('switchTab', {
    invoke(args: { url: string }) {
      const token = uni.getStorageSync('access_token')
      if (!token) {
        uni.reLaunch({ url: '/pages/auth/login' })
        return false
      }
    },
    complete() {
      hideNativeTabBar()
    },
  })
})

onShow(() => {
  themeStore.applyRuntimeTheme()
  hideNativeTabBar()
})

onHide(() => {
  // App 切入后台
})
</script>

<style>
page {
  font-family: var(--theme-font-family-body);
  font-size: 28rpx;
  color: var(--color-foreground);
  background: var(--color-surface-light, #f5f5f7);
}
</style>
