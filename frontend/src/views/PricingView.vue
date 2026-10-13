<script setup>
import { t } from '../i18n';
import PublicLayout from '../components/PublicLayout.vue';
import PricingPlans from '../components/PricingPlans.vue';
import SiteFaq from '../components/SiteFaq.vue';
</script>

<template>
  <PublicLayout>
    <section class="site-section first">
      <h1>{{ t('site.pricing.title') }}</h1>
      <p class="muted section-lead">{{ t('site.pricing.text') }}</p>
      <PricingPlans />
    </section>
    <section class="site-section narrow">
      <h2>{{ t('site.faq.title') }}</h2>
      <SiteFaq />
    </section>
  </PublicLayout>
</template>
