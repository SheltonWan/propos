<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor" <!-- theme-guard-ignore-line -->
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor" <!-- theme-guard-ignore-line -->
    :page-style="pageMetaPageStyle"
  />
  <AppShell with-tabbar>
    <template #header>
      <!-- Dashboard 深色渐变 Header，参考 PAGE_WIREFRAMES v1.8 §3.2 -->
      <view class="dash-header">
        <view class="dash-header__left">
          <text class="dash-header__greeting">你好，{{ displayName }}</text>
          <text class="dash-header__date">{{ dateStr }}</text>
        </view>
        <view class="dash-header__right">
          <view
            class="dash-header__bell"
            hover-class="dash-header__btn--pressed"
            :hover-start-time="20"
            :hover-stay-time="80"
            @tap="handleNotifications"
          >
            <image class="dash-header__bell-icon" src="/static/icons/bell.svg" mode="aspectFit" />
          </view>
          <view
            class="dash-header__avatar"
            hover-class="dash-header__btn--pressed"
            :hover-start-time="20"
            :hover-stay-time="80"
            @tap="handleUserMenu"
          >
            <image class="dash-header__avatar-icon" src="/static/icons/person.svg" mode="aspectFit" />
          </view>
        </view>
      </view>
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
import { computed } from 'vue'
import dayjs from 'dayjs'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAuthStore } from '@/stores/auth'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()
const authStore = useAuthStore()

const displayName = computed(() => authStore.user?.name ?? '用户')

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
// ─── Dashboard 顶部 Header ─────────────────────────────────────────────────
.dash-header {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 24rpx $space-page-x 28rpx;
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-background-dark) 100%);
}

.dash-header__left {
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.dash-header__greeting {
  font-size: 34rpx;
  font-weight: 700;
  color: $color-on-dark-text;
  line-height: 1.3;
}

.dash-header__date {
  font-size: 22rpx;
  color: $color-on-dark-text-muted;
  line-height: 1.4;
}

.dash-header__right {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 24rpx;
}

.dash-header__bell,
.dash-header__avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  transition: opacity 0.15s;
}

.dash-header__btn--pressed {
  opacity: 0.6;
}

.dash-header__bell {
  background: $color-on-dark-overlay-sm;
}

.dash-header__bell-icon {
  width: 40rpx;
  height: 40rpx;
}

.dash-header__avatar {
  background: $color-on-dark-overlay-md;
}

.dash-header__avatar-icon {
  width: 40rpx;
  height: 40rpx;
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
