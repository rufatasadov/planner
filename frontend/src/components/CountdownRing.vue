<script setup>
import { computed } from 'vue';
import { fmtSeconds } from '../utils/time';

const props = defineProps({
  totalSec: { type: Number, required: true },
  remainingSec: { type: Number, required: true },
  color: { type: String, default: '#6366f1' },
  warning: Boolean,
  size: { type: Number, default: 170 },
  caption: String,
});

const stroke = 12;
const r = computed(() => (props.size - stroke) / 2);
const circ = computed(() => 2 * Math.PI * r.value);
const ratio = computed(() => (props.totalSec ? Math.min(1, Math.max(0, props.remainingSec / props.totalSec)) : 0));
</script>

<template>
  <div class="ring" :class="{ warning }">
    <svg :width="size" :height="size">
      <circle :cx="size / 2" :cy="size / 2" :r="r" fill="none" :style="{ stroke: 'var(--surface-3)' }" :stroke-width="stroke" />
      <circle
        class="ring-progress"
        :cx="size / 2"
        :cy="size / 2"
        :r="r"
        fill="none"
        :style="{ stroke: warning ? 'var(--warning)' : color }"
        :stroke-width="stroke"
        stroke-linecap="round"
        :stroke-dasharray="circ"
        :stroke-dashoffset="circ * (1 - ratio)"
        :transform="`rotate(-90 ${size / 2} ${size / 2})`"
      />
    </svg>
    <div class="ring-center">
      <div class="ring-time">{{ fmtSeconds(remainingSec) }}</div>
      <div class="ring-caption">{{ caption }}</div>
    </div>
  </div>
</template>
