<script setup>
import AppModal from './AppModal.vue';
import { fmtMin } from '../utils/time';
import { t } from '../i18n';

defineProps({
  show: Boolean,
  delta: Number, // minutes the plan's end moved
  following: { type: Array, default: () => [] },
});
const emit = defineEmits(['close', 'choose']);
</script>

<template>
  <AppModal :show="show" :title="t('shift.title')" width="520px" @close="emit('close')">
    <p>{{ t('shift.intro', { delta: (delta > 0 ? '+' : '') + delta, n: following.length }) }}</p>
    <ul class="mini-list">
      <li v-for="p in following" :key="p.id">
        <span class="dot" :style="{ background: p.project_color }"></span>
        {{ p.project_name }} — {{ fmtMin(p.start_min) }}-{{ fmtMin(p.end_min) }}
      </li>
    </ul>
    <div class="choice-list">
      <button class="choice" @click="emit('choose', 'all')">
        <b>{{ t('shift.allTitle') }}</b>
        <span>{{ t(delta > 0 ? 'shift.allDescForward' : 'shift.allDescBack', { m: Math.abs(delta) }) }}</span>
      </button>
      <button class="choice" @click="emit('choose', 'next')">
        <b>{{ t('shift.nextTitle') }}</b>
        <span>{{ t('shift.nextDesc') }}</span>
      </button>
      <button class="choice" @click="emit('choose', 'none')">
        <b>{{ t('shift.noneTitle') }}</b>
        <span>{{ t('shift.noneDesc') }}</span>
      </button>
    </div>
  </AppModal>
</template>
