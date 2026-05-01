<template>
  <div class="layout-root">
    <!-- Apple 风格深色侧边栏 -->
    <aside :class="['layout-aside', { collapsed }]">
      <!-- Logo 区域 -->
      <div class="sidebar-logo">
        <span v-if="!collapsed" class="logo-text">PropOS</span>
        <span v-else class="logo-icon">P</span>
      </div>

      <!-- 菜单分隔线 -->
      <div class="sidebar-divider" />

      <!-- 导航菜单 -->
      <nav class="sidebar-nav">
        <router-link to="/dashboard" class="nav-item" :class="{ active: activeSection === 'dashboard' }">
          <el-icon class="nav-icon"><Odometer /></el-icon>
          <span v-if="!collapsed" class="nav-label">总览</span>
        </router-link>

        <!-- 资产管理分组 -->
        <div class="nav-group">
          <div v-if="!collapsed" class="nav-group-label">资产 & 租务</div>
          <router-link to="/assets" class="nav-item" :class="{ active: activeSection === 'assets' }">
            <el-icon class="nav-icon"><OfficeBuilding /></el-icon>
            <span v-if="!collapsed" class="nav-label">资产管理</span>
          </router-link>
          <router-link to="/contracts" class="nav-item" :class="{ active: activeSection === 'contracts' }">
            <el-icon class="nav-icon"><Document /></el-icon>
            <span v-if="!collapsed" class="nav-label">合同管理</span>
          </router-link>
          <router-link to="/subleases" class="nav-item" :class="{ active: activeSection === 'subleases' }">
            <el-icon class="nav-icon"><Connection /></el-icon>
            <span v-if="!collapsed" class="nav-label">二房东管理</span>
          </router-link>
        </div>

        <!-- 财务 & 工单 -->
        <div class="nav-group">
          <div v-if="!collapsed" class="nav-group-label">运营</div>
          <router-link to="/finance" class="nav-item" :class="{ active: activeSection === 'finance' }">
            <el-icon class="nav-icon"><Money /></el-icon>
            <span v-if="!collapsed" class="nav-label">财务管理</span>
          </router-link>
          <router-link to="/workorders" class="nav-item" :class="{ active: activeSection === 'workorders' }">
            <el-icon class="nav-icon"><Tools /></el-icon>
            <span v-if="!collapsed" class="nav-label">工单管理</span>
          </router-link>
        </div>

        <!-- 系统设置 -->
        <div class="nav-group">
          <div v-if="!collapsed" class="nav-group-label">系统</div>
          <router-link to="/system/users" class="nav-item" :class="{ active: activeSection === 'system/users' }">
            <el-icon class="nav-icon"><User /></el-icon>
            <span v-if="!collapsed" class="nav-label">员工管理</span>
          </router-link>
          <router-link to="/system/departments" class="nav-item" :class="{ active: activeSection === 'system/departments' }">
            <el-icon class="nav-icon"><OfficeBuilding /></el-icon>
            <span v-if="!collapsed" class="nav-label">组织结构</span>
          </router-link>
        </div>
      </nav>

      <!-- 底部：收起按钮 -->
      <div class="sidebar-footer">
        <button class="collapse-btn" :title="collapsed ? '展开侧边栏' : '收起侧边栏'" @click="collapsed = !collapsed">
          <el-icon><Fold v-if="!collapsed" /><Expand v-else /></el-icon>
        </button>
      </div>
    </aside>

    <!-- 主体区域 -->
    <div class="layout-main">
      <!-- 顶部栏 -->
      <header class="layout-header">
        <div class="header-breadcrumb">
          <span class="breadcrumb-text">{{ pageTitle }}</span>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <button class="user-btn">
              <div class="user-avatar">{{ userInitial }}</div>
              <span class="user-name">{{ authStore.profile?.name ?? '用户' }}</span>
              <el-icon class="user-caret"><ArrowDown /></el-icon>
            </button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- 主内容区 -->
      <main class="layout-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  Odometer, OfficeBuilding, Document, Money, Tools,
  Connection, Fold, Expand, ArrowDown, User,
} from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores'

const authStore = useAuthStore()
const route = useRoute()
const collapsed = ref(false)

/* 当前激活的路由段（支持二级路径如 system/users、system/departments）*/
const activeSection = computed(() => {
  const parts = route.path.split('/').filter(Boolean)
  if (parts[0] === 'system' && parts[1]) return `system/${parts[1]}`
  return parts[0] || 'dashboard'
})

/* 页面标题映射 */
const PAGE_TITLES: Record<string, string> = {
  dashboard: '总览',
  assets: '资产管理',
  contracts: '合同管理',
  finance: '财务管理',
  workorders: '工单管理',
  subleases: '二房东管理',
  'system/users': '员工管理',
  'system/departments': '组织结构',
}

const pageTitle = computed(() => PAGE_TITLES[activeSection.value] ?? 'PropOS')

/* 用户名首字母（头像占位符）*/
const userInitial = computed(() => {
  const name = authStore.profile?.name ?? '用'
  return name.charAt(0).toUpperCase()
})

async function handleCommand(cmd: string) {
  if (cmd === 'logout') {
    await authStore.logout()
  }
}
</script>

<style scoped>
/* ─── 整体布局 ─── */
.layout-root {
  height: 100vh;
  display: flex;
  overflow: hidden;
  background: var(--apple-light-gray);
}

/* ─── 侧边栏 ─── */
.layout-aside {
  width: 240px;
  min-width: 240px;
  height: 100vh;
  background: var(--apple-near-black);
  display: flex;
  flex-direction: column;
  transition: width 0.22s cubic-bezier(0.4, 0, 0.2, 1),
              min-width 0.22s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  flex-shrink: 0;
  position: relative;
  z-index: 10;
}

.layout-aside.collapsed {
  width: 64px;
  min-width: 64px;
}

/* Logo */
.sidebar-logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.logo-text {
  font-family: var(--apple-font-display);
  font-size: 20px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.5px;
  white-space: nowrap;
}

.logo-icon {
  font-family: var(--apple-font-display);
  font-size: 22px;
  font-weight: 700;
  color: var(--apple-link-dark);
}

.sidebar-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.08);
  margin: 0 16px;
  flex-shrink: 0;
}

/* 导航 */
.sidebar-nav {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  scrollbar-width: none;
}

.sidebar-nav::-webkit-scrollbar {
  display: none;
}

.nav-group {
  margin-top: 16px;
}

.nav-group-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.3);
  padding: 0 12px;
  margin-bottom: 4px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  height: 40px;
  border-radius: 8px;
  text-decoration: none;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
  font-family: var(--apple-font-text);
  letter-spacing: -0.2px;
  transition: background 0.15s, color 0.15s;
  white-space: nowrap;
  overflow: hidden;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.08);
  color: #ffffff;
}

.nav-item.active {
  background: rgba(41, 151, 255, 0.15);
  color: var(--apple-link-dark);
}

.nav-icon {
  font-size: 16px;
  flex-shrink: 0;
}

.nav-label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 底部收起按钮 */
.sidebar-footer {
  padding: 12px 8px;
  flex-shrink: 0;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.collapse-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 36px;
  border-radius: 8px;
  background: transparent;
  border: none;
  color: rgba(255, 255, 255, 0.4);
  font-size: 16px;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.collapse-btn:hover {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.8);
}

/* ─── 主体 ─── */
.layout-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
}

/* ─── 顶部栏 ─── */
.layout-header {
  height: 56px;
  min-height: 56px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  background: rgba(255, 255, 255, 0.88);
  backdrop-filter: saturate(180%) blur(20px);
  -webkit-backdrop-filter: saturate(180%) blur(20px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.07);
  flex-shrink: 0;
  position: sticky;
  top: 0;
  z-index: 9;
}

.header-breadcrumb {
  display: flex;
  align-items: center;
}

.breadcrumb-text {
  font-family: var(--apple-font-display);
  font-size: 17px;
  font-weight: 600;
  color: var(--apple-near-black);
  letter-spacing: -0.3px;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 6px 10px;
  border-radius: 8px;
  transition: background 0.15s;
}

.user-btn:hover {
  background: rgba(0, 0, 0, 0.05);
}

.user-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--apple-blue);
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  flex-shrink: 0;
}

.user-name {
  font-family: var(--apple-font-text);
  font-size: 14px;
  font-weight: 400;
  color: var(--apple-near-black);
  letter-spacing: -0.2px;
}

.user-caret {
  font-size: 12px;
  color: var(--apple-text-secondary);
}

/* ─── 内容区 ─── */
.layout-content {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  background: var(--apple-light-gray);
}
</style>
