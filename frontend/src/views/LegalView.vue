<script setup>
import { computed } from 'vue';
import { locale, t } from '../i18n';
import { LEGAL, LEGAL_UPDATED } from '../legal';
import { fmtDateShort } from '../utils/time';
import PublicLayout from '../components/PublicLayout.vue';

const props = defineProps({ doc: { type: String, required: true } });
const page = computed(() => LEGAL[props.doc]);
</script>

<template>
  <PublicLayout>
    <article class="site-section narrow legal first">
      <h1>{{ t(page.titleKey) }}</h1>
      <p class="muted">{{ t('site.legal.updated', { date: fmtDateShort(`${LEGAL_UPDATED}T12:00:00`, { year: true }) }) }}</p>
      <p v-if="locale !== 'en'" class="muted legal-note">{{ t('site.legal.englishOnly') }}</p>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div class="legal-body" lang="en" v-html="page.html"></div>
    </article>
  </PublicLayout>
</template>
