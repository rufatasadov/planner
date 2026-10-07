<script setup>
import { computed, ref } from 'vue';
import { fmtMin } from '../utils/time';

const props = defineProps({
  plans: { type: Array, default: () => [] },
  startMin: { type: Number, required: true },
  endMin: { type: Number, required: true },
  nowMin: { type: Number, default: null }, // null when the shown day is not today
  nowSec: { type: Number, default: 0 },
  selectedId: { type: Number, default: null },
});
const emit = defineEmits(['select', 'create']);

const PPM = 1.4;
const el = ref(null);

const y = (m) => (m - props.startMin) * PPM;
const height = computed(() => y(props.endMin));

const hours = computed(() => {
  const list = [];
  for (let h = Math.ceil(props.startMin / 60); h * 60 <= props.endMin; h++) list.push(h * 60);
  return list;
});

const showNow = computed(() => props.nowMin !== null && props.nowMin >= props.startMin && props.nowMin <= props.endMin);

function state(p) {
  if (props.nowMin === null) return '';
  if (p.end_min <= props.nowMin) return 'past';
  if (p.start_min <= props.nowMin) return 'current';
  return '';
}

function progress(p) {
  const total = (p.end_min - p.start_min) * 60;
  return Math.min(100, ((props.nowSec - p.start_min * 60) / total) * 100);
}

function onBgClick(e) {
  const rect = el.value.getBoundingClientRect();
  const minute = props.startMin + (e.clientY - rect.top) / PPM;
  const start = Math.max(props.startMin, Math.floor(minute / 15) * 15);
  emit('create', start);
}

const doneCount = (p) => p.tasks.filter((t) => t.status === 'done').length;
</script>

<template>
  <div ref="el" class="timeline" :style="{ height: height + 'px' }" @click.self="onBgClick">
    <div v-for="h in hours" :key="h" class="tl-hour" :style="{ top: y(h) + 'px' }">
      <span>{{ fmtMin(h) }}</span>
    </div>

    <TransitionGroup name="block">
      <div
        v-for="p in plans"
        :key="p.id"
        class="tl-block"
        :class="[state(p), { selected: p.id === selectedId, compact: p.end_min - p.start_min < 40 }]"
        :style="{ top: y(p.start_min) + 'px', height: (p.end_min - p.start_min) * PPM - 3 + 'px', '--c': p.project_color }"
        @click.stop="emit('select', p)"
      >
        <div v-if="state(p) === 'current'" class="tl-fill" :style="{ height: progress(p) + '%' }"></div>
        <div class="tl-content">
          <div class="tl-title">
            <span class="dot" :style="{ background: p.project_color }"></span>
            {{ p.project_name }}
            <span v-if="state(p) === 'current'" class="live">CANLI</span>
          </div>
          <div class="tl-meta">
            {{ fmtMin(p.start_min) }} – {{ fmtMin(p.end_min) }}
            <template v-if="p.tasks.length"> · ✓ {{ doneCount(p) }}/{{ p.tasks.length }}</template>
          </div>
        </div>
      </div>
    </TransitionGroup>

    <div v-if="showNow" class="tl-now" :style="{ top: y(nowMin) + 'px' }">
      <span>{{ fmtMin(nowMin) }}</span>
    </div>
  </div>
</template>
