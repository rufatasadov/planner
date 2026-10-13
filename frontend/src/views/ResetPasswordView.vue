<script setup>
import { reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api, { errMsg } from '../api';
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import { useToast } from '../stores/toast';
import AuthShell from '../components/AuthShell.vue';

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const toast = useToast();
const token = typeof route.query.token === 'string' ? route.query.token : '';
const form = reactive({ password: '', repeat: '' });
const error = ref('');
const busy = ref(false);

async function submit() {
  error.value = '';
  if (form.password !== form.repeat) {
    error.value = t('account.passwordsDiffer');
    return;
  }
  busy.value = true;
  try {
    const { data } = await api.post('/auth/reset-password', { token, password: form.password });
    auth.setSession(data);
    toast.push({ type: 'success', title: t('account.resetDone') });
    router.replace('/');
  } catch (e) {
    error.value = errMsg(e);
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <AuthShell>
    <h2 class="auth-title">{{ t('account.resetTitle') }}</h2>
    <p v-if="!token" class="error-text">{{ t('account.linkMissing') }}</p>
    <form v-else class="auth-form" @submit.prevent="submit">
      <label>
        {{ t('account.newPassword') }}
        <input v-model="form.password" type="password" required minlength="6" autocomplete="new-password" />
      </label>
      <label>
        {{ t('account.repeatPassword') }}
        <input v-model="form.repeat" type="password" required minlength="6" autocomplete="new-password" />
      </label>
      <p v-if="error" class="error-text">{{ error }}</p>
      <button class="btn primary block" :disabled="busy">{{ t('account.savePassword') }}</button>
    </form>
    <RouterLink to="/forgot-password" class="auth-link">{{ t('account.forgot') }}</RouterLink>
  </AuthShell>
</template>
