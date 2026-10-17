<script setup>
import { computed, ref } from 'vue';
import { useAuthStore } from '../stores/auth';
import { errMsg } from '../api';
import { t } from '../i18n';

const props = defineProps({ disabled: Boolean });
const emit = defineEmits(['start', 'finish', 'done', 'error']);

const auth = useAuthStore();
const appleId = import.meta.env.VITE_APPLE_CLIENT_ID || '';
const googleId = import.meta.env.VITE_GOOGLE_CLIENT_ID || '';
const visible = computed(() => Boolean(appleId || googleId));
const localBusy = ref(false);

function loadScript(src) {
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) {
      if (existing.dataset.ready === '1') resolve();
      else existing.addEventListener('load', () => resolve(), { once: true });
      return;
    }
    const script = document.createElement('script');
    script.src = src;
    script.async = true;
    script.onload = () => {
      script.dataset.ready = '1';
      resolve();
    };
    script.onerror = () => reject(new Error('script'));
    document.head.appendChild(script);
  });
}

function cancelled(error) {
  const code = String(error?.error || error?.message || '');
  return code.includes('popup_closed') || code.includes('cancel') || code.includes('user_cancelled');
}

async function run(action) {
  if (props.disabled || localBusy.value) return;
  localBusy.value = true;
  emit('start');
  emit('error', '');
  try {
    await action();
    emit('done');
  } catch (error) {
    if (!cancelled(error)) {
      emit('error', error?.response ? errMsg(error) : t('common.error'));
    }
  } finally {
    localBusy.value = false;
    emit('finish');
  }
}

async function apple() {
  await run(async () => {
    await loadScript('https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js');
    const redirectURI = import.meta.env.VITE_APPLE_REDIRECT_URI || `${window.location.origin}/login`;
    window.AppleID.auth.init({
      clientId: appleId,
      scope: 'name email',
      redirectURI,
      usePopup: true,
    });
    const result = await window.AppleID.auth.signIn();
    const name = [result.user?.name?.firstName, result.user?.name?.lastName].filter(Boolean).join(' ');
    await auth.oauth({ provider: 'apple', idToken: result.authorization.id_token, name });
  });
}

async function google() {
  await run(async () => {
    await loadScript('https://accounts.google.com/gsi/client');
    const accessToken = await new Promise((resolve, reject) => {
      const client = window.google.accounts.oauth2.initTokenClient({
        client_id: googleId,
        scope: 'openid email profile',
        callback: (response) => {
          if (response.error) reject(response);
          else resolve(response.access_token);
        },
        error_callback: (error) => reject(error),
      });
      client.requestAccessToken();
    });
    await auth.oauth({ provider: 'google', accessToken });
  });
}
</script>

<template>
  <div v-if="visible" class="auth-social">
    <button v-if="appleId" type="button" class="auth-provider apple" :disabled="disabled || localBusy" @click="apple">
      {{ t('auth.continueApple') }}
    </button>
    <button v-if="googleId" type="button" class="auth-provider" :disabled="disabled || localBusy" @click="google">
      {{ t('auth.continueGoogle') }}
    </button>
    <p class="auth-or">{{ t('auth.or') }}</p>
  </div>
</template>
