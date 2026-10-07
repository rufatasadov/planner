<script setup>
import { useToast } from '../stores/toast';

const toast = useToast();
const icons = { info: 'ℹ️', success: '✅', error: '⛔', warning: '⏰' };
</script>

<template>
  <div class="toasts">
    <TransitionGroup name="toast">
      <div v-for="t in toast.items" :key="t.id" class="toast" :class="t.type" @click="toast.remove(t.id)">
        <span class="toast-icon">{{ icons[t.type] }}</span>
        <div>
          <div class="toast-title">{{ t.title }}</div>
          <div v-if="t.body" class="toast-body">{{ t.body }}</div>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>
