<script setup>
import { watch, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from './stores/auth';
import { useSettingsStore } from './stores/settings';
import { useNotifier } from './composables/useNotifier';
import ToastHost from './components/ToastHost.vue';

const auth = useAuthStore();
const settings = useSettingsStore();
const router = useRouter();
const notifier = useNotifier();

watch(
  () => auth.token,
  (token) => {
    if (token) {
      settings.load(true).catch(() => {});
      notifier.start();
    } else {
      notifier.stop();
    }
  },
  { immediate: true },
);

onUnmounted(() => notifier.stop());

function logout() {
  auth.logout();
  router.push('/login');
}
</script>

<template>
  <div class="app">
    <header v-if="auth.token" class="topbar">
      <RouterLink to="/" class="brand"><span class="brand-dot"></span>Planner</RouterLink>
      <nav>
        <RouterLink to="/" exact-active-class="active">Günlük plan</RouterLink>
        <RouterLink to="/projects" active-class="active">Proyektlər</RouterLink>
        <RouterLink to="/settings" active-class="active">Ayarlar</RouterLink>
      </nav>
      <div class="user">
        <span class="avatar">{{ auth.user?.name?.[0]?.toUpperCase() }}</span>
        <span class="muted hide-sm">{{ auth.user?.name }}</span>
        <button class="btn ghost sm" @click="logout">Çıxış</button>
      </div>
    </header>
    <main :class="{ container: auth.token }">
      <RouterView v-slot="{ Component }">
        <Transition name="page" mode="out-in">
          <component :is="Component" />
        </Transition>
      </RouterView>
    </main>
    <ToastHost />
  </div>
</template>
