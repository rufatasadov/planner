<script setup>
import { computed } from 'vue';
import { useSettingsStore } from '../stores/settings';
import { efficiencyPct, elapsedPlanSec, liveTracking, planWindow } from '../utils/tracking';
import { fmtSeconds } from '../utils/time';
import { t } from '../i18n';
import SessionBar from './SessionBar.vue';

const props = defineProps({
  plan: { type: Object, required: true },
  nowMs: { type: Number, required: true },
  loadedAt: { type: Number, required: true },
  compact: Boolean,
  busy: Boolean,
});
const emit = defineEmits(['start', 'pause']);
const settings = useSettingsStore();

const live = computed(() => liveTracking(props.plan, props.nowMs, props.loadedAt));
const eff = computed(() => efficiencyPct(live.value.effective, elapsedPlanSec(props.plan, props.nowMs)));
const canStart = computed(() => !(settings.auto_stop && props.nowMs >= planWindow(props.plan).end));
const longBreak = computed(
  () => settings.break_reminder_min > 0 && live.value.currentBreak >= settings.break_reminder_min * 60,
);
const effLevel = computed(() => {
  if (eff.value === null) return '';
  const target = settings.target_efficiency_pct;
  return eff.value >= target ? 'good' : eff.value >= target * 0.75 ? 'mid' : 'low';
});
</script>

<template>
  <div class="tracking" :class="[live.state, { compact }]">
    <div class="trk-row">
      <button v-if="live.state === 'running'" class="btn trk-btn pause" :disabled="busy" @click="emit('pause')">
        ⏸ {{ t('tracking.pause') }}
      </button>
      <button v-else-if="canStart" class="btn trk-btn start" :disabled="busy" @click="emit('start')">
        ▶ {{ live.state === 'not_started' ? t('tracking.start') : t('tracking.resume') }}
      </button>
      <span v-else class="muted small">{{ t('tracking.ended') }}</span>
      <div class="trk-clock">
        <div class="trk-time">
          <span v-if="live.state === 'running'" class="rec-dot"></span>{{ fmtSeconds(live.effective) }}
        </div>
        <div class="muted small">{{ t('tracking.effective') }}</div>
      </div>
    </div>

    <div v-if="live.state === 'paused'" class="trk-break" :class="{ long: longBreak }">
      ☕ {{ t('tracking.onBreak', { time: fmtSeconds(live.currentBreak) }) }}
    </div>

    <template v-if="!compact">
      <div class="trk-stats">
        <div>
          <span class="muted small">{{ t('tracking.breaks') }}</span>
          <b>{{ fmtSeconds(live.breaks) }}</b>
        </div>
        <div>
          <span class="muted small">{{ t('tracking.sessions') }}</span>
          <b>{{ plan.tracking.sessions.length }}</b>
        </div>
        <div>
          <span class="muted small">{{ t('tracking.efficiency') }}</span>
          <b :class="['eff-text', effLevel]">{{ eff === null ? '—' : eff + '%' }}</b>
        </div>
      </div>
      <div class="eff-bar" :title="t('tracking.target', { p: settings.target_efficiency_pct })">
        <div class="eff-fill" :class="effLevel" :style="{ width: Math.min(eff ?? 0, 100) + '%' }"></div>
        <div class="eff-target" :style="{ left: settings.target_efficiency_pct + '%' }"></div>
      </div>
      <SessionBar v-if="plan.tracking.sessions.length" :plan="plan" :now-ms="nowMs" />
    </template>
  </div>
</template>
