<template>
  <div class="users-view">
    <div class="page-header">
      <h2 class="title">员工账号管理</h2>
      <div class="actions">
        <el-button @click="goImport">
          <el-icon><Upload /></el-icon> 批量导入
        </el-button>
        <el-button type="primary" @click="openCreateDialog">
          <el-icon><Plus /></el-icon> 新建员工
        </el-button>
      </div>
    </div>

    <el-alert
      v-if="store.error"
      type="error"
      :title="store.error"
      show-icon
      :closable="false"
      class="alert"
    />

    <!-- 过滤栏 -->
    <el-card class="filter-card" shadow="never">
      <el-form inline :model="filterForm" @submit.prevent="onSearch">
        <el-form-item label="搜索">
          <el-input
            v-model="filterForm.search"
            clearable
            placeholder="姓名 / 邮箱"
            style="width: 220px"
            @keyup.enter="onSearch"
          />
        </el-form-item>
        <el-form-item label="角色">
          <el-select
            v-model="filterForm.role"
            clearable
            placeholder="全部"
            style="width: 160px"
          >
            <el-option
              v-for="(label, value) in USER_ROLE_LABELS"
              :key="value"
              :label="label"
              :value="value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="部门">
          <el-select
            v-model="filterForm.department_id"
            clearable
            filterable
            placeholder="全部"
            style="width: 220px"
          >
            <el-option
              v-for="d in departmentsStore.flatOptions"
              :key="d.id"
              :label="d.fullName"
              :value="d.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select
            v-model="filterForm.is_active"
            clearable
            placeholder="全部"
            style="width: 120px"
          >
            <el-option label="启用" :value="true" />
            <el-option label="停用" :value="false" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 列表 -->
    <el-card class="list-card" shadow="never">
      <el-table
        v-loading="store.loading"
        :data="store.list"
        stripe
        size="default"
        empty-text="暂无员工"
      >
        <el-table-column prop="name" label="姓名" min-width="120" />
        <el-table-column prop="email" label="邮箱" min-width="200" />
        <el-table-column label="角色" width="140">
          <template #default="{ row }">
            <el-tag :type="row.role === 'super_admin' ? 'danger' : 'info'">
              {{ USER_ROLE_LABELS[row.role as UserRole] ?? row.role }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="department_name" label="部门" min-width="160">
          <template #default="{ row }">
            {{ row.department_name ?? '—' }}
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'">
              {{ row.is_active ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="最近登录" width="170">
          <template #default="{ row }">
            {{ row.last_login_at ? formatDate(row.last_login_at) : '—' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="320" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="goDetail(row.id)">详情</el-button>
            <el-button link type="primary" @click="openRoleDialog(row)">角色</el-button>
            <el-button link type="primary" @click="openDeptDialog(row)">部门</el-button>
            <el-button
              link
              :type="row.is_active ? 'warning' : 'success'"
              @click="onToggleStatus(row)"
            >
              {{ row.is_active ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-if="store.meta && store.meta.total > 0"
        class="pagination"
        background
        :total="store.meta.total"
        :page-size="store.meta.pageSize"
        :current-page="store.meta.page"
        layout="total, prev, pager, next, sizes"
        :page-sizes="[20, 50, 100]"
        @current-change="onPageChange"
        @size-change="onPageSizeChange"
      />
    </el-card>

    <!-- 创建员工弹窗 -->
    <el-dialog v-model="createDialogVisible" title="新建员工" width="520px" @closed="onCreateDialogClosed">
      <el-form ref="createFormRef" :model="createForm" :rules="createRules" label-width="100px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="createForm.name" maxlength="100" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="createForm.email" placeholder="example@propos.cn" />
        </el-form-item>
        <el-form-item label="初始密码" prop="password">
          <el-input v-model="createForm.password" show-password placeholder="≥8 位，含大小写+数字" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="createForm.role" placeholder="选择角色" style="width: 100%">
            <el-option
              v-for="(label, value) in USER_ROLE_LABELS"
              :key="value"
              :label="label"
              :value="value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="所属部门" prop="department_id">
          <el-select
            v-model="createForm.department_id"
            placeholder="非二房东角色建议填写"
            filterable
            clearable
            style="width: 100%"
          >
            <el-option
              v-for="d in departmentsStore.activeOptions"
              :key="d.id"
              :label="d.fullName"
              :value="d.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createForm.role === 'sub_landlord'" label="绑定主合同" prop="bound_contract_id">
          <el-input v-model="createForm.bound_contract_id" placeholder="二房东主合同 ID（必填）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="store.loading" @click="onCreate">创建</el-button>
      </template>
    </el-dialog>

    <!-- 变更角色弹窗 -->
    <el-dialog v-model="roleDialogVisible" title="变更角色" width="460px">
      <div v-if="targetRow" class="dialog-tip">
        员工：<b>{{ targetRow.name }}</b>（{{ targetRow.email }}）
      </div>
      <el-form label-width="100px">
        <el-form-item label="新角色">
          <el-select v-model="roleForm.role" style="width: 100%">
            <el-option
              v-for="(label, value) in USER_ROLE_LABELS"
              :key="value"
              :label="label"
              :value="value"
            />
          </el-select>
        </el-form-item>
        <el-form-item v-if="roleForm.role === 'sub_landlord'" label="绑定主合同">
          <el-input v-model="roleForm.bound_contract_id" placeholder="二房东主合同 ID（必填）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="roleDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onChangeRole">确认变更</el-button>
      </template>
    </el-dialog>

    <!-- 变更部门弹窗 -->
    <el-dialog v-model="deptDialogVisible" title="变更部门" width="460px">
      <div v-if="targetRow" class="dialog-tip">
        员工：<b>{{ targetRow.name }}</b>（{{ targetRow.email }}）
      </div>
      <el-form label-width="100px">
        <el-form-item label="新部门">
          <el-select
            v-model="deptForm.department_id"
            placeholder="选择部门"
            filterable
            style="width: 100%"
          >
            <el-option
              v-for="d in departmentsStore.activeOptions"
              :key="d.id"
              :label="d.fullName"
              :value="d.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="deptDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onChangeDept">确认变更</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { Plus, Upload } from '@element-plus/icons-vue'
import dayjs from 'dayjs'
import { useUsersStore, useDepartmentsStore } from '@/stores'
import { USER_ROLE_LABELS } from '@/types/user'
import type { UserRole, UserSummary, UserListParams, UserCreateRequest } from '@/types/user'

const store = useUsersStore()
const departmentsStore = useDepartmentsStore()
const router = useRouter()

// ── 过滤 ────────────────────────────────────────────
const filterForm = reactive<UserListParams>({
  search: '',
  role: undefined,
  department_id: undefined,
  is_active: undefined,
  page: 1,
  pageSize: 20,
})

function onSearch(): void {
  store.load({ ...filterForm, page: 1 })
}

function onReset(): void {
  filterForm.search = ''
  filterForm.role = undefined
  filterForm.department_id = undefined
  filterForm.is_active = undefined
  filterForm.page = 1
  store.resetFilters()
  store.load(filterForm)
}

function onPageChange(page: number): void {
  store.load({ page })
}

function onPageSizeChange(pageSize: number): void {
  store.load({ page: 1, pageSize })
}

// ── 创建员工 ────────────────────────────────────────
const createDialogVisible = ref(false)
const createFormRef = ref<FormInstance>()
const createForm = reactive<UserCreateRequest>({
  name: '',
  email: '',
  password: '',
  role: 'leasing_specialist' as UserRole,
  department_id: null,
  bound_contract_id: null,
})

const createRules: FormRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '邮箱格式不正确', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入初始密码', trigger: 'blur' },
    { min: 8, message: '密码至少 8 位', trigger: 'blur' },
  ],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
}

function openCreateDialog(): void {
  createDialogVisible.value = true
}

function onCreateDialogClosed(): void {
  createForm.name = ''
  createForm.email = ''
  createForm.password = ''
  createForm.role = 'leasing_specialist' as UserRole
  createForm.department_id = null
  createForm.bound_contract_id = null
  createFormRef.value?.clearValidate()
}

async function onCreate(): Promise<void> {
  if (!createFormRef.value) return
  const valid = await createFormRef.value.validate().catch(() => false)
  if (!valid) return
  if (createForm.role === 'sub_landlord' && !createForm.bound_contract_id) {
    ElMessage.error('二房东角色必须填写绑定的主合同 ID')
    return
  }
  try {
    await store.create({
      ...createForm,
      department_id: createForm.department_id || null,
      bound_contract_id: createForm.bound_contract_id || null,
    })
    ElMessage.success('员工已创建')
    createDialogVisible.value = false
  } catch {
    // store.error 已显示
  }
}

// ── 启停用 ─────────────────────────────────────────
async function onToggleStatus(row: UserSummary): Promise<void> {
  const action = row.is_active ? '停用' : '启用'
  try {
    await ElMessageBox.confirm(`确认${action}员工 ${row.name}？`, '提示', { type: 'warning' })
  } catch {
    return
  }
  try {
    await store.toggleStatus(row.id, !row.is_active)
    ElMessage.success(`已${action}`)
  } catch {
    // store.error 显示
  }
}

// ── 变更角色 ────────────────────────────────────────
const targetRow = ref<UserSummary | null>(null)
const roleDialogVisible = ref(false)
const roleForm = reactive<{ role: UserRole; bound_contract_id: string }>({
  role: 'leasing_specialist',
  bound_contract_id: '',
})

function openRoleDialog(row: UserSummary): void {
  targetRow.value = row
  roleForm.role = row.role
  roleForm.bound_contract_id = ''
  roleDialogVisible.value = true
}

async function onChangeRole(): Promise<void> {
  if (!targetRow.value) return
  if (roleForm.role === 'sub_landlord' && !roleForm.bound_contract_id) {
    ElMessage.error('二房东角色必须填写绑定的主合同 ID')
    return
  }
  try {
    await store.changeRole(
      targetRow.value.id,
      roleForm.role,
      roleForm.role === 'sub_landlord' ? roleForm.bound_contract_id : null,
    )
    ElMessage.success('角色已变更')
    roleDialogVisible.value = false
  } catch {
    // store.error 显示
  }
}

// ── 变更部门 ────────────────────────────────────────
const deptDialogVisible = ref(false)
const deptForm = reactive<{ department_id: string }>({ department_id: '' })

function openDeptDialog(row: UserSummary): void {
  targetRow.value = row
  deptForm.department_id = row.department_id ?? ''
  deptDialogVisible.value = true
}

async function onChangeDept(): Promise<void> {
  if (!targetRow.value || !deptForm.department_id) {
    ElMessage.error('请选择部门')
    return
  }
  try {
    await store.changeDepartment(targetRow.value.id, deptForm.department_id)
    ElMessage.success('部门已变更')
    deptDialogVisible.value = false
  } catch {
    // store.error 显示
  }
}

// ── 跳转 ───────────────────────────────────────────
function goDetail(id: string): void {
  router.push({ name: 'user-detail', params: { id } })
}

function goImport(): void {
  router.push({ name: 'user-import' })
}

// ── 工具 ───────────────────────────────────────────
function formatDate(value: string): string {
  return dayjs(value).format('YYYY-MM-DD HH:mm')
}

// ── 初始化 ─────────────────────────────────────────
onMounted(async () => {
  await departmentsStore.load()
  await store.load()
})
</script>

<style scoped>
.users-view { padding: 24px 28px; }

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
}

.page-header .title {
  font-family: var(--apple-font-display);
  font-size: 26px;
  font-weight: 600;
  letter-spacing: -0.5px;
  color: var(--apple-near-black);
  margin: 0;
}

.actions { display: flex; gap: 8px; }

.alert { margin-bottom: 12px; }

.filter-card { margin-bottom: 16px; }

.list-card :deep(.el-table) { margin-top: 4px; }

.pagination {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

.dialog-tip {
  margin-bottom: 12px;
  font-size: 13px;
  color: var(--apple-text-secondary);
  letter-spacing: -0.1px;
  padding: 10px 12px;
  background: rgba(0, 113, 227, 0.05);
  border-radius: 8px;
  border-left: 3px solid var(--apple-blue);
}
</style>
