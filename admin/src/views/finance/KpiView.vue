<template>
  <div class="placeholder-page">
    <div class="placeholder-inner">
      <div class="placeholder-icon">🏆</div>
      <h2 class="placeholder-title">KPI 考核</h2>
      <p class="placeholder-desc">线性插分与排名申诉仪表盘，开发中</p>
    </div>
  </div>
</template>

<script setup lang="ts">
// TODO: KPI考核
</script>

<style scoped>
.placeholder-page {
  padding: 48px 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 56px);
}
.placeholder-inner { text-align: center; max-width: 320px; }
.placeholder-icon { font-size: 48px; margin-bottom: 16px; opacity: 0.5; }
.placeholder-title {
  font-family: var(--apple-font-display);
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.4px;
  color: var(--apple-near-black);
  margin: 0 0 8px;
}
.placeholder-desc {
  font-size: 15px;
  color: var(--apple-text-secondary);
  margin: 0;
  letter-spacing: -0.2px;
}
</style>
