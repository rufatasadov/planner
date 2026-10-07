<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { errMsg } from '../api';

const auth = useAuthStore();
const router = useRouter();
const mode = ref('login');
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
  <div class="auth-page">
    <div class="auth-glow"></div>
    <form class="auth-card card" @submit.prevent="submit">
      <div class="brand big"><span class="brand-dot"></span>Planner</div>
      <p class="muted">Günün hər saatını planla, proyektlərini idarə et.</p>
      <div class="tabs">
        <button type="button" :class="{ active: mode === 'login' }" @click="mode = 'login'">Daxil ol</button>
        <button type="button" :class="{ active: mode === 'register' }" @click="mode = 'register'">Qeydiyyat</button>
      </div>
      <label v-if="mode === 'register'">Ad <input v-model="form.name" required autocomplete="name" /></label>
      <label>Email <input v-model="form.email" type="email" required autocomplete="email" /></label>
      <label>
        Şifrə
        <input
          v-model="form.password"
          type="password"
          required
          minlength="6"
          :autocomplete="mode === 'login' ? 'current-password' : 'new-password'"
        />
      </label>
      <p v-if="error" class="error-text">{{ error }}</p>
      <button class="btn primary block" :disabled="busy">
        {{ mode === 'login' ? 'Daxil ol' : 'Hesab yarat' }}
      </button>
    </form>
  </div>
</template>
