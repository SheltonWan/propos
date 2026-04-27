<template>
  <div class="user-import">
    <el-page-header @back="goBack">
      <template #content>
        <span class="title">批量导入员工账号</span>
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

    <el-steps :active="currentStep" align-center finish-status="success" class="steps">
      <el-step title="选择文件" description="上传 Excel" />
      <el-step title="预校验" description="dry_run 校验" />
      <el-step title="确认导入" description="正式入库" />
    </el-steps>

    <el-card v-if="currentStep === 0" class="step-card" shadow="never">
      <el-upload
        class="uploader"
        drag
        :auto-upload="false"
        :limit="1"
        accept=".xlsx,.xls,.csv"
        :file-list="fileList"
        :on-change="onFileChange"
        :on-remove="onFileRemove"
      >
        <el-icon class="upload-icon"><UploadFilled /></el-icon>
        <div class="upload-text">点击或拖拽上传 Excel 文件</div>
        <template #tip>
          <div class="upload-tip">
            支持 .xlsx / .xls / .csv。模板列：姓名、邮箱、初始密码、角色（英文标识）、部门名称、主合同编号（仅二房东角色）
          </div>
        </template>
      </el-upload>

      <div class="template-row">
        <el-button type="primary" link @click="onDownloadTemplate">下载导入模板（CSV）</el-button>
        <span class="template-hint">CSV 用 Excel 打开后另存为 .xlsx 再上传</span>
      </div>

      <div class="actions">
        <el-button :disabled="!store.file" type="primary" :loading="store.loading" @click="onDryRun">
          下一步：执行预校验
        </el-button>
      </div>
    </el-card>

    <el-card v-if="currentStep === 1" class="step-card" shadow="never">
      <div v-if="store.dryRunResult" class="dry-run-summary">
        <div><span class="metric-label">总记录数</span><span class="metric-value">{{ store.dryRunResult.total_records }}</span></div>
        <div><span class="metric-label">校验通过</span><span class="metric-value success">{{ store.dryRunResult.success_count }}</span></div>
        <div><span class="metric-label">错误条目</span><span class="metric-value danger">{{ store.dryRunResult.failure_count }}</span></div>
      </div>
      <el-table
        v-if="(store.dryRunResult?.error_details ?? []).length > 0"
        :data="store.dryRunResult?.error_details ?? []"
        size="small"
        stripe
        max-height="320"
      >
        <el-table-column prop="row" label="行号" width="80" />
        <el-table-column prop="field" label="字段" width="160" />
        <el-table-column prop="error" label="错误原因" />
      </el-table>
      <el-empty v-else description="暂无错误明细" />

      <div class="actions">
        <el-button @click="onReset">上一步</el-button>
        <el-button type="primary" :disabled="commitDisabled" :loading="store.loading" @click="onCommit">
          下一步：确认导入
        </el-button>
      </div>
    </el-card>

    <el-card v-if="currentStep === 2" class="step-card" shadow="never">
      <el-result :icon="commitIcon" :title="commitTitle" :sub-title="commitSubtitle">
        <template #extra>
          <el-button @click="onReset">再次导入</el-button>
          <el-button type="primary" @click="goBack">返回员工列表</el-button>
        </template>
      </el-result>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { UploadFilled } from '@element-plus/icons-vue'
import type { UploadFile } from 'element-plus'
import { useUserImportStore } from '@/stores'

const store = useUserImportStore()
const router = useRouter()

const fileList = ref<UploadFile[]>([])

const currentStep = computed<number>(() => {
  if (store.commitResult) return 2
  if (store.dryRunResult) return 1
  return 0
})

const commitDisabled = computed<boolean>(() => {
  const r = store.dryRunResult
  return !r || r.failure_count > 0 || r.success_count === 0
})

const commitIcon = computed<'success' | 'error'>(() =>
  store.commitResult && store.commitResult.failure_count === 0 ? 'success' : 'error',
)

const commitTitle = computed<string>(() => {
  const r = store.commitResult
  if (!r) return '导入完成'
  if (r.rollback_status === 'rolled_back') return '导入已整批回滚'
  return `已成功导入 ${r.success_count} 条`
})

const commitSubtitle = computed<string>(() => {
  const r = store.commitResult
  if (!r) return ''
  return `批次号：${r.batch_name} · 总数 ${r.total_records} · 失败 ${r.failure_count}`
})

function onFileChange(file: UploadFile): void {
  if (file.raw) {
    store.setFile(file.raw as File)
    fileList.value = [file]
  }
}

function onFileRemove(): void {
  store.setFile(null)
  fileList.value = []
}

async function onDryRun(): Promise<void> {
  await store.dryRun()
}

async function onCommit(): Promise<void> {
  await store.commit()
}

function onReset(): void {
  store.reset()
  fileList.value = []
}

function onDownloadTemplate(): void {
  const headers = ['姓名', '邮箱', '初始密码', '角色', '部门名称', '主合同编号']
  const sample = ['张三', 'zhangsan@propos.cn', 'Init@1234', 'leasing_specialist', '写字楼组', '']
  const csv = [headers.join(','), sample.join(',')].join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'users_import_template.csv'
  a.click()
  URL.revokeObjectURL(url)
}

function goBack(): void {
  router.push({ name: 'users' })
}
</script>

<style scoped>
.user-import {
  padding: 16px;
}
.alert {
  margin: 12px 0;
}
.steps {
  margin: 16px 0;
}
.step-card {
  margin-top: 12px;
}
.uploader {
  margin-top: 12px;
}
.upload-icon {
  font-size: 48px;
  color: var(--el-color-primary);
}
.upload-text {
  font-size: 14px;
  margin-top: 8px;
}
.upload-tip {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-top: 4px;
}
.template-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
}
.template-hint {
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.actions {
  margin-top: 20px;
  display: flex;
  gap: 8px;
}
.dry-run-summary {
  display: flex;
  gap: 32px;
  margin-bottom: 16px;
}
.metric-label {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-right: 6px;
}
.metric-value {
  font-size: 18px;
  font-weight: 600;
}
.metric-value.success {
  color: var(--el-color-success);
}
.metric-value.danger {
  color: var(--el-color-danger);
}
</style>
