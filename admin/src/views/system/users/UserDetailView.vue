<template>
  <div class="user-detail-view">
    <el-page-header @back="goBack">
      <template #content>
        <span class="title">员工详情</span>
      </template>
    </el-page-header>

    <el-alert
      v-if="store.error"
      type="error"
      :title="store.error"
      show-icon
      :closable="false"
      class="alert"
    />

    <el-card v-loading="store.loading" class="detail-card" shadow="never">
      <template v-if="store.item">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="姓名">{{ store.item.name }}</el-descriptions-item>
          <el-descriptions-item label="邮箱">{{ store.item.email }}</el-descriptions-item>
          <el-descriptions-item label="角色">
            {{ USER_ROLE_LABELS[store.item.role] ?? store.item.role }}
          </el-descriptions-item>
          <el-descriptions-item label="所属部门">
            {{ store.item.department_name ?? '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="store.item.is_active ? 'success' : 'info'">
              {{ store.item.is_active ? '启用' : '停用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="登录失败次数">
            {{ store.item.failed_login_attempts }}
          </el-descriptions-item>
          <el-descriptions-item label="锁定截止">
            {{ store.item.locked_until ? formatDate(store.item.locked_until) : '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="最近登录">
            {{ store.item.last_login_at ? formatDate(store.item.last_login_at) : '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="最近改密">
            {{ store.item.password_changed_at ? formatDate(store.item.password_changed_at) : '—' }}
          </el-descriptions-item>
          <el-descriptions-item label="冻结时间">
            {{ store.item.frozen_at ? formatDate(store.item.frozen_at) : '—' }}
          </el-descriptions-item>
          <el-descriptions-item v-if="store.item.bound_contract_id" label="绑定主合同">
            {{ store.item.bound_contract_id }}
          </el-descriptions-item>
          <el-descriptions-item v-if="store.item.frozen_reason" label="冻结原因">
            {{ store.item.frozen_reason }}
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatDate(store.item.created_at) }}
          </el-descriptions-item>
          <el-descriptions-item label="更新时间">
            {{ formatDate(store.item.updated_at) }}
          </el-descriptions-item>
        </el-descriptions>

        <div class="actions">
          <el-button type="primary" @click="openEditDialog">编辑基本信息</el-button>
        </div>
      </template>

      <el-empty v-else description="未找到员工" />
    </el-card>

    <!-- 编辑基本信息 -->
    <el-dialog v-model="editDialogVisible" title="编辑员工" width="460px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="姓名">
          <el-input v-model="editForm.name" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="editForm.email" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import dayjs from 'dayjs'
import { useUserDetailStore, useUsersStore } from '@/stores'
import { USER_ROLE_LABELS } from '@/types/user'

const store = useUserDetailStore()
const usersStore = useUsersStore()
const route = useRoute()
const router = useRouter()

const id = route.params.id as string

const editDialogVisible = ref(false)
const editForm = reactive({ name: '', email: '' })

function formatDate(value: string): string {
  return dayjs(value).format('YYYY-MM-DD HH:mm')
}

function goBack(): void {
  router.back()
}

function openEditDialog(): void {
  if (!store.item) return
  editForm.name = store.item.name
  editForm.email = store.item.email
  editDialogVisible.value = true
}

async function onSave(): Promise<void> {
  try {
    await usersStore.update(id, { name: editForm.name, email: editForm.email })
    ElMessage.success('已保存')
    editDialogVisible.value = false
    await store.load(id)
  } catch {
    // store.error
  }
}

onMounted(() => {
  store.load(id)
})
</script>

<style scoped>
.user-detail-view { padding: 24px 28px; }

.alert { margin: 12px 0; }

.detail-card { margin-top: 16px; }

.actions {
  margin-top: 20px;
  display: flex;
  gap: 8px;
}
</style>
