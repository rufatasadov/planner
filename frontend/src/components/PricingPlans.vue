<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import { usePaywall } from '../stores/paywall';
import { PRICES, YEARLY_SAVING_PCT, fmtUsd } from '../utils/billing';

const auth = useAuthStore();
const router = useRouter();
const period = ref('yearly');

const pro = computed(() => (period.value === 'yearly' ? PRICES.pro_yearly : PRICES.pro_monthly));
const plan = computed(() => (auth.token ? auth.user?.billing?.plan : null));
const paidPro = computed(() => ['subscription', 'promo', 'admin'].includes(auth.user?.billing?.source));

const freeFeatures = computed(() => [
  t('billing.features.projects') + ': 3',
  t('billing.features.history') + ': ' + t('billing.days', { n: 14 }),
  t('billing.features.timeline'),
  t('billing.features.tracking'),
  t('billing.features.notes'),
]);
const proFeatures = computed(() => [
  t('billing.features.projects') + ': ' + t('billing.unlimited'),
  t('billing.features.history') + ': ' + t('billing.unlimited'),
  t('billing.features.timeline'),
  t('billing.features.tracking'),
  t('billing.features.notes'),
  `${t('billing.features.calendar')}, ${t('billing.features.export')} — ${t('billing.soon')}`,
]);

function startFree() {
  router.push(auth.token ? '/' : { path: '/login', query: { mode: 'register' } });
}
function startPro() {
  if (auth.token) usePaywall().show();
  else router.push({ path: '/login', query: { mode: 'register' } });
}
</script>

<template>
  <div class="pricing">
    <div class="period-switch pricing-switch" role="tablist">
      <button :class="{ active: period === 'monthly' }" @click="period = 'monthly'">{{ t('billing.monthly') }}</button>
      <button :class="{ active: period === 'yearly' }" @click="period = 'yearly'">
        {{ t('billing.yearly') }} <span class="save-badge">{{ t('billing.save', { p: YEARLY_SAVING_PCT }) }}</span>
      </button>
    </div>

    <div class="pricing-cards">
      <article class="card price-card">
        <h3>{{ t('site.pricing.freeName') }}</h3>
        <p class="muted">{{ t('site.pricing.freeText') }}</p>
        <div class="price-line"><b>{{ t('site.pricing.freePrice') }}</b> <span class="muted">{{ t('site.pricing.forever') }}</span></div>
        <p class="muted price-sub">&nbsp;</p>
        <ul class="price-features">
          <li v-for="f in freeFeatures" :key="f">✓ {{ f }}</li>
        </ul>
        <button v-if="plan === 'free'" class="btn ghost block" disabled>{{ t('site.pricing.current') }}</button>
        <button v-else class="btn ghost block" @click="startFree">{{ t('site.pricing.freeCta') }}</button>
      </article>

      <article class="card price-card pro">
        <span class="popular-badge">{{ t('site.pricing.popular') }}</span>
        <h3>{{ t('site.pricing.proName') }}</h3>
        <p class="muted">{{ t('site.pricing.proText') }}</p>
        <div class="price-line">
          <b>{{ fmtUsd(period === 'yearly' ? PRICES.pro_yearly.usd / 12 : pro.usd) }}</b>
          <span class="muted">{{ t('billing.perMonth') }}</span>
        </div>
        <p class="muted price-sub">
          {{ period === 'yearly' ? t('site.pricing.billedYearly', { price: fmtUsd(PRICES.pro_yearly.usd) }) : t('site.pricing.billedMonthly') }}
        </p>
        <ul class="price-features">
          <li v-for="f in proFeatures" :key="f">✓ {{ f }}</li>
        </ul>
        <button v-if="paidPro" class="btn primary block" disabled>{{ t('site.pricing.current') }}</button>
        <button v-else class="btn primary block" @click="startPro">
          ⭐ {{ auth.token ? t('site.pricing.upgradeCta') : t('site.pricing.proCta') }}
        </button>
      </article>
    </div>
    <p class="muted pricing-tax">{{ t('site.pricing.taxNote') }}</p>
  </div>
</template>
