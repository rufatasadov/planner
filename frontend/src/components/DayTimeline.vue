<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue';
import { fmtMin } from '../utils/time';
import { t } from '../i18n';

const props = defineProps({
  plans: { type: Array, default: () => [] },
  startMin: { type: Number, required: true },
  endMin: { type: Number, required: true },
  nowMin: { type: Number, default: null }, // null when the shown day is not today
  nowSec: { type: Number, default: 0 },
  selectedId: { type: Number, default: null },
  tracking: { type: Object, default: () => ({}) }, // plan id -> { state, pct }
  preview: { type: Object, default: null }, // { id, start_min, end_min } awaiting confirmation
});
const emit = defineEmits(['select', 'create', 'change', 'invalid']);

// Minimum pixels per minute; the track stretches to the card width and scrolls when narrower.
const PPM = 1.8;
const scroller = ref(null);
const el = ref(null);

const span = computed(() => Math.max(1, props.endMin - props.startMin));
const x = (m) => ((m - props.startMin) / span.value) * 100;
const minWidth = computed(() => span.value * PPM);

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

const STEP = 15;
const DRAG_THRESHOLD = 4;
const drag = ref(null); // { plan, mode: 'move' | 'start' | 'end', x0, start, end, active, valid }
let suppressClick = false;

function pos(p) {
  if (drag.value?.active && drag.value.plan.id === p.id) return { start_min: drag.value.start, end_min: drag.value.end };
  if (props.preview?.id === p.id) return props.preview;
  return p;
}

const snap = (m) => Math.round(m / STEP) * STEP;
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function overlaps(id, start, end) {
  return props.plans.some((o) => o.id !== id && start < o.end_min && o.start_min < end);
}

function onPointerDown(e, p, mode) {
  if (e.button !== 0 || props.preview) return;
  drag.value = { plan: p, mode, x0: e.clientX, start: p.start_min, end: p.end_min, active: false, valid: true };
  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('pointerup', onPointerUp);
  window.addEventListener('keydown', onKeyDown);
}

function onPointerMove(e) {
  const d = drag.value;
  if (!d) return;
  const dx = e.clientX - d.x0;
  if (!d.active && Math.abs(dx) < DRAG_THRESHOLD) return;
  d.active = true;
  const dm = (dx / el.value.getBoundingClientRect().width) * span.value;
  const { start_min: s0, end_min: e0 } = d.plan;
  if (d.mode === 'move') {
    const len = e0 - s0;
    d.start = clamp(snap(s0 + dm), props.startMin, props.endMin - len);
    d.end = d.start + len;
  } else if (d.mode === 'start') {
    d.start = clamp(snap(s0 + dm), props.startMin, e0 - STEP);
    d.end = e0;
  } else {
    d.start = s0;
    d.end = clamp(snap(e0 + dm), s0 + STEP, props.endMin);
  }
  d.valid = !overlaps(d.plan.id, d.start, d.end);
}

function onPointerUp() {
  const d = drag.value;
  stopDrag();
  if (!d?.active) return;
  suppressClick = true;
  setTimeout(() => (suppressClick = false));
  if (d.start === d.plan.start_min && d.end === d.plan.end_min) return;
  if (!d.valid) return emit('invalid', d.plan);
  emit('change', { plan: d.plan, start_min: d.start, end_min: d.end });
}

function onKeyDown(e) {
  if (e.key === 'Escape') stopDrag();
}

function stopDrag() {
  drag.value = null;
  window.removeEventListener('pointermove', onPointerMove);
  window.removeEventListener('pointerup', onPointerUp);
  window.removeEventListener('keydown', onKeyDown);
}
onUnmounted(stopDrag);

function onBlockClick(p) {
  if (!suppressClick) emit('select', p);
}

function onBgClick(e) {
  const rect = el.value.getBoundingClientRect();
  const minute = props.startMin + ((e.clientX - rect.left) / rect.width) * span.value;
  const start = Math.max(props.startMin, Math.floor(minute / 15) * 15);
  emit('create', start);
}

onMounted(async () => {
  await nextTick();
  const box = scroller.value;
  if (!box || box.scrollWidth <= box.clientWidth) return;
  const focus = showNow.value ? props.nowMin : props.plans[0]?.start_min;
  if (focus == null) return;
  box.scrollLeft = (x(focus) / 100) * box.scrollWidth - box.clientWidth / 3;
});

const doneCount = (p) => p.tasks.filter((t) => t.status === 'done').length;
</script>

<template>
  <div ref="scroller" class="timeline-scroll">
    <div ref="el" class="timeline" :style="{ minWidth: minWidth + 'px' }" @click.self="onBgClick">
      <div v-for="h in hours" :key="h" class="tl-hour" :style="{ left: x(h) + '%' }">
        <span>{{ fmtMin(h) }}</span>
      </div>

      <TransitionGroup name="block">
        <div
          v-for="p in plans"
          :key="p.id"
          class="tl-block"
          :class="[
            state(p),
            {
              selected: p.id === selectedId,
              compact: (pos(p).end_min - pos(p).start_min) * PPM < 110,
              dragging: drag?.active && drag.plan.id === p.id,
              invalid: drag?.active && drag.plan.id === p.id && !drag.valid,
              pending: preview?.id === p.id,
            },
          ]"
          :style="{
            left: x(pos(p).start_min) + '%',
            width: `calc(${x(pos(p).end_min) - x(pos(p).start_min)}% - 3px)`,
            '--c': p.project_color,
          }"
          :title="`${p.project_name} · ${fmtMin(p.start_min)} – ${fmtMin(p.end_min)}\n${t('drag.hint')}`"
          @pointerdown="onPointerDown($event, p, 'move')"
          @click.stop="onBlockClick(p)"
        >
          <span class="tl-handle start" @pointerdown.stop="onPointerDown($event, p, 'start')"></span>
          <span class="tl-handle end" @pointerdown.stop="onPointerDown($event, p, 'end')"></span>
          <div v-if="state(p) === 'current'" class="tl-fill" :style="{ width: progress(p) + '%' }"></div>
          <div class="tl-content">
            <div class="tl-title">
              <span class="dot" :style="{ background: p.project_color }"></span>
              <span class="tl-name">{{ p.project_name }}</span>
              <span v-if="state(p) === 'current'" class="live">{{ t('plan.live') }}</span>
              <span v-if="tracking[p.id]?.state === 'running'" class="trk-badge running" :title="t('tracking.running')">● REC</span>
              <span v-else-if="tracking[p.id]?.state === 'paused'" class="trk-badge paused" :title="t('tracking.paused')">⏸</span>
            </div>
            <div class="tl-meta">{{ fmtMin(pos(p).start_min) }} – {{ fmtMin(pos(p).end_min) }}</div>
            <div v-if="p.tasks.length || tracking[p.id]?.pct != null" class="tl-meta">
              <template v-if="p.tasks.length">✓ {{ doneCount(p) }}/{{ p.tasks.length }}</template>
              <template v-if="tracking[p.id]?.pct != null"> · ⚡ {{ tracking[p.id].pct }}%</template>
            </div>
          </div>
        </div>
      </TransitionGroup>

      <div v-if="showNow" class="tl-now" :style="{ left: x(nowMin) + '%' }">
        <span>{{ fmtMin(nowMin) }}</span>
      </div>
    </div>
  </div>
</template>
