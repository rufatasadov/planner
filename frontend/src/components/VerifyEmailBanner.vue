<script setup>
import { computed, ref } from 'vue';
import api, { errMsg } from '../api';
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import { useToast } from '../stores/toast';

const DISMISS_KEY = 'verifyBannerHidden';

const auth = useAuthStore();
const toast = useToast();
const hidden = ref(sessionStorage.getItem(DISMISS_KEY) === '1');
const busy = ref(false);

// Only when the server says so explicitly: sessions saved before this field existed have it undefined.
const show = computed(() => !hidden.value && auth.user?.email_verified === false);

async function resend() {
  busy.value = true;
  try {
    await api.post('/auth/resend-verification');
    toast.push({ type: 'success', title: t('account.resent') });
  } catch (e) {
    toast.push({ type: 'error', title: errMsg(e) });
  } finally {
    busy.value = false;
  }
}

function dismiss() {
  hidden.value = true;
  sessionStorage.setItem(DISMISS_KEY, '1');
}
</script>

<template>
  <div v-if="show" class="verify-banner">
    <span>✉️ {{ t('account.banner', { email: auth.user.email }) }}</span>
    <button class="link-btn" :disabled="busy" @click="resend">{{ t('account.resend') }}</button>
    <button class="icon-btn verify-close" :title="t('account.dismiss')" @click="dismiss">✕</button>
  </div>
</template>
