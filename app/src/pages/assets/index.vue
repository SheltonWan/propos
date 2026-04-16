<template>
  <page-meta
    :background-text-style="pageMetaTextStyle"
    :background-color="pageMetaBackgroundColor"
    :background-color-top="pageMetaBackgroundColor"
    :background-color-bottom="pageMetaBackgroundColor"
    :root-background-color="pageMetaRootBackgroundColor"
    :page-style="pageMetaPageStyle"
  />
  <AppShell with-tabbar>
    <template #header>
      <PageHeader title="资产" :sticky="true" :back="false" :animated="false" />
    </template>

    <view class="assets">
      <AppCard class="assets__placeholder-card" :animated="false">
        <text class="assets__placeholder">资产列表占位</text>
      </AppCard>
    </view>
  </AppShell>
</template>

<script setup lang="ts">
import AppCard from '@/components/base/AppCard.vue'
import AppShell from '@/components/base/AppShell.vue'
import PageHeader from '@/components/base/PageHeader.vue'
import { usePageThemeMeta } from '@/composables/usePageThemeMeta'

const { pageMetaBackgroundColor, pageMetaRootBackgroundColor, pageMetaPageStyle, pageMetaTextStyle } = usePageThemeMeta()
</script>

<style lang="scss" scoped>
.assets {
  padding-top: $space-page-y;
}

.assets__placeholder-card {
  margin-top: $space-gap-md;
}

.assets__placeholder {
  @include text-caption;
  text-align: center;
  display: block;
  margin: 120rpx 0;
}
</style>
