<script setup>
import { ref, computed, watch } from 'vue';
import AppModal from './AppModal.vue';
import { addDays, weekDates, weekdayIndex, weekdayShort, parseDate, fmtDateLong } from '../utils/time';
import { t } from '../i18n';

const props = defineProps({
  show: Boolean,
  sourceDate: String,
  planCount: Number,
  saving: Boolean,
});
const emit = defineEmits(['close', 'generate']);

const selected = ref([]);
const mode = ref('skip');

const weeks = computed(() => {
  const thisWeek = weekDates(props.sourceDate);
  return [
    { label: t('generate.thisWeek'), days: thisWeek },
    { label: t('generate.nextWeek'), days: weekDates(addDays(thisWeek[0], 7)) },
  ];
});

watch(
  () => props.show,
  (open) => {
    if (open) {
      selected.value = [];
      mode.value = 'skip';
    }
  },
);

const toggle = (d) => {
  selected.value = selected.value.includes(d) ? selected.value.filter((x) => x !== d) : [...selected.value, d];
};

function pick(filter) {
  selected.value = weeks.value[0].days.filter((d) => d > props.sourceDate && filter(d));
}
</script>

<template>
  <AppModal :show="show" :title="t('generate.title')" width="560px" @close="emit('close')">
    <p class="muted">{{ t('generate.intro', { date: fmtDateLong(sourceDate), n: planCount }) }}</p>
    <div class="chips">
      <button class="chip" @click="pick((d) => weekdayIndex(d) < 5)">{{ t('generate.restWorkdays') }}</button>
      <button class="chip" @click="pick(() => true)">{{ t('generate.restDays') }}</button>
      <button class="chip" @click="selected = []">{{ t('generate.clear') }}</button>
    </div>
    <div v-for="w in weeks" :key="w.label" class="gen-week">
      <div class="muted small">{{ w.label }}</div>
      <div class="gen-days">
        <button
          v-for="d in w.days"
          :key="d"
          class="gen-day"
          :class="{ active: selected.includes(d), source: d === sourceDate }"
          :disabled="d === sourceDate"
          @click="toggle(d)"
        >
          <span>{{ weekdayShort(d) }}</span>
          <b>{{ parseDate(d).getDate() }}</b>
        </button>
      </div>
    </div>
    <div class="radio-group">
      <label><input v-model="mode" type="radio" value="skip" /> {{ t('generate.modeSkip') }}</label>
      <label><input v-model="mode" type="radio" value="replace" /> {{ t('generate.modeReplace') }}</label>
    </div>
    <template #footer>
      <button class="btn ghost" @click="emit('close')">{{ t('common.cancel') }}</button>
      <button
        class="btn primary"
        :disabled="!selected.length || saving"
        @click="emit('generate', { target_dates: selected, mode })"
      >
        {{ t('generate.submit', { n: selected.length }) }}
      </button>
    </template>
  </AppModal>
</template>
