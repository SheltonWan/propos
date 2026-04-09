<template>
  <el-container class="layout-root">
    <!-- 侧边栏 -->
    <el-aside :width="sidebarWidth" class="layout-aside">
      <div class="logo">
        <span v-if="!collapsed" class="logo-text">PropOS</span>
        <span v-else class="logo-icon">P</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        :collapse="collapsed"
        router
        class="sidebar-menu"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon>
          <template #title>总览</template>
        </el-menu-item>
        <el-menu-item index="/assets">
          <el-icon><OfficeBuilding /></el-icon>
          <template #title>资产管理</template>
        </el-menu-item>
        <el-menu-item index="/contracts">
          <el-icon><Document /></el-icon>
          <template #title>合同管理</template>
        </el-menu-item>
        <el-menu-item index="/finance">
          <el-icon><Money /></el-icon>
          <template #title>财务管理</template>
        </el-menu-item>
        <el-menu-item index="/workorders">
          <el-icon><Tools /></el-icon>
          <template #title>工单管理</template>
        </el-menu-item>
        <el-menu-item index="/subleases">
          <el-icon><Connection /></el-icon>
          <template #title>二房东管理</template>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container class="layout-main">
      <!-- 顶部栏 -->
      <el-header class="layout-header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="collapsed = !collapsed">
            <Fold v-if="!collapsed" /><Expand v-else />
          </el-icon>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              {{ authStore.profile?.name ?? '用户' }}
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 主内容区 -->
      <el-main class="layout-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  Odometer, OfficeBuilding, Document, Money, Tools,
  Connection, Fold, Expand, ArrowDown,
} from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores'
import { SIDEBAR_WIDTH_PX, SIDEBAR_COLLAPSED_WIDTH_PX } from '@/constants/ui_constants'

const authStore = useAuthStore()
const route = useRoute()
const collapsed = ref(false)

const sidebarWidth = computed(() =>
  collapsed.value ? `${SIDEBAR_COLLAPSED_WIDTH_PX}px` : `${SIDEBAR_WIDTH_PX}px`,
)

const activeMenu = computed(() => '/' + route.path.split('/')[1])

function handleCommand(cmd: string) {
  if (cmd === 'logout') authStore.logout()
}
</script>

<style scoped>
.layout-root { height: 100vh; }
.layout-aside {
  background: var(--el-menu-bg-color);
  transition: width 0.2s;
  overflow: hidden;
}
.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 700;
  color: var(--el-color-primary);
  border-bottom: 1px solid var(--el-border-color);
}
.sidebar-menu { border-right: none; height: calc(100vh - 60px); }
.layout-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--el-border-color);
  background: #fff;
}
.collapse-btn { font-size: 20px; cursor: pointer; }
.user-info { cursor: pointer; display: flex; align-items: center; gap: 4px; }
.layout-content { background: var(--el-bg-color-page); }
</style>
