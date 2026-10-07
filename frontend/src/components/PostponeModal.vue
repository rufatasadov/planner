<script setup>
import { reactive, watch } from 'vue';
import AppModal from './AppModal.vue';
import TimeSelect from './TimeSelect.vue';
import { addDays, fmtMin } from '../utils/time';
import { t } from '../i18n';

const props = defineProps({
  show: Boolean,
  plan: Object,
  workStart: Number,
  workEnd: Number,
  saving: Boolean,
});
const emit = defineEmits(['close', 'save']);

const form = reactive({ date: '', start_min: 540 });

watch(
  () => props.show,
  (open) => {
    if (!open || !props.plan) return;
    form.date = addDays(props.plan.plan_date, 1);
    form.start_min = props.plan.start_min;
  },
);

const duration = () => (props.plan ? props.plan.end_min - props.plan.start_min : 0);

function quick(days) {
  form.date = addDays(props.plan.plan_date, days);
}
</script>

<template>
  <AppModal :show="show" :title="t('postpone.title')" @close="emit('close')">
    <div v-if="plan" class="form">
      <p>
        <span class="dot" :style="{ background: plan.project_color }"></span>
        <b>{{ plan.project_name }}</b> ({{ fmtMin(plan.start_min) }}-{{ fmtMin(plan.end_min) }})
      </p>
      <div class="chips">
        <button type="button" class="chip" @click="quick(0)">{{ t('postpone.today') }}</button>
        <button type="button" class="chip" @click="quick(1)">{{ t('postpone.tomorrow') }}</button>
        <button type="button" class="chip" @click="quick(2)">{{ t('postpone.in2days') }}</button>
        <button type="button" class="chip" @click="quick(7)">{{ t('postpone.in1week') }}</button>
      </div>
      <div class="row">
        <label>{{ t('postpone.date') }} <input v-model="form.date" type="date" /></label>
        <label>
          {{ t('planForm.start') }}
          <TimeSelect v-model="form.start_min" :min="workStart" :max="workEnd - duration()" />
        </label>
      </div>
      <p class="hint">
        {{ t('postpone.newTime', { range: `${fmtMin(form.start_min)} – ${fmtMin(form.start_min + duration())}` }) }}
      </p>
    </div>
    <template #footer>
      <button class="btn ghost" @click="emit('close')">{{ t('common.cancel') }}</button>
      <button
        class="btn primary"
        :disabled="saving || !form.date"
        @click="emit('save', { date: form.date, start_min: form.start_min, end_min: form.start_min + duration() })"
      >
        {{ t('postpone.submit') }}
      </button>
    </template>
  </AppModal>
</template>
