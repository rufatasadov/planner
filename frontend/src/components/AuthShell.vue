<script setup>
import { t } from '../i18n';
import { AUTHOR } from '../about';
import AppLogo from './AppLogo.vue';
import PrefsSwitch from './PrefsSwitch.vue';
</script>

<template>
  <div class="auth-page">
    <div class="auth-glow"></div>
    <div class="auth-prefs"><PrefsSwitch /></div>
    <div class="auth-card card">
      <RouterLink to="/" class="brand big"><AppLogo :size="44" /></RouterLink>
      <slot />
    </div>
    <footer class="auth-footer">
      <nav class="auth-legal">
        <RouterLink to="/pricing">{{ t('site.footer.pricing') }}</RouterLink>
        <RouterLink to="/terms">{{ t('site.footer.terms') }}</RouterLink>
        <RouterLink to="/privacy">{{ t('site.footer.privacy') }}</RouterLink>
        <RouterLink to="/refund">{{ t('site.footer.refund') }}</RouterLink>
      </nav>
      {{ t('about.author') }}: {{ AUTHOR.name }} ·
      <a :href="`mailto:${AUTHOR.email}`">{{ AUTHOR.email }}</a>
    </footer>
  </div>
</template>
