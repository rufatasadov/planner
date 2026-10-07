<script setup>
import { ref, computed, watch } from 'vue';
import AppModal from './AppModal.vue';
import { addDays, weekDates, weekdayIndex, parseDate, WEEKDAYS, fmtDateLong } from '../utils/time';

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
    { label: 'Bu həftə', days: thisWeek },
    { label: 'Gələn həftə', days: weekDates(addDays(thisWeek[0], 7)) },
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
  <AppModal :show="show" title="Planı digər günlərə köçür" width="560px" @close="emit('close')">
    <p class="muted">
      Mənbə: <b>{{ fmtDateLong(sourceDate) }}</b> ({{ planCount }} plan). Hər yeni plana proyektin həmin andakı açıq
      taskları əlavə olunur.
    </p>
    <div class="chips">
      <button class="chip" @click="pick((d) => weekdayIndex(d) < 5)">Həftənin qalan iş günləri</button>
      <button class="chip" @click="pick(() => true)">Həftənin qalan günləri</button>
      <button class="chip" @click="selected = []">Təmizlə</button>
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
          <span>{{ WEEKDAYS[weekdayIndex(d)] }}</span>
          <b>{{ parseDate(d).getDate() }}</b>
        </button>
      </div>
    </div>
    <div class="radio-group">
      <label><input v-model="mode" type="radio" value="skip" /> Mövcud planlarla kəsişənləri ötür</label>
      <label><input v-model="mode" type="radio" value="replace" /> Həmin günlərin mövcud planlarını sil və əvəz et</label>
    </div>
    <template #footer>
      <button class="btn ghost" @click="emit('close')">Ləğv et</button>
      <button
        class="btn primary"
        :disabled="!selected.length || saving"
        @click="emit('generate', { target_dates: selected, mode })"
      >
        {{ selected.length }} günə generasiya et
      </button>
    </template>
  </AppModal>
</template>
