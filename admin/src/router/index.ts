import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
      meta: { public: true },
    },
    {
      path: '/forgot-password',
      name: 'forgot-password',
      component: () => import('@/views/auth/ForgotPasswordView.vue'),
      meta: { public: true },
    },
    {
      path: '/',
      component: () => import('@/views/layout/AppLayout.vue'),
      redirect: '/dashboard',
      children: [
        // M3 总览
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('@/views/dashboard/DashboardView.vue'),
        },
        // M1 资产
        {
          path: 'assets',
          name: 'assets',
          component: () => import('@/views/assets/AssetsView.vue'),
        },
        {
          path: 'assets/import',
          name: 'unit-import',
          component: () => import('@/views/assets/UnitImportView.vue'),
        },
        {
          path: 'assets/buildings/:id',
          name: 'building-detail',
          component: () => import('@/views/assets/BuildingDetailView.vue'),
        },
        {
          path: 'assets/buildings/:buildingId/floors/:floorId',
          name: 'floor-plan',
          component: () => import('@/views/assets/FloorPlanView.vue'),
        },
        {
          path: 'assets/units/:id',
          name: 'unit-detail',
          component: () => import('@/views/assets/UnitDetailView.vue'),
        },
        // M2 合同
        {
          path: 'contracts',
          name: 'contracts',
          component: () => import('@/views/contracts/ContractsView.vue'),
        },
        {
          path: 'contracts/:id',
          name: 'contract-detail',
          component: () => import('@/views/contracts/ContractDetailView.vue'),
        },
        // M3 财务
        {
          path: 'finance',
          name: 'finance',
          component: () => import('@/views/finance/FinanceView.vue'),
        },
        {
          path: 'finance/invoices',
          name: 'invoices',
          component: () => import('@/views/finance/InvoicesView.vue'),
        },
        {
          path: 'finance/kpi',
          name: 'kpi',
          component: () => import('@/views/finance/KpiView.vue'),
        },
        // M4 工单
        {
          path: 'workorders',
          name: 'workorders',
          component: () => import('@/views/workorders/WorkordersView.vue'),
        },
        {
          path: 'workorders/:id',
          name: 'workorder-detail',
          component: () => import('@/views/workorders/WorkorderDetailView.vue'),
        },
        // M5 二房东
        {
          path: 'subleases',
          name: 'subleases',
          component: () => import('@/views/subleases/SubleasesView.vue'),
        },
        {
          path: 'subleases/:id',
          name: 'sublease-detail',
          component: () => import('@/views/subleases/SubleaseDetailView.vue'),
        },
        // 系统设置 — 用户管理
        {
          path: 'system/users',
          name: 'users',
          component: () => import('@/views/system/users/UsersView.vue'),
        },
        {
          path: 'system/users/import',
          name: 'user-import',
          component: () => import('@/views/system/users/UserImportView.vue'),
        },
        {
          path: 'system/users/:id',
          name: 'user-detail',
          component: () => import('@/views/system/users/UserDetailView.vue'),
        },
        // 系统设置 — 组织架构
        {
          path: 'system/departments',
          name: 'departments',
          component: () => import('@/views/system/departments/DepartmentsView.vue'),
        },
        {
          path: 'system/departments/import',
          name: 'department-import',
          component: () => import('@/views/system/departments/DepartmentImportView.vue'),
        },
      ],
    },
    // 404
    { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
  ],
})

// ── 导航守卫：JWT 未登录跳转登录页 ───────────────────
router.beforeEach((to) => {
  if (to.meta.public) return true
  const token = localStorage.getItem('access_token')
  if (!token) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  return true
})

export default router
