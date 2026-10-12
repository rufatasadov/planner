<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { addDays, fmtDateLong, toDateStr, weekDates } from '../utils/time';
import { t } from '../i18n';
import NoteItem from '../components/NoteItem.vue';

const toast = useToast();
const today = toDateStr(new Date());

const RANGES = {
  today: () => [today, today],
  week: () => [weekDates(today)[0], today],
  month: () => [addDays(today, -29), today],
  all: () => ['', ''],
};

const projects = ref([]);
const notes = ref([]);
const loading = ref(false);
const projectId = ref('');
const from = ref(RANGES.week()[0]);
const to = ref(today);
const search = ref('');
const q = ref('');

const activeRange = computed(
  () => Object.keys(RANGES).find((k) => RANGES[k]().join() === [from.value, to.value].join()) ?? null,
);

const groups = computed(() => {
  const map = new Map();
  for (const n of notes.value) {
    const day = toDateStr(new Date(n.created_at));
    if (!map.has(day)) map.set(day, []);
    map.get(day).push(n);
  }
  return [...map].map(([day, items]) => ({ day, items }));
});

const taskCount = computed(() => new Set(notes.value.map((n) => n.task_id)).size);

async function load() {
  loading.value = true;
  try {
    const params = {};
    if (projectId.value) params.project_id = projectId.value;
    if (from.value) params.from = from.value;
    if (to.value) params.to = to.value;
    if (q.value) params.q = q.value;
    notes.value = (await api.get('/notes', { params })).data;
  } catch (e) {
    toast.error(t('common.loadFailed'), errMsg(e));
  } finally {
    loading.value = false;
  }
}

let searchTimer = null;
watch(search, (v) => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => (q.value = v.trim()), 300);
});
watch([projectId, from, to, q], load);

onMounted(async () => {
  load();
  try {
    projects.value = (await api.get('/projects')).data;
  } catch {
    /* project filter stays empty */
  }
});

function setRange(key) {
  [from.value, to.value] = RANGES[key]();
}

function onUpdated(note) {
  const i = notes.value.findIndex((n) => n.id === note.id);
  if (i >= 0) notes.value[i] = note;
}
</script>

<template>
  <div class="notes-page">
    <section class="page-head">
      <div>
        <h1>{{ t('notes.title') }}</h1>
        <p class="muted">{{ t('notes.summary', { n: notes.length, tasks: taskCount }) }}</p>
      </div>
    </section>

    <section class="card notes-filters">
      <div class="tabs inline">
        <button v-for="(_, key) in RANGES" :key="key" :class="{ active: activeRange === key }" @click="setRange(key)">
          {{ t(`notes.ranges.${key}`) }}
        </button>
      </div>
      <div class="filter-row">
        <input v-model="search" type="search" :placeholder="t('notes.search')" />
        <select v-model="projectId">
          <option value="">{{ t('notes.allProjects') }}</option>
          <option v-for="p in projects" :key="p.id" :value="p.id">{{ p.name }}</option>
        </select>
        <input v-model="from" type="date" :max="to || undefined" :title="t('notes.from')" />
        <input v-model="to" type="date" :min="from || undefined" :title="t('notes.to')" />
      </div>
    </section>

    <p v-if="!loading && !notes.length" class="card muted empty-notes">{{ t('notes.emptyFilter') }}</p>

    <section v-for="g in groups" :key="g.day" class="notes-day">
      <h3 class="notes-day-title">{{ fmtDateLong(g.day) }} <span class="muted small">· {{ g.items.length }}</span></h3>
      <TransitionGroup name="list" tag="div" class="notes-list">
        <NoteItem
          v-for="note in g.items"
          :key="note.id"
          :note="note"
          show-task
          @updated="onUpdated"
          @deleted="(id) => (notes = notes.filter((n) => n.id !== id))"
        />
      </TransitionGroup>
    </section>
  </div>
</template>
