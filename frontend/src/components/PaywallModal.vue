<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { usePaywall } from '../stores/paywall';
import { useAuthStore } from '../stores/auth';
import { useToast } from '../stores/toast';
import { t } from '../i18n';
import { PRICES, YEARLY_SAVING_PCT, fmtUsd } from '../utils/billing';
import { onPaddleEvent, openCheckout, waitForSubscription } from '../utils/paddle';
import { errMsg } from '../api';
import AppModal from './AppModal.vue';

const paywall = usePaywall();
const auth = useAuthStore();
const toast = useToast();
const period = ref('yearly');

// Free-plan limits come from the server; fall back to the defaults before /auth/me has loaded.
const freeLimits = computed(() => {
  const l = auth.user?.billing?.limits;
  return auth.user?.billing?.plan === 'free' && l ? l : { projects: 3, history_days: 14 };
});

const head = computed(() => {
  const n = paywall.reason === 'projects' ? freeLimits.value.projects : freeLimits.value.history_days;
  const key = paywall.reason === 'projects' ? 'projects' : paywall.reason === 'history' ? 'history' : 'default';
  return { title: t(`billing.paywall.${key}Title`), text: t(`billing.paywall.${key}Text`, { n }) };
});

const features = computed(() => [
  { key: 'projects', free: String(freeLimits.value.projects), pro: t('billing.unlimited') },
  { key: 'history', free: t('billing.days', { n: freeLimits.value.history_days }), pro: t('billing.unlimited') },
  { key: 'timeline', free: true, pro: true },
  { key: 'tracking', free: true, pro: true },
  { key: 'notes', free: true, pro: true },
  { key: 'calendar', free: false, pro: 'soon' },
  { key: 'export', free: false, pro: 'soon' },
  { key: 'templates', free: false, pro: 'soon' },
]);

const price = computed(() => (period.value === 'yearly' ? PRICES.pro_yearly : PRICES.pro_monthly));

const busy = ref(false);

async function checkout() {
  busy.value = true;
  try {
    await openCheckout(period.value === 'yearly' ? 'pro_yearly' : 'pro_monthly');
    paywall.close();
  } catch (e) {
    toast.push({ type: 'error', title: t('billing.checkoutFailed'), body: errMsg(e) });
  } finally {
    busy.value = false;
  }
}

async function onPaid() {
  toast.push({ type: 'info', title: t('billing.paid'), body: t('billing.activating') });
  const active = await waitForSubscription();
  toast.push(
    active
      ? { type: 'success', title: t('billing.activated') }
      : { type: 'info', title: t('billing.paid'), body: t('billing.activationDelayed') },
  );
}

let unsubscribe;
onMounted(() => {
  unsubscribe = onPaddleEvent((e) => {
    if (e.name === 'checkout.completed') onPaid();
  });
});
onUnmounted(() => unsubscribe?.());
</script>

<template>
  <AppModal :show="paywall.open" :title="head.title" width="520px" @close="paywall.close()">
    <div class="paywall">
      <p class="muted paywall-lead">{{ head.text }}</p>

      <div class="period-switch" role="tablist">
        <button :class="{ active: period === 'monthly' }" @click="period = 'monthly'">{{ t('billing.monthly') }}</button>
        <button :class="{ active: period === 'yearly' }" @click="period = 'yearly'">
          {{ t('billing.yearly') }} <span class="save-badge">{{ t('billing.save', { p: YEARLY_SAVING_PCT }) }}</span>
        </button>
      </div>

      <div class="price-box">
        <b>{{ fmtUsd(price.usd) }}</b>
        <span class="muted">{{ period === 'yearly' ? t('billing.perYear') : t('billing.perMonth') }}</span>
        <small v-if="period === 'yearly'" class="muted">
          {{ t('billing.perMonthApprox', { price: fmtUsd(PRICES.pro_yearly.usd / 12) }) }}
        </small>
      </div>

      <table class="plan-compare">
        <thead>
          <tr><th></th><th>{{ t('billing.free') }}</th><th class="pro-col">{{ t('billing.pro') }}</th></tr>
        </thead>
        <tbody>
          <tr v-for="f in features" :key="f.key">
            <td>{{ t(`billing.features.${f.key}`) }}</td>
            <td>
              <template v-if="f.free === true">✓</template>
              <template v-else-if="f.free === false"><span class="muted">—</span></template>
              <template v-else>{{ f.free }}</template>
            </td>
            <td class="pro-col">
              <template v-if="f.pro === true">✓</template>
              <span v-else-if="f.pro === 'soon'" class="soon-badge">{{ t('billing.soon') }}</span>
              <template v-else>{{ f.pro }}</template>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <template #footer>
      <small class="muted paywall-note">{{ t('billing.cancelAnytime') }}</small>
      <button class="btn primary" :disabled="busy" @click="checkout">⭐ {{ t('billing.upgrade') }}</button>
    </template>
  </AppModal>
</template>
