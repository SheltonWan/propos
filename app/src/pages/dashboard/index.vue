<template>
  <!-- theme-guard-ignore-next -->
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaTopBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell with-tabbar :header-background="headerDarkColor">
    <template #header>
      <!-- Dashboard 深色 Header，对齐 React Home.tsx PageHeader variant="dark" -->
      <PageHeader
        variant="dark"
        :title="`你好，${displayName}`"
        :subtitle="dateStr"
        :back="false"
        :border="false"
      >
        <template #actions>
          <!-- 铃铛：未读角标 -->
          <view
            class="dash-action-btn"
            hover-class="dash-action-btn--pressed"
            :hover-start-time="20"
            :hover-stay-time="80"
            @tap="handleNotifications"
          >
            <image class="dash-action-icon" src="/static/icons/bell.svg" mode="aspectFit" />
            <view v-if="unreadCount > 0" class="dash-badge">
              <text class="dash-badge__text">{{ unreadCount > 99 ? '99+' : unreadCount }}</text>
            </view>
          </view>
          <!-- 头像：SVG 图标 -->
          <view
            class="dash-avatar"
            hover-class="dash-action-btn--pressed"
            :hover-start-time="20"
            :hover-stay-time="80"
            @tap="handleUserMenu"
          >
            <image class="dash-action-icon" src="/static/icons/person.svg" mode="aspectFit" />
          </view>
        </template>
      </PageHeader>
    </template>

    <view class="dashboard">
      <AppCard class="dashboard__placeholder-card" :animated="false">
        <text class="dashboard__placeholder">
          首页内容占位
        </text>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import dayjs from 'dayjs'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { storeToRefs } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const { activeTheme } = storeToRefs(themeStore)
// Dashboard Header 专用深色背景：使用 --color-card-dark（由主题系统注入）
// 而非 --color-background-dark，对齐 React PageHeader variant="dark"
const headerDarkColor = computed(() => activeTheme.value.vars['--color-card-dark'] ?? '#001d3d')
const { pageMetaBackgroundColor, pageMetaTopBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle } = usePageThemeMeta(undefined, headerDarkColor)
// Dashboard 顶部始终为深色 Header，状态栏文字固定为浅色（白色图标）
const pageMetaTextStyle = 'light' as const
const authStore = useAuthStore()

const displayName = computed(() => authStore.user?.name ?? '用户')
// TODO: 接入通知 store 后替换为真实未读数
const unreadCount = ref(0)

const dateStr = computed(() => {
  const now = dayjs()
  const month = now.month() + 1
  const day = now.date()
  const weekDays = ['日', '一', '二', '三', '四', '五', '六']
  const week = weekDays[now.day()]
  return `${month}月${day}日 周${week}`
})

function handleNotifications() {
  // TODO: 跳转通知中心
}

function handleUserMenu() {
  uni.showActionSheet({
    itemList: ['退出登录'],
    itemColor: '#e53935', // theme-guard-ignore-line
    success(res) {
      if (res.tapIndex === 0) {
        uni.showModal({
          title: '退出登录',
          content: '确定要退出当前账号吗？',
          confirmText: '退出',
          confirmColor: '#e53935', // theme-guard-ignore-line
          success(modal) {
            if (modal.confirm) {
              authStore.logout()
            }
          },
        })
      }
    },
  })
}
</script>

<style lang="scss" scoped>
// ─── Dashboard Header 操作按钮（对齐 React Home.tsx actions） ──────────────
.dash-action-btn {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  background: $color-on-dark-overlay-sm;
  transition: opacity 0.15s;
}

.dash-action-btn--pressed {
  opacity: 0.6;
}

.dash-action-icon {
  width: 40rpx;
  height: 40rpx;
}

// 未读角标（红点 + 数字）
.dash-badge {
  position: absolute;
  top: 8rpx;
  right: 8rpx;
  min-width: 32rpx;
  height: 32rpx;
  padding: 0 8rpx;
  background: var(--color-danger);
  border-radius: 999rpx;
  border: 3rpx solid $color-background-dark;
  display: flex;
  align-items: center;
  justify-content: center;
}

.dash-badge__text {
  font-size: 18rpx;
  font-weight: 700;
  color: $color-on-dark-text;
  line-height: 1;
}

// 头像圆圈（SVG 图标）
.dash-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  background: $color-on-dark-overlay-md;
  display: flex;
  align-items: center;
  justify-content: center;
}

// ─── Dashboard 主体 ────────────────────────────────────────────────────────
.dashboard {
  padding-top: $space-page-y;
}

.dashboard__placeholder-card {
  margin-top: $space-gap-md;
}

.dashboard__placeholder {
  @include text-caption;
  text-align: center;
  display: block;
  margin: 120rpx 0;
}
</style>
