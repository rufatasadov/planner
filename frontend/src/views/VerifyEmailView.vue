<script setup>
import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import api from '../api';
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import AuthShell from '../components/AuthShell.vue';

const route = useRoute();
const auth = useAuthStore();
const state = ref('verifying');

onMounted(async () => {
  const token = route.query.token;
  if (typeof token !== 'string' || !token) {
    state.value = 'verifyFailed';
    return;
  }
  try {
    await api.post('/auth/verify-email', { token });
    state.value = 'verified';
    if (auth.token) auth.fetchMe().catch(() => {});
  } catch {
    state.value = 'verifyFailed';
  }
});
</script>

<template>
  <AuthShell>
    <h2 class="auth-title">{{ t('account.verifyTitle') }}</h2>
    <p :class="state === 'verifyFailed' ? 'error-text' : 'muted'">
      {{ state === 'verified' ? '✅ ' : '' }}{{ t(`account.${state}`) }}
    </p>
    <RouterLink v-if="state !== 'verifying'" :to="auth.token ? '/' : '/login'" class="btn primary block">
      {{ t('account.toApp') }}
    </RouterLink>
  </AuthShell>
</template>
