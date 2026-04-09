<template>
  <view class="placeholder-page">
    <text class="icon">📊</text>
    <text class="title">总览仪表盘</text>
    <text class="subtitle">NOI · WALE · KPI · 出租率</text>
    <text class="tip">待实现</text>
  </view>
</template>

<script setup lang="ts">
// dashboard/index — M3 NOI 仪表盘
// 待实现：连接 useFinanceStore 展示 NOI/WALE/KPI/出租率四核心指标
</script>

<style scoped>
.placeholder-page { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 80vh; gap: 16rpx; color: #8c8c8c; }
.icon { font-size: 80rpx; }
.title { font-size: 40rpx; font-weight: 600; color: #262626; }
.subtitle { font-size: 24rpx; }
.tip { font-size: 22rpx; color: #bfbfbf; border: 2rpx dashed #d9d9d9; padding: 8rpx 24rpx; border-radius: 8rpx; margin-top: 16rpx; }
</style>
