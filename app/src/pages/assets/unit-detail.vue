<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell>
    <template #header>
      <PageHeader title="房源详情" :back="true" :animated="false" />
    </template>

    <view class="unit-detail">
      <AppCard :state="cardState" :animated="false" class="unit-detail__card">
        <template #empty>
          <text class="unit-detail__placeholder">未找到房源</text>
        </template>
        <template #error>
          <text class="unit-detail__placeholder">{{ store.error || '加载失败' }}</text>
          <view class="unit-detail__retry" @tap="reload">
            <text class="unit-detail__retry-text">点击重试</text>
          </view>
        </template>

        <view v-if="unit" class="unit-detail__body">
          <UnitHeaderSection :unit="unit" />
          <UnitMetricsSection :unit="unit" />
          <UnitInfoList :unit="unit" />

          <!-- 当前合同 -->
          <view v-if="unit.current_contract_id" class="contract-link" @tap="onContractTap">
            <text class="contract-link__label">关联合同</text>
            <text class="contract-link__action">查看 ›</text>
          </view>
        </view>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import UnitHeaderSection from '@/components/assets/UnitHeaderSection.vue'
import UnitMetricsSection from '@/components/assets/UnitMetricsSection.vue'
import UnitInfoList from '@/components/assets/UnitInfoList.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'
import { useUnitDetailStore } from '@/stores/assetsStore'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()

const store = useUnitDetailStore()
const unit = computed(() => store.item)

const cardState = computed<'default' | 'loading' | 'empty' | 'error'>(() => {
  if (store.loading) return 'loading'
  if (store.error) return 'error'
  if (!unit.value) return 'empty'
  return 'default'
})

function onContractTap() {
  if (!unit.value?.current_contract_id) return
  uni.navigateTo({ url: `/pages/contracts/detail?id=${unit.value.current_contract_id}` })
}

async function reload() {
  if (unit.value?.id) {
    await store.fetchDetail(unit.value.id)
  }
}

onLoad((options) => {
  const opts = (options ?? {}) as { id?: string }
  if (opts.id) store.fetchDetail(opts.id)
})
</script>

<style lang="scss" scoped>
.unit-detail {
  padding: $space-page-y $space-page-x;
}

.unit-detail__placeholder {
  @include text-caption;
  display: block;
  text-align: center;
  margin: 60rpx 0;
}

.unit-detail__retry {
  text-align: center;
  margin-top: $space-gap-sm;
}

.unit-detail__retry-text {
  @include text-caption;
  color: var(--color-primary);
}

.unit-detail__body {
  display: flex;
  flex-direction: column;
  gap: $space-gap-md;
}

.contract-link {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $space-gap-md;
  border-radius: $radius-control;
  background: var(--color-primary-soft);
}

.contract-link__label {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--color-foreground);
}

.contract-link__action {
  font-size: 26rpx;
  color: var(--color-primary);
}
</style>
