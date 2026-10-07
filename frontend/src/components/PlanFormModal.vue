<script setup>
import { reactive, watch, computed } from 'vue';
import AppModal from './AppModal.vue';
import TimeSelect from './TimeSelect.vue';
import { fmtDuration } from '../utils/time';
import { t } from '../i18n';

const props = defineProps({
  show: Boolean,
  plan: Object, // null => create
  projects: { type: Array, default: () => [] },
  defaults: { type: Object, default: () => ({}) }, // { start_min, end_min }
  workStart: Number,
  workEnd: Number,
  saving: Boolean,
});
const emit = defineEmits(['close', 'save']);

const form = reactive({ project_id: null, start_min: 540, end_min: 600, note: '' });

watch(
  () => props.show,
  (open) => {
    if (!open) return;
    const src = props.plan ?? props.defaults;
    form.project_id = props.plan?.project_id ?? props.projects[0]?.id ?? null;
    form.start_min = src.start_min ?? props.workStart;
    form.end_min = src.end_min ?? Math.min(form.start_min + 60, props.workEnd);
    form.note = props.plan?.note ?? '';
  },
);

watch(
  () => form.start_min,
  (start, prev) => {
    if (props.plan || prev === undefined) return;
    if (form.end_min <= start) form.end_min = Math.min(start + 60, props.workEnd);
  },
);

const selectedProject = computed(() => props.projects.find((p) => p.id === form.project_id));
const valid = computed(() => form.project_id && form.end_min > form.start_min);

function submit() {
  if (valid.value) emit('save', { ...form });
}
</script>

<template>
  <AppModal :show="show" :title="plan ? t('planForm.editTitle') : t('planForm.newTitle')" @close="emit('close')">
    <form class="form" @submit.prevent="submit">
      <label>
        {{ t('planForm.project') }}
        <div class="project-pick">
          <button
            v-for="p in projects"
            :key="p.id"
            type="button"
            class="chip"
            :class="{ active: form.project_id === p.id }"
            :style="{ '--c': p.color }"
            @click="form.project_id = p.id"
          >
            <span class="dot" :style="{ background: p.color }"></span>{{ p.name }}
          </button>
        </div>
        <span v-if="!projects.length" class="muted">{{ t('planForm.noProjects') }}</span>
      </label>
      <p v-if="selectedProject && !plan" class="hint">
        {{ t('planForm.openTasksHint', { n: selectedProject.open_task_count }) }}
      </p>
      <div class="row">
        <label>
          {{ t('planForm.start') }}
          <TimeSelect v-model="form.start_min" :min="workStart" :max="workEnd - 5" />
        </label>
        <label>
          {{ t('planForm.end') }}
          <TimeSelect v-model="form.end_min" :min="workStart + 5" :max="workEnd" />
        </label>
      </div>
      <p v-if="form.end_min > form.start_min" class="hint">
        {{ t('planForm.duration', { d: fmtDuration(form.end_min - form.start_min) }) }}
      </p>
      <p v-else class="error-text">{{ t('planForm.endAfterStart') }}</p>
      <label>
        {{ t('planForm.note') }}
        <textarea v-model="form.note" rows="2" :placeholder="t('planForm.optional')"></textarea>
      </label>
    </form>
    <template #footer>
      <button class="btn ghost" @click="emit('close')">{{ t('common.cancel') }}</button>
      <button class="btn primary" :disabled="!valid || saving" @click="submit">{{ t('common.save') }}</button>
    </template>
  </AppModal>
</template>
