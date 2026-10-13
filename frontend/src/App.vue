<script setup>
import { computed, watch, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from './stores/auth';
import { useSettingsStore } from './stores/settings';
import { useNotifier } from './composables/useNotifier';
import { t } from './i18n';
import ToastHost from './components/ToastHost.vue';
import PrefsSwitch from './components/PrefsSwitch.vue';

const auth = useAuthStore();
const settings = useSettingsStore();
const router = useRouter();
const notifier = useNotifier();

watch(
  () => auth.token,
  (token) => {
    if (token) {
      settings.load(true).catch(() => {});
      auth.fetchMe().catch(() => {});
      notifier.start();
    } else {
      notifier.stop();
    }
  },
  { immediate: true },
);

onUnmounted(() => notifier.stop());

const navItems = computed(() => [
  { to: '/', label: 'nav.plan', icon: '📅', activeAttr: { 'exact-active-class': 'active' } },
  { to: '/projects', label: 'nav.projects', icon: '🗂️', activeAttr: { 'active-class': 'active' } },
  { to: '/notes', label: 'nav.notes', icon: '📝', activeAttr: { 'active-class': 'active' } },
  { to: '/settings', label: 'nav.settings', icon: '⚙️', activeAttr: { 'active-class': 'active' } },
  ...(auth.user?.is_admin ? [{ to: '/admin', label: 'nav.admin', icon: '🛡️', activeAttr: { 'active-class': 'active' } }] : []),
]);

function logout() {
  auth.logout();
  router.push('/login');
}
</script>

<template>
  <div class="app">
    <header v-if="auth.token" class="topbar">
      <RouterLink to="/" class="brand"><span class="brand-dot"></span>Planner</RouterLink>
      <nav class="main-nav">
        <RouterLink v-for="item in navItems" :key="item.to" :to="item.to" v-bind="item.activeAttr">
          {{ t(item.label) }}
        </RouterLink>
      </nav>
      <div class="user">
        <PrefsSwitch />
        <span class="avatar hide-sm">{{ auth.user?.name?.[0]?.toUpperCase() }}</span>
        <span class="muted hide-md">{{ auth.user?.name }}</span>
        <button class="btn ghost sm logout-btn" :title="t('nav.logout')" @click="logout">
          <span class="hide-sm">{{ t('nav.logout') }}</span><span class="show-sm">⏻</span>
        </button>
      </div>
    </header>
    <main :class="{ container: auth.token }">
      <RouterView v-slot="{ Component }">
        <Transition name="page" mode="out-in">
          <component :is="Component" />
        </Transition>
      </RouterView>
    </main>
    <nav v-if="auth.token" class="tab-bar">
      <RouterLink v-for="item in navItems" :key="item.to" :to="item.to" v-bind="item.activeAttr">
        <span class="tab-ico">{{ item.icon }}</span>
        <span class="tab-label">{{ t(item.label) }}</span>
      </RouterLink>
    </nav>
    <ToastHost />
  </div>
</template>
