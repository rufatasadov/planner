<script setup>
import { t } from '../i18n';
import { useAuthStore } from '../stores/auth';
import { AUTHOR } from '../about';
import AppLogo from './AppLogo.vue';
import PrefsSwitch from './PrefsSwitch.vue';

const auth = useAuthStore();
const year = new Date().getFullYear();
</script>

<template>
  <div class="site">
    <header class="site-header">
      <RouterLink to="/" class="brand"><AppLogo :size="30" /></RouterLink>
      <nav class="site-nav">
        <RouterLink to="/#features" class="hide-sm">{{ t('site.nav.features') }}</RouterLink>
        <RouterLink to="/pricing">{{ t('site.nav.pricing') }}</RouterLink>
        <RouterLink to="/#faq" class="hide-sm">{{ t('site.nav.faq') }}</RouterLink>
      </nav>
      <div class="site-actions">
        <PrefsSwitch />
        <RouterLink v-if="auth.token" to="/" class="btn primary sm">{{ t('site.nav.openApp') }}</RouterLink>
        <template v-else>
          <RouterLink to="/login" class="btn ghost sm hide-sm">{{ t('site.nav.login') }}</RouterLink>
          <RouterLink :to="{ path: '/login', query: { mode: 'register' } }" class="btn primary sm">{{ t('site.nav.signup') }}</RouterLink>
        </template>
      </div>
    </header>

    <main class="site-main"><slot /></main>

    <footer class="site-footer">
      <div class="site-footer-links">
        <RouterLink to="/pricing">{{ t('site.footer.pricing') }}</RouterLink>
        <RouterLink to="/terms">{{ t('site.footer.terms') }}</RouterLink>
        <RouterLink to="/privacy">{{ t('site.footer.privacy') }}</RouterLink>
        <RouterLink to="/refund">{{ t('site.footer.refund') }}</RouterLink>
        <a :href="`mailto:${AUTHOR.email}`">{{ t('site.footer.contact') }}</a>
      </div>
      <p class="muted">{{ t('site.footer.paddle') }}</p>
      <p class="muted">© {{ year }} OneLinePlanner · {{ AUTHOR.name }} · <a :href="`mailto:${AUTHOR.email}`">{{ AUTHOR.email }}</a></p>
    </footer>
  </div>
</template>
