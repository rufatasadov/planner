<script setup>
import { ref } from 'vue';
import api, { errMsg } from '../api';
import { t } from '../i18n';
import AuthShell from '../components/AuthShell.vue';

const email = ref('');
const sentTo = ref('');
const error = ref('');
const busy = ref(false);

async function submit() {
  error.value = '';
  busy.value = true;
  try {
    await api.post('/auth/forgot-password', { email: email.value });
    sentTo.value = email.value;
  } catch (e) {
    error.value = errMsg(e);
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <AuthShell>
    <h2 class="auth-title">{{ t('account.forgotTitle') }}</h2>
    <template v-if="sentTo">
      <p class="muted">✉️ {{ t('account.forgotSent', { email: sentTo }) }}</p>
    </template>
    <form v-else class="auth-form" @submit.prevent="submit">
      <p class="muted">{{ t('account.forgotText') }}</p>
      <label>{{ t('auth.email') }} <input v-model="email" type="email" required autocomplete="email" /></label>
      <p v-if="error" class="error-text">{{ error }}</p>
      <button class="btn primary block" :disabled="busy">{{ t('account.sendLink') }}</button>
    </form>
    <RouterLink to="/login" class="auth-link">← {{ t('account.backToLogin') }}</RouterLink>
  </AuthShell>
</template>
