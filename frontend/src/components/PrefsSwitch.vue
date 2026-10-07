<script setup>
import { LOCALES, locale, setLocale, t } from '../i18n';
import { theme, toggleTheme } from '../theme';
</script>

<template>
  <div class="prefs">
    <div class="lang-switch" role="group">
      <button
        v-for="l in LOCALES"
        :key="l.code"
        :class="{ active: locale === l.code }"
        :title="l.name"
        @click="setLocale(l.code)"
      >
        {{ l.label }}
      </button>
    </div>
    <button class="icon-btn theme-btn" :title="theme === 'dark' ? t('theme.light') : t('theme.dark')" @click="toggleTheme">
      {{ theme === 'dark' ? '☀️' : '🌙' }}
    </button>
  </div>
</template>
