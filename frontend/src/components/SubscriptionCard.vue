<script setup>
import { computed, onMounted, ref } from 'vue';
import { errMsg } from '../api';
import { openPortal } from '../utils/paddle';
import { useAuthStore } from '../stores/auth';
import { usePaywall } from '../stores/paywall';
import { useToast } from '../stores/toast';
import { t } from '../i18n';
import { fmtDateShort } from '../utils/time';
import { trialDaysLeft } from '../utils/billing';

const auth = useAuthStore();
const paywall = usePaywall();
const toast = useToast();

onMounted(() => auth.fetchMe().catch(() => {}));

const billing = computed(() => auth.user?.billing);
const date = (v) => fmtDateShort(v, { year: true });

const status = computed(() => {
  const b = billing.value;
  if (!b) return null;
  const sub = b.subscription;
  switch (b.source) {
    case 'admin':
      return { title: t('billing.pro'), lines: [t('billing.settings.sourceAdmin')] };
    case 'trial':
      return {
        title: t('billing.pro'),
        lines: [t('billing.settings.sourceTrial', { n: trialDaysLeft(b), date: date(b.trial_ends_at) })],
        upgrade: true,
      };
    case 'promo':
      return {
        title: t('billing.pro'),
        lines: [
          `${t('billing.settings.sourcePromo')} · ${
            sub.current_period_end ? t('billing.settings.promoUntil', { date: date(sub.current_period_end) }) : t('billing.settings.promoForever')
          }`,
        ],
      };
    case 'subscription':
      return {
        title: t('billing.pro'),
        lines: [
          t('billing.settings.sourceSubscription', { product: t(`billing.settings.product.${sub.product_id}`) }),
          sub.current_period_end &&
            t(sub.will_renew ? 'billing.settings.renews' : 'billing.settings.endsOn', { date: date(sub.current_period_end) }),
        ].filter(Boolean),
        manage: true,
      };
    default:
      return {
        title: t('billing.free'),
        lines: [t('billing.settings.freeText', { projects: b.limits.projects, days: b.limits.history_days })],
        upgrade: true,
      };
  }
});

const opening = ref(false);

async function manage() {
  opening.value = true;
  try {
    await openPortal();
  } catch (e) {
    toast.push({ type: 'error', title: t('billing.settings.manage'), body: errMsg(e) });
  } finally {
    opening.value = false;
  }
}
</script>

<template>
  <section v-if="status" class="card subscription-card">
    <h3>{{ t('billing.settings.title') }}</h3>
    <div class="sub-row">
      <div>
        <span class="plan-badge" :class="billing.plan">{{ status.title }}</span>
        <p v-for="line in status.lines" :key="line" class="muted sub-line">{{ line }}</p>
      </div>
      <button v-if="status.upgrade" class="btn primary" @click="paywall.show()">⭐ {{ t('billing.upgrade') }}</button>
      <button v-else-if="status.manage" class="btn ghost" :disabled="opening" @click="manage">{{ t('billing.settings.manage') }}</button>
    </div>
  </section>
</template>
