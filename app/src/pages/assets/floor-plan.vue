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
      <PageHeader title="楼层平面图" :back="true" />
    </template>

    <view class="floor-plan">
      <text class="floor-plan__placeholder">楼层平面图占位</text>
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
.floor-plan__placeholder {
  @include text-caption;
  text-align: center;
  display: block;
  margin-top: 200rpx;
}
</style>
