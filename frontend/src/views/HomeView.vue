<script setup>
import { defineAsyncComponent } from 'vue';
import { useAuthStore } from '../stores/auth';

// "/" is the daily plan for signed-in users and the public landing page for everyone else.
const PlanView = defineAsyncComponent(() => import('./PlanView.vue'));
const LandingView = defineAsyncComponent(() => import('./LandingView.vue'));
const auth = useAuthStore();
</script>

<template>
  <PlanView v-if="auth.token" />
  <LandingView v-else />
</template>
