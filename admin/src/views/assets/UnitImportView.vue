<template>
  <div class="unit-import">
    <el-page-header class="header" @back="goBack">
      <template #content>
        <span class="title">批量导入单元台账</span>
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

    <!-- 步骤条 -->
    <el-steps :active="currentStep" align-center finish-status="success" class="steps">
      <el-step title="选择文件" description="上传 Excel 文件" />
      <el-step title="预校验" description="试导入校验" />
      <el-step title="确认导入" description="正式入库" />
    </el-steps>

    <!-- 步骤① 选择文件 -->
    <el-card v-if="currentStep === 0" class="step-card" shadow="never">
      <div class="form-row">
        <div class="row-label">数据类型</div>
        <el-select v-model="dataType" disabled style="width: 220px">
          <el-option label="单元台账" value="units" />
        </el-select>
      </div>

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
          <div class="upload-tip">支持 .xlsx / .xls / .csv，单元台账导入采用整批回滚模式</div>
        </template>
      </el-upload>

      <div class="template-row">
        <el-icon><Document /></el-icon>
        <span>下载导入模板：</span>
        <el-button type="primary" link @click="onDownloadTemplate('office')">写字楼</el-button>
        <el-divider direction="vertical" />
        <el-button type="primary" link @click="onDownloadTemplate('retail')">商铺</el-button>
        <el-divider direction="vertical" />
        <el-button type="primary" link @click="onDownloadTemplate('apartment')">公寓</el-button>
        <span class="template-hint">CSV / Excel 格式均可直接上传</span>
      </div>

      <div class="actions">
        <el-button :disabled="!store.file" type="primary" :loading="store.loading" @click="onDryRun">
          下一步：执行预校验
        </el-button>
      </div>
    </el-card>

    <!-- 步骤② 预校验结果 -->
    <el-card v-if="currentStep === 1" class="step-card" shadow="never">
      <div v-if="store.dryRunResult" class="dry-run-summary">
        <div>
          <span class="metric-label">总记录数</span>
          <span class="metric-value">{{ store.dryRunResult.total_records }}</span>
        </div>
        <div>
          <span class="metric-label">校验通过</span>
          <span class="metric-value success">{{ store.dryRunResult.success_count }}</span>
        </div>
        <div>
          <span class="metric-label">错误条目</span>
          <span class="metric-value danger">{{ store.dryRunResult.failure_count }}</span>
        </div>
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
        <el-button @click="goBackStep">上一步</el-button>
        <el-button
          type="primary"
          :disabled="commitDisabled"
          :loading="store.loading"
          @click="onCommit"
        >
          下一步：确认导入
        </el-button>
      </div>
    </el-card>

    <!-- 步骤③ 确认导入结果 -->
    <el-card v-if="currentStep === 2" class="step-card" shadow="never">
      <el-result
        :icon="commitIcon"
        :title="commitTitle"
        :sub-title="commitSubtitle"
      >
        <template #extra>
          <el-button @click="onReset">再次导入</el-button>
          <el-button type="primary" @click="goAssets">返回资产列表</el-button>
        </template>
      </el-result>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Document, UploadFilled } from '@element-plus/icons-vue'
import type { UploadFile } from 'element-plus'
import { useUnitImportStore } from '@/stores'
import { downloadUnitImportTemplate } from './utils/unit_import_template'
import type { PropertyType } from '@/types/asset'

const store = useUnitImportStore()
const router = useRouter()

const dataType = ref<'units'>('units')
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

function goBackStep(): void {
  store.reset()
  fileList.value = []
}

function onReset(): void {
  store.reset()
  fileList.value = []
}

function goBack(): void {
  router.push({ name: 'assets' })
}

function goAssets(): void {
  store.reset()
  router.push({ name: 'assets' })
}

function onDownloadTemplate(t: PropertyType): void {
  downloadUnitImportTemplate(t)
}
</script>

<style scoped>
.unit-import { padding: 24px; }
.header { margin-bottom: 16px; }
.title { font-size: 18px; font-weight: 600; }
.alert { margin-bottom: 16px; }
.steps { margin: 16px 0 24px; max-width: 720px; }
.step-card { margin-bottom: 24px; }
.form-row {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-bottom: 16px;
}
.row-label { font-size: 14px; color: var(--el-text-color-regular); }
.uploader { margin: 16px 0; }
.upload-icon { font-size: 56px; color: var(--el-color-primary); }
.upload-text { color: var(--el-text-color-regular); margin-top: 8px; font-size: 14px; }
.upload-tip { color: var(--el-text-color-secondary); font-size: 12px; }
.template-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 12px 16px;
  margin-top: 8px;
  background: var(--el-fill-color-light);
  border-radius: 4px;
  font-size: 13px;
  color: var(--el-text-color-regular);
}
.template-hint {
  margin-left: 8px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 16px;
}
.dry-run-summary {
  display: flex;
  gap: 32px;
  margin-bottom: 16px;
  padding: 12px 16px;
  background: var(--el-fill-color-light);
  border-radius: 4px;
}
.metric-label {
  display: block;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.metric-value {
  font-size: 24px;
  font-weight: 600;
}
.metric-value.success { color: var(--el-color-success); }
.metric-value.danger { color: var(--el-color-danger); }
</style>
