<template>
  <div class="departments-view">
    <div class="page-header">
      <h2 class="title">组织架构管理</h2>
      <div class="actions">
        <el-button @click="goImport">
          <el-icon><Upload /></el-icon> 批量导入
        </el-button>
        <el-button type="primary" @click="openCreateDialog(null)">
          <el-icon><Plus /></el-icon> 新建顶级部门
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

    <el-card v-loading="store.loading" class="tree-card" shadow="never">
      <el-tree
        v-if="store.tree.length"
        :data="store.tree"
        node-key="id"
        :props="{ label: 'name', children: 'children' }"
        default-expand-all
      >
        <template #default="{ node, data }">
          <div class="tree-node">
            <span class="node-name">
              {{ data.name }}
              <el-tag size="small" type="info" class="level-tag">L{{ data.level }}</el-tag>
              <el-tag v-if="!data.is_active" size="small" type="info" class="level-tag">已停用</el-tag>
            </span>
            <span class="node-actions" @click.stop>
              <el-button
                v-if="data.level < 3 && data.is_active"
                link
                type="primary"
                size="small"
                @click="openCreateDialog(data)"
              >
                添加子部门
              </el-button>
              <el-button link type="primary" size="small" @click="openEditDialog(data)">
                编辑
              </el-button>
              <el-button
                v-if="data.is_active"
                link
                type="danger"
                size="small"
                @click="onDeactivate(data)"
              >
                停用
              </el-button>
            </span>
          </div>
        </template>
      </el-tree>
      <el-empty v-else description="暂无部门，点击右上角新建顶级部门" />
    </el-card>

    <!-- 创建 / 编辑 弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新建部门' : '编辑部门'" width="500px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="部门名称" prop="name">
          <el-input v-model="form.name" maxlength="100" />
        </el-form-item>
        <el-form-item label="父部门">
          <el-select
            v-model="form.parent_id"
            clearable
            placeholder="留空表示顶级"
            filterable
            style="width: 100%"
            :disabled="dialogMode === 'edit' && form.id === currentRootId"
          >
            <el-option
              v-for="d in selectableParents"
              :key="d.id"
              :label="d.fullName"
              :value="d.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="排序号">
          <el-input-number v-model="form.sort_order" :min="0" :max="9999" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { Plus, Upload } from '@element-plus/icons-vue'
import { useDepartmentsStore } from '@/stores'
import type { DepartmentTree } from '@/types/department'

const store = useDepartmentsStore()
const router = useRouter()

const dialogVisible = ref(false)
const dialogMode = ref<'create' | 'edit'>('create')
const formRef = ref<FormInstance>()
const currentRootId = ref<string | null>(null)

const form = reactive<{ id: string; name: string; parent_id: string | null; sort_order: number }>({
  id: '',
  name: '',
  parent_id: null,
  sort_order: 0,
})

const rules: FormRules = {
  name: [{ required: true, message: '请输入部门名称', trigger: 'blur' }],
}

/** 编辑模式下，父部门可选项需排除自身及其后代（防止循环） */
const selectableParents = computed(() => {
  if (dialogMode.value === 'create') {
    return store.flatOptions.filter((n) => n.is_active && n.level < 3)
  }
  // 编辑：排除自身和子孙
  const excluded = collectDescendantIds(store.tree, form.id)
  return store.flatOptions.filter(
    (n) => n.is_active && n.level < 3 && !excluded.includes(n.id),
  )
})

function collectDescendantIds(tree: DepartmentTree[], targetId: string): string[] {
  const result: string[] = []
  function walk(nodes: DepartmentTree[], inside: boolean): void {
    for (const node of nodes) {
      if (inside || node.id === targetId) {
        result.push(node.id)
        if (node.children?.length) walk(node.children, true)
      } else if (node.children?.length) {
        walk(node.children, false)
      }
    }
  }
  walk(tree, false)
  return result
}

function openCreateDialog(parent: DepartmentTree | null): void {
  dialogMode.value = 'create'
  currentRootId.value = null
  form.id = ''
  form.name = ''
  form.parent_id = parent?.id ?? null
  form.sort_order = 0
  dialogVisible.value = true
  formRef.value?.clearValidate()
}

function openEditDialog(node: DepartmentTree): void {
  dialogMode.value = 'edit'
  currentRootId.value = node.id
  form.id = node.id
  form.name = node.name
  form.parent_id = node.parent_id
  form.sort_order = node.sort_order
  dialogVisible.value = true
  formRef.value?.clearValidate()
}

async function onSave(): Promise<void> {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  try {
    if (dialogMode.value === 'create') {
      await store.create({
        name: form.name,
        parent_id: form.parent_id || null,
        sort_order: form.sort_order,
      })
      ElMessage.success('部门已创建')
    } else {
      await store.update(form.id, {
        name: form.name,
        parent_id: form.parent_id || null,
        sort_order: form.sort_order,
      })
      ElMessage.success('部门已更新')
    }
    dialogVisible.value = false
  } catch {
    // store.error
  }
}

async function onDeactivate(node: DepartmentTree): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确认停用部门 "${node.name}"？停用后该部门将不再可选。`,
      '停用部门',
      { type: 'warning' },
    )
  } catch {
    return
  }
  try {
    await store.deactivate(node.id)
    ElMessage.success('部门已停用')
  } catch {
    // store.error 已显示
  }
}

function goImport(): void {
  router.push({ name: 'department-import' })
}

onMounted(() => {
  store.load()
})
</script>

<style scoped>
.departments-view { padding: 24px 28px; }

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

.alert { margin-bottom: 12px; }

.tree-card { min-height: 400px; }

.tree-node {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-right: 12px;
}

.node-name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: var(--apple-near-black);
  letter-spacing: -0.2px;
}

.level-tag { margin-left: 4px; }

.node-actions {
  display: flex;
  gap: 4px;
}
</style>
