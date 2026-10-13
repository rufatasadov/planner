<script setup>
import { t } from '../i18n';

const items = [1, 2, 3, 4, 5, 6];
</script>

<template>
  <div class="faq">
    <details v-for="n in items" :key="n" class="card faq-item">
      <summary>{{ t(`site.faq.q${n}`) }}</summary>
      <p class="muted">
        {{ t(`site.faq.a${n}`) }}
        <RouterLink v-if="n === 4" to="/refund">{{ t('site.footer.refund') }} →</RouterLink>
      </p>
    </details>
  </div>
</template>
