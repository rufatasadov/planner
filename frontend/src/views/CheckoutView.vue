<script setup>
import { onMounted, onUnmounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import { initPaddleFromConfig, onPaddleEvent } from '../utils/paddle';

// Paddle's default payment link: links from Paddle emails (update card, pay a failed renewal)
// land here as /checkout?_ptxn=txn_...; Paddle.js opens the checkout for that transaction by itself.
const route = useRoute();
const auth = useAuthStore();
const state = ref(route.query._ptxn ? 'loading' : 'missing');

let unsubscribe;
onMounted(async () => {
  if (state.value === 'missing') return;
  unsubscribe = onPaddleEvent((e) => {
    if (e.name === 'checkout.loaded') state.value = 'open';
    if (e.name === 'checkout.completed') state.value = 'done';
    if (e.name === 'checkout.closed' && state.value !== 'done') state.value = 'closed';
  });
  try {
    if (!(await initPaddleFromConfig())) state.value = 'error';
  } catch {
    state.value = 'error';
  }
});
onUnmounted(() => unsubscribe?.());
</script>

<template>
  <div class="checkout-page">
    <section class="card checkout-card">
      <img src="/logo.svg" alt="" class="checkout-logo" />
      <h2 v-if="state === 'done'">{{ t('billing.checkoutPage.doneTitle') }}</h2>
      <h2 v-else>{{ t('billing.checkoutPage.title') }}</h2>
      <p class="muted">{{ t(`billing.checkoutPage.${state}`) }}</p>
      <router-link class="btn primary" :to="auth.token ? '/' : '/login'">{{ t('billing.checkoutPage.toApp') }}</router-link>
    </section>
  </div>
</template>
