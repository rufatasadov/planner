<script setup>
import { computed } from 'vue';

const props = defineProps({
  segments: { type: Array, default: () => [] }, // [{ label, value, color }]
  size: { type: Number, default: 180 },
  thickness: { type: Number, default: 22 },
  centerTitle: String,
  centerSub: String,
});

const r = computed(() => (props.size - props.thickness) / 2);
const circ = computed(() => 2 * Math.PI * r.value);
const total = computed(() => props.segments.reduce((s, x) => s + x.value, 0));

const arcs = computed(() => {
  let offset = 0;
  return props.segments.map((s) => {
    const len = total.value ? (s.value / total.value) * circ.value : 0;
    const arc = { ...s, dash: `${Math.max(len - 2, 0)} ${circ.value}`, offset: -offset };
    offset += len;
    return arc;
  });
});
</script>

<template>
  <div class="donut">
    <svg :width="size" :height="size" :viewBox="`0 0 ${size} ${size}`">
      <circle :cx="size / 2" :cy="size / 2" :r="r" fill="none" :style="{ stroke: 'var(--surface-3)' }" :stroke-width="thickness" />
      <g :transform="`rotate(-90 ${size / 2} ${size / 2})`">
        <circle
          v-for="a in arcs"
          :key="a.label"
          class="donut-arc"
          :cx="size / 2"
          :cy="size / 2"
          :r="r"
          fill="none"
          :style="{ stroke: a.color }"
          :stroke-width="thickness"
          :stroke-dasharray="a.dash"
          :stroke-dashoffset="a.offset"
          stroke-linecap="butt"
        >
          <title>{{ a.label }}</title>
        </circle>
      </g>
      <text :x="size / 2" :y="size / 2 - 4" text-anchor="middle" class="donut-title">{{ centerTitle }}</text>
      <text :x="size / 2" :y="size / 2 + 16" text-anchor="middle" class="donut-sub">{{ centerSub }}</text>
    </svg>
    <ul class="legend">
      <li v-for="s in segments" :key="s.label">
        <span class="dot" :style="{ background: s.color }"></span>
        <span class="legend-label">{{ s.label }}</span>
        <span class="muted">{{ total ? Math.round((s.value / total) * 100) : 0 }}%</span>
      </li>
    </ul>
  </div>
</template>
