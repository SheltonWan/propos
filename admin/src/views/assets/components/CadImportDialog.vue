<!--
  CadImportDialog — 楼栋级 DXF 上传 + 异步切分 + 未匹配指派对话框（Day 14 任务 14.3）

  用户流程：
    1. 选择 DXF 文件 → 点「上传并切分」
    2. 后端立即返回任务 ID，前端每 2 秒轮询一次状态
    3. 切分完成后：
       - 已匹配数量 + 未匹配 SVG 列表（带楼层下拉 + 指派按钮）
       - 失败时显示 error_message
    4. 用户可对每个未匹配 SVG 选择楼层并点「指派」，列表自动刷新
    5. 关闭对话框时调用 store.reset() 清理 polling timer
-->
<template>
  <el-dialog
    v-model="visible"
    title="导入 DXF 楼层平面图"
    width="720px"
    :close-on-click-modal="false"
    @closed="handleClosed"
  >
    <!-- ─── Step 1：上传区 ───────────────────────────────────── -->
    <div v-if="!store.job" class="upload-zone">
      <el-alert type="info" :closable="false" class="tip">
        <template #title>
          <span>
            上传整栋 <b>.dxf</b> 文件，系统将自动按「X 层平面图」标题切分为单层 SVG 并匹配楼层。
            <b>不接受 .dwg 格式</b>，请先在 CAD 软件中另存为 DXF 后再上传。
          </span>
        </template>
      </el-alert>

      <el-upload
        class="upload"
        drag
        action="#"
        :auto-upload="false"
        :show-file-list="true"
        :limit="1"
        accept=".dxf,.DXF"
        :on-change="onFileChange"
        :on-exceed="onExceed"
        :file-list="fileList"
      >
        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
        <div class="el-upload__text">
          将 DXF 文件拖拽到此处，或<em>点击选择</em>
        </div>
        <template #tip>
          <div class="tip-sm">单个文件最大 50MB；切分耗时通常 1-2 分钟，请勿关闭此页。</div>
        </template>
      </el-upload>

      <div v-if="store.error" class="error-msg">
        <el-alert :title="store.error" type="error" show-icon :closable="false" />
      </div>
    </div>

    <!-- ─── Step 2：处理中（切分中） ───────────────────────────── -->
    <div v-else-if="store.isProcessing" class="processing">
      <el-result icon="info" title="正在切分 DXF…" :sub-title="processingSubtitle">
        <template #extra>
          <el-progress :percentage="processingPct" :indeterminate="true" :duration="3" />
          <div class="hint">大文件可能耗时数分钟；状态每 2 秒自动刷新一次。</div>
        </template>
      </el-result>
    </div>

    <!-- ─── Step 3：失败 ────────────────────────────────────────── -->
    <div v-else-if="store.job.status === 'failed'" class="failed">
      <el-result
        icon="error"
        title="切分失败"
        :sub-title="store.job.error_message ?? '未知错误'"
      >
        <template #extra>
          <el-button type="primary" @click="store.reset()">重新选择文件</el-button>
        </template>
      </el-result>
    </div>

    <!-- ─── Step 4：完成 ────────────────────────────────────────── -->
    <div v-else class="done">
      <el-alert
        :title="`切分完成：已自动匹配 ${store.job.matched_count} 个楼层` +
          (store.job.unmatched_svgs.length > 0
            ? `；剩余 ${store.job.unmatched_svgs.length} 个 SVG 待手动指派`
            : '；全部匹配成功')"
        :type="store.job.unmatched_svgs.length > 0 ? 'warning' : 'success'"
        show-icon
        :closable="false"
      />

      <div v-if="store.job.unmatched_svgs.length > 0" class="unmatched-section">
        <h4>未匹配 SVG 列表</h4>
        <p class="hint">
          下列 SVG 未能根据文件名自动匹配楼层（常见于「负一层」「夹层」等非数字命名），
          请逐个选择目标楼层并点「指派」。指派后 SVG 将复制到该楼层并设为当前生效图纸。
        </p>

        <el-table :data="store.job.unmatched_svgs" stripe size="default">
          <el-table-column label="SVG 标识" prop="label" width="180" />
          <el-table-column label="临时路径" min-width="260">
            <template #default="{ row }">
              <span class="path">{{ row.tmp_path }}</span>
            </template>
          </el-table-column>
          <el-table-column label="目标楼层" width="180">
            <template #default="{ row }">
              <el-select
                v-model="floorSelections[row.label]"
                placeholder="选择楼层"
                size="small"
                style="width: 100%"
              >
                <el-option
                  v-for="f in floorOptions"
                  :key="f.id"
                  :label="floorLabel(f)"
                  :value="f.id"
                />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" align="center">
            <template #default="{ row }">
              <el-button
                type="primary"
                size="small"
                :loading="assigningLabel === row.label"
                :disabled="!floorSelections[row.label]"
                @click="onAssign(row.label)"
              >
                指派
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div v-if="store.error" class="error-msg">
          <el-alert :title="store.error" type="error" show-icon :closable="false" />
        </div>
      </div>
    </div>

    <template #footer>
      <el-button @click="visible = false">关闭</el-button>
      <el-button
        v-if="!store.job"
        type="primary"
        :loading="store.loading"
        :disabled="!selectedFile"
        @click="onUpload"
      >
        上传并切分
      </el-button>
      <el-button v-else-if="store.job.status === 'done'" type="success" @click="onFinish">
        完成
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import type { UploadFile, UploadFiles, UploadUserFile } from 'element-plus'
import { useCadImportStore } from '@/stores'
import type { Floor } from '@/types/asset'

const props = defineProps<{
  modelValue: boolean
  buildingId: string
  /** 楼栋下的所有楼层（来自父页 BuildingDetailView 的 store.floors） */
  floors: Floor[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void
  /** 切分完成且用户点「完成」时触发，父页应刷新楼层数据 */
  (e: 'finished'): void
}>()

const store = useCadImportStore()

const visible = ref(props.modelValue)
watch(() => props.modelValue, (v) => (visible.value = v))
watch(visible, (v) => emit('update:modelValue', v))

const selectedFile = ref<File | null>(null)
const fileList = ref<UploadUserFile[]>([])

/** 楼层 -> 选中目标 floor_id 的映射（key 为 svg label） */
const floorSelections = reactive<Record<string, string>>({})

/** 当前正在指派的 SVG label（用于按钮 loading） */
const assigningLabel = ref<string | null>(null)

const floorOptions = computed<Floor[]>(() =>
  [...props.floors].sort((a, b) => b.floor_number - a.floor_number),
)

const processingSubtitle = computed(() => {
  if (store.job?.status === 'uploaded') return 'DXF 已上传，正在排队等待切分…'
  if (store.job?.status === 'splitting') return '正在调用 ezdxf 切分图纸，请稍候…'
  return ''
})

const processingPct = computed(() => (store.job?.status === 'splitting' ? 60 : 20))

function floorLabel(f: Floor): string {
  const numLabel = f.floor_number > 0 ? `F${f.floor_number}` : `B${Math.abs(f.floor_number)}`
  return f.floor_name ? `${numLabel} · ${f.floor_name}` : numLabel
}

function onFileChange(file: UploadFile, _files: UploadFiles): void {
  if (!file.raw) return
  // 双重校验扩展名（el-upload accept 不强制）
  const name = file.name.toLowerCase()
  if (!name.endsWith('.dxf')) {
    ElMessage.warning('请上传 .dxf 文件，不接受 .dwg 等其他格式')
    fileList.value = []
    selectedFile.value = null
    return
  }
  selectedFile.value = file.raw
  fileList.value = [file]
}

function onExceed(): void {
  ElMessage.warning('一次只能上传一个 DXF 文件，请先移除当前文件')
}

async function onUpload(): Promise<void> {
  if (!selectedFile.value) return
  const job = await store.upload(props.buildingId, selectedFile.value)
  if (job) {
    ElMessage.success('DXF 已上传，正在后台切分')
  }
}

async function onAssign(label: string): Promise<void> {
  const floorId = floorSelections[label]
  if (!floorId) return
  assigningLabel.value = label
  const ok = await store.assign(label, floorId)
  assigningLabel.value = null
  if (ok) {
    ElMessage.success(`已指派 ${label} 到目标楼层`)
    delete floorSelections[label]
  }
}

function onFinish(): void {
  visible.value = false
  emit('finished')
}

function handleClosed(): void {
  // 关闭时清理 polling timer + 状态，但只在用户已完成查看后才重置
  // 若任务仍在 processing，保留 store 状态以便下次重新打开继续轮询
  if (store.isFinished || !store.job) {
    store.reset()
    selectedFile.value = null
    fileList.value = []
    for (const k of Object.keys(floorSelections)) delete floorSelections[k]
  }
}
</script>

<style scoped>
.upload-zone .tip { margin-bottom: 16px; }

.upload { margin-top: 8px; }

.tip-sm {
  font-size: 12px;
  color: var(--apple-text-secondary);
  margin-top: 4px;
  letter-spacing: -0.1px;
}

.error-msg { margin-top: 16px; }

.processing { padding: 24px 0; }

.processing .hint {
  margin-top: 12px;
  font-size: 12px;
  color: var(--apple-text-secondary);
  text-align: center;
  letter-spacing: -0.1px;
}

.failed { padding: 12px 0; }

.done .unmatched-section { margin-top: 16px; }

.done h4 {
  margin: 0 0 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--apple-near-black);
  letter-spacing: -0.2px;
}

.done .hint {
  margin: 0 0 12px;
  font-size: 12px;
  color: var(--apple-text-secondary);
  line-height: 1.5;
  letter-spacing: -0.1px;
}

.path {
  font-family: ui-monospace, 'SFMono-Regular', Menlo, monospace;
  font-size: 12px;
  color: var(--apple-near-black);
  background: var(--apple-light-gray);
  padding: 2px 6px;
  border-radius: 4px;
}
</style>
