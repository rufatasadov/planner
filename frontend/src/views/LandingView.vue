<script setup>
import { computed } from 'vue';
import { locale, t } from '../i18n';
import PublicLayout from '../components/PublicLayout.vue';
import PricingPlans from '../components/PricingPlans.vue';
import SiteFaq from '../components/SiteFaq.vue';

// The promo video exists in Azerbaijani and English.
const media = computed(() => (locale.value === 'az' ? 'az' : 'en'));

const features = [
  { key: 'line', icon: '➖' },
  { key: 'tracking', icon: '⏱️' },
  { key: 'projects', icon: '🗂️' },
  { key: 'reminders', icon: '🔔' },
  { key: 'week', icon: '📅' },
  { key: 'anywhere', icon: '🌍' },
];
const signup = { path: '/login', query: { mode: 'register' } };
</script>

<template>
  <PublicLayout>
    <section class="hero">
      <h1>
        {{ t('site.hero.title') }}<br />
        <span class="accent">{{ t('site.hero.titleAccent') }}</span>
      </h1>
      <p class="hero-text muted">{{ t('site.hero.text') }}</p>
      <div class="hero-cta">
        <RouterLink :to="signup" class="btn primary lg">⭐ {{ t('site.hero.cta') }}</RouterLink>
        <RouterLink to="/pricing" class="btn ghost lg">{{ t('site.hero.secondary') }}</RouterLink>
      </div>
      <p class="muted hero-note">{{ t('site.hero.note') }}</p>
      <div class="hero-media card">
        <video
          :key="media"
          :poster="`/media/promo-${media}.jpg`"
          autoplay
          muted
          loop
          playsinline
          preload="metadata"
        >
          <source :src="`/media/promo-${media}.mp4`" type="video/mp4" />
        </video>
      </div>
    </section>

    <section id="features" class="site-section">
      <h2>{{ t('site.features.title') }}</h2>
      <div class="feature-grid">
        <article v-for="f in features" :key="f.key" class="card feature">
          <span class="feature-ico">{{ f.icon }}</span>
          <h3>{{ t(`site.features.${f.key}.title`) }}</h3>
          <p class="muted">{{ t(`site.features.${f.key}.text`) }}</p>
        </article>
      </div>
    </section>

    <section class="site-section">
      <h2>{{ t('site.how.title') }}</h2>
      <ol class="steps">
        <li v-for="n in 3" :key="n" class="card step">
          <span class="step-n">{{ n }}</span>
          <h3>{{ t(`site.how.s${n}.title`) }}</h3>
          <p class="muted">{{ t(`site.how.s${n}.text`) }}</p>
        </li>
      </ol>
    </section>

    <section id="pricing" class="site-section">
      <h2>{{ t('site.pricing.title') }}</h2>
      <p class="muted section-lead">{{ t('site.pricing.text') }}</p>
      <PricingPlans />
    </section>

    <section id="faq" class="site-section narrow">
      <h2>{{ t('site.faq.title') }}</h2>
      <SiteFaq />
    </section>

    <section class="site-section final-cta">
      <h2>{{ t('site.final.title') }}</h2>
      <RouterLink :to="signup" class="btn primary lg">{{ t('site.final.cta') }}</RouterLink>
      <p class="muted hero-note">{{ t('site.hero.note') }}</p>
    </section>
  </PublicLayout>
</template>
