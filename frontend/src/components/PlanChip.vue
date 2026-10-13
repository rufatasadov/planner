<script setup>
import { computed } from 'vue';
import { useAuthStore } from '../stores/auth';
import { usePaywall } from '../stores/paywall';
import { t } from '../i18n';
import { trialDaysLeft } from '../utils/billing';

const auth = useAuthStore();
const paywall = usePaywall();

const billing = computed(() => auth.user?.billing);
const days = computed(() => trialDaysLeft(billing.value));
</script>

<template>
  <template v-if="billing">
    <button
      v-if="billing.source === 'trial'"
      class="plan-chip trial"
      :class="{ warning: days <= 3 }"
      @click="paywall.show()"
    >
      ⭐ <span class="hide-sm">{{ days <= 1 ? t('billing.chipTrialLast') : t('billing.chipTrial', { n: days }) }}</span>
      <span class="show-sm">{{ days }}d</span>
    </button>
    <button v-else-if="billing.plan === 'free'" class="plan-chip upgrade" @click="paywall.show()">
      ⭐ <span class="hide-sm">{{ t('billing.upgrade') }}</span><span class="show-sm">Pro</span>
    </button>
    <RouterLink v-else to="/settings" class="plan-chip pro">PRO</RouterLink>
  </template>
</template>
