<script setup>
import { computed } from 'vue';
import { planWindow } from '../utils/tracking';
import { fmtMin } from '../utils/time';
import { t } from '../i18n';

const props = defineProps({
  plan: { type: Object, required: true },
  nowMs: { type: Number, required: true },
});

const fmtTime = (ms) => {
  const d = new Date(ms);
  return fmtMin(d.getHours() * 60 + d.getMinutes());
};

const view = computed(() => {
  const win = planWindow(props.plan);
  const sessions = props.plan.tracking.sessions.map((s) => ({
    start: new Date(s.started_at).getTime(),
    end: s.ended_at ? new Date(s.ended_at).getTime() : props.nowMs,
    running: !s.ended_at,
  }));
  const from = Math.min(win.start, ...sessions.map((s) => s.start));
  const to = Math.max(win.end, ...sessions.map((s) => s.end));
  const pct = (ms) => ((ms - from) / (to - from)) * 100;
  return {
    plan: { left: pct(win.start), width: pct(win.end) - pct(win.start) },
    sessions: sessions.map((s) => ({
      ...s,
      left: pct(s.start),
      width: Math.max(0.6, pct(s.end) - pct(s.start)),
      title: `${fmtTime(s.start)} – ${s.running ? t('tracking.now') : fmtTime(s.end)}`,
    })),
    now: props.nowMs >= from && props.nowMs <= to ? pct(props.nowMs) : null,
  };
});
</script>

<template>
  <div class="session-bar" :style="{ '--c': plan.project_color }">
    <div class="sb-plan" :style="{ left: view.plan.left + '%', width: view.plan.width + '%' }"></div>
    <div
      v-for="(s, i) in view.sessions"
      :key="i"
      class="sb-session"
      :class="{ running: s.running }"
      :style="{ left: s.left + '%', width: s.width + '%' }"
      :title="s.title"
    ></div>
    <div v-if="view.now !== null" class="sb-now" :style="{ left: view.now + '%' }"></div>
  </div>
</template>
