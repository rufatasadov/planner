<script setup>
import { ref, reactive } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { errMsg } from '../api';
import { t } from '../i18n';
import AuthShell from '../components/AuthShell.vue';
import SocialAuth from '../components/SocialAuth.vue';

const auth = useAuthStore();
const route = useRoute();
const router = useRouter();
const mode = ref(route.query.mode === 'register' ? 'register' : 'login');
const form = reactive({ name: '', email: '', password: '' });
const error = ref('');
const busy = ref(false);

async function submit() {
  error.value = '';
  busy.value = true;
  try {
    if (mode.value === 'login') await auth.login(form.email, form.password);
    else await auth.register(form.name, form.email, form.password);
    router.push('/');
  } catch (e) {
    error.value = errMsg(e);
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <AuthShell>
    <SocialAuth
      :disabled="busy"
      @start="busy = true"
      @finish="busy = false"
      @done="router.push('/')"
      @error="error = $event"
    />
    <form class="auth-form" @submit.prevent="submit">
      <p class="muted">{{ t('auth.tagline') }}</p>
      <div class="tabs">
        <button type="button" :class="{ active: mode === 'login' }" @click="mode = 'login'">{{ t('auth.login') }}</button>
        <button type="button" :class="{ active: mode === 'register' }" @click="mode = 'register'">{{ t('auth.register') }}</button>
      </div>
      <label v-if="mode === 'register'">{{ t('auth.name') }} <input v-model="form.name" required autocomplete="name" /></label>
      <label>{{ t('auth.email') }} <input v-model="form.email" type="email" required autocomplete="email" /></label>
      <label>
        {{ t('auth.password') }}
        <input
          v-model="form.password"
          type="password"
          required
          minlength="6"
          :autocomplete="mode === 'login' ? 'current-password' : 'new-password'"
        />
      </label>
      <RouterLink v-if="mode === 'login'" to="/forgot-password" class="auth-link forgot-link">{{ t('account.forgot') }}</RouterLink>
      <p v-if="error" class="error-text">{{ error }}</p>
      <button class="btn primary block" :disabled="busy">
        {{ mode === 'login' ? t('auth.login') : t('auth.createAccount') }}
      </button>
    </form>
  </AuthShell>
</template>
