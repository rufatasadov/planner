<script setup>
import { reactive, ref, onMounted } from 'vue';
import { useSettingsStore } from '../stores/settings';
import { useToast } from '../stores/toast';
import { errMsg, notifyPlansChanged } from '../api';
import {
  idlePermissionState, requestIdlePermission, showNotification,
} from '../composables/useNotifier';
import { fmtDuration } from '../utils/time';
import { LOCALES, locale, setLocale, t } from '../i18n';
import { theme, setTheme } from '../theme';
import TimeSelect from '../components/TimeSelect.vue';

const settings = useSettingsStore();
const toast = useToast();
const FIELDS = [
  'work_start_min', 'work_end_min', 'notify_before_min',
  'auto_stop', 'break_reminder_min', 'idle_pause_min', 'target_efficiency_pct',
];
const form = reactive({
  work_start_min: 540, work_end_min: 1440, notify_before_min: 10,
  auto_stop: true, break_reminder_min: 15, idle_pause_min: 10, target_efficiency_pct: 80,
});
const permission = ref('Notification' in window ? Notification.permission : 'unsupported');
const idlePermission = ref('prompt');

onMounted(async () => {
  idlePermission.value = await idlePermissionState();
  await settings.load();
  FIELDS.forEach((k) => (form[k] = settings[k]));
});

async function requestIdle() {
  idlePermission.value = await requestIdlePermission();
}

async function save() {
  try {
    await settings.save({ ...form });
    notifyPlansChanged();
    toast.success(t('settings.saved'));
  } catch (e) {
    toast.error(t('common.saveFailed'), errMsg(e));
  }
}

async function requestPermission() {
  permission.value = await Notification.requestPermission();
}
</script>

<template>
  <div class="settings-page">
    <section class="page-head"><h1>{{ t('settings.title') }}</h1></section>

    <section class="card form">
      <h3>{{ t('settings.appearance') }}</h3>
      <div class="row">
        <label>
          {{ t('settings.language') }}
          <select :value="locale" @change="setLocale($event.target.value)">
            <option v-for="l in LOCALES" :key="l.code" :value="l.code">{{ l.name }}</option>
          </select>
        </label>
        <label>
          {{ t('settings.theme') }}
          <div class="tabs inline theme-tabs">
            <button type="button" :class="{ active: theme === 'light' }" @click="setTheme('light')">☀️ {{ t('theme.light') }}</button>
            <button type="button" :class="{ active: theme === 'dark' }" @click="setTheme('dark')">🌙 {{ t('theme.dark') }}</button>
          </div>
        </label>
      </div>
    </section>

    <form class="card form" @submit.prevent="save">
      <h3>{{ t('settings.workHours') }}</h3>
      <p class="muted">{{ t('settings.workHoursHint') }}</p>
      <div class="row">
        <label>{{ t('planForm.start') }} <TimeSelect v-model="form.work_start_min" :min="0" :max="1425" :step="15" /></label>
        <label>{{ t('planForm.end') }} <TimeSelect v-model="form.work_end_min" :min="15" :max="1440" :step="15" /></label>
      </div>
      <p v-if="form.work_end_min > form.work_start_min" class="hint">
        {{ t('settings.workDay', { d: fmtDuration(form.work_end_min - form.work_start_min) }) }}
      </p>
      <p v-else class="error-text">{{ t('planForm.endAfterStart') }}</p>

      <h3>{{ t('settings.notifications') }}</h3>
      <label>
        {{ t('settings.notifyBefore') }}
        <div class="range-row">
          <input v-model.number="form.notify_before_min" type="range" min="0" max="60" step="1" />
          <b>{{ t('time.minutes', { m: form.notify_before_min }) }}</b>
        </div>
      </label>
      <div class="perm">
        <span>{{ t('settings.browserNotifications') }}: <b>{{ t(`settings.permission.${permission}`) }}</b></span>
        <button v-if="permission === 'default'" type="button" class="btn ghost sm" @click="requestPermission">
          {{ t('settings.allow') }}
        </button>
        <button
          type="button"
          class="btn ghost sm"
          @click="showNotification(t('settings.testTitle'), t('settings.testBody', { m: form.notify_before_min }))"
        >
          {{ t('settings.test') }}
        </button>
      </div>

      <h3>{{ t('tracking.settingsTitle') }}</h3>
      <p class="muted">{{ t('tracking.efficiencyHint') }}</p>
      <label class="check-row">
        <input v-model="form.auto_stop" type="checkbox" />
        <span>
          {{ t('tracking.autoStop') }}
          <small class="muted">{{ t('tracking.autoStopHint') }}</small>
        </span>
      </label>
      <label>
        {{ t('tracking.targetLabel') }}
        <div class="range-row">
          <input v-model.number="form.target_efficiency_pct" type="range" min="10" max="100" step="5" />
          <b>{{ form.target_efficiency_pct }}%</b>
        </div>
      </label>
      <label>
        {{ t('tracking.breakReminderLabel') }}
        <div class="range-row">
          <input v-model.number="form.break_reminder_min" type="range" min="0" max="120" step="5" />
          <b>{{ form.break_reminder_min ? t('time.minutes', { m: form.break_reminder_min }) : t('tracking.off') }}</b>
        </div>
      </label>
      <label>
        {{ t('tracking.idlePauseLabel') }}
        <div class="range-row">
          <input v-model.number="form.idle_pause_min" type="range" min="0" max="60" step="1" />
          <b>{{ form.idle_pause_min ? t('time.minutes', { m: form.idle_pause_min }) : t('tracking.off') }}</b>
        </div>
      </label>
      <div class="perm">
        <span>{{ t('tracking.idleDetection') }}: <b>{{ t(`tracking.idlePermission.${idlePermission}`) }}</b></span>
        <button v-if="idlePermission === 'prompt'" type="button" class="btn ghost sm" @click="requestIdle">
          {{ t('settings.allow') }}
        </button>
      </div>
      <p class="hint">{{ t('tracking.idleHint') }}</p>

      <div class="form-actions">
        <button class="btn primary" :disabled="form.work_end_min <= form.work_start_min">{{ t('common.save') }}</button>
      </div>
    </form>
  </div>
</template>
