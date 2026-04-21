<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
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
            <text class="dash-header__bell-icon">🔔</text>
          </view>
          <view
            class="dash-header__avatar"
            hover-class="dash-header__btn--pressed"
            :hover-start-time="20"
            :hover-stay-time="80"
            @tap="handleUserMenu"
          >
            <image class="dash-header__avatar-icon" :src="PERSON_ICON" mode="aspectFit" />
          </view>
        </view>
      </view>
    </template>

    <view class="dashboard">
      <AppCard class="dashboard__placeholder-card" :animated="false">
        <text class="dashboard__placeholder">首页内容占位</text>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useAuthStore } from '@/stores/auth'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()
const authStore = useAuthStore()

const displayName = computed(() => authStore.user?.name ?? '用户')

// 标准人物轮廓 SVG，用作无头像时的默认图标
const PERSON_ICON = `data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='rgba(255%2C255%2C255%2C0.9)'%3E%3Ccircle cx='12' cy='8' r='4'/%3E%3Cpath d='M12 14c-5.33 0-8 2.67-8 4v2h16v-2c0-1.33-2.67-4-8-4z'/%3E%3C/svg%3E`

const dateStr = computed(() => {
  const now = new Date()
  const month = now.getMonth() + 1
  const day = now.getDate()
  const weekDays = ['日', '一', '二', '三', '四', '五', '六']
  const week = weekDays[now.getDay()]
  return `${month}月${day}日 周${week}`
})

function handleNotifications() {
  // TODO: 跳转通知中心
}

function handleUserMenu() {
  uni.showActionSheet({
    itemList: ['退出登录'],
    itemColor: '#e53935',
    success(res) {
      if (res.tapIndex === 0) {
        uni.showModal({
          title: '退出登录',
          content: '确定要退出当前账号吗？',
          confirmText: '退出',
          confirmColor: '#e53935',
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
  background: linear-gradient(135deg, var(--color-primary, #1565c0) 0%, var(--color-background-dark, #1c1c1e) 100%);
}

.dash-header__left {
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.dash-header__greeting {
  font-size: 34rpx;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.3;
}

.dash-header__date {
  font-size: 22rpx;
  color: rgba(255, 255, 255, 0.65);
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
  background: rgba(255, 255, 255, 0.12);
}

.dash-header__bell-icon {
  font-size: 36rpx;
  line-height: 1;
}

.dash-header__avatar {
  background: rgba(255, 255, 255, 0.22);
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
