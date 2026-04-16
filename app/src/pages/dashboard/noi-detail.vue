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
      <PageHeader title="NOI 分析" :back="true" />
    </template>

    <view class="noi-detail">
      <text class="noi-detail__placeholder">NOI 分析详情占位</text>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()
</script>

<style lang="scss" scoped>
.noi-detail__placeholder {
  @include text-caption;
  text-align: center;
  display: block;
  margin-top: 200rpx;
}
</style>
