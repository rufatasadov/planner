<script setup>
import { ref, computed, onMounted } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { STATUSES } from '../utils/status';
import TaskStatusSelect from '../components/TaskStatusSelect.vue';

const props = defineProps({ id: String });
const toast = useToast();

const project = ref(null);
const tasks = ref([]);
const filter = ref('open');
const newTitle = ref('');
const editingId = ref(null);
const editTitle = ref('');
const vFocus = { mounted: (el) => el.focus() };

const FILTERS = [
  { value: 'open', label: 'Açıq', match: (t) => ['todo', 'in_progress'].includes(t.status) },
  { value: 'done', label: 'Bitmiş', match: (t) => t.status === 'done' },
  { value: 'cancelled', label: 'Ləğv', match: (t) => t.status === 'cancelled' },
  { value: 'all', label: 'Hamısı', match: () => true },
];

const visible = computed(() => tasks.value.filter(FILTERS.find((f) => f.value === filter.value).match));
const counts = computed(() => Object.fromEntries(STATUSES.map((s) => [s.value, tasks.value.filter((t) => t.status === s.value).length])));

async function load() {
  try {
    const [p, t] = await Promise.all([api.get(`/projects/${props.id}`), api.get('/tasks', { params: { project_id: props.id } })]);
    project.value = p.data;
    tasks.value = t.data;
  } catch (e) {
    toast.error('Yüklənmədi', errMsg(e));
  }
}
onMounted(load);

async function addTask() {
  const title = newTitle.value.trim();
  if (!title) return;
  try {
    const { data } = await api.post('/tasks', { project_id: Number(props.id), title });
    tasks.value.push(data);
    newTitle.value = '';
    if (filter.value !== 'open' && filter.value !== 'all') filter.value = 'open';
  } catch (e) {
    toast.error('Task əlavə olunmadı', errMsg(e));
  }
}

async function setStatus(task, status) {
  const prev = task.status;
  task.status = status;
  try {
    await api.patch(`/tasks/${task.id}/status`, { status });
  } catch (e) {
    task.status = prev;
    toast.error('Status dəyişmədi', errMsg(e));
  }
}

function startEdit(task) {
  editingId.value = task.id;
  editTitle.value = task.title;
}

async function saveEdit(task) {
  const title = editTitle.value.trim();
  editingId.value = null;
  if (!title || title === task.title) return;
  try {
    const { data } = await api.put(`/tasks/${task.id}`, { title });
    task.title = data.title;
  } catch (e) {
    toast.error('Yadda saxlanmadı', errMsg(e));
  }
}

async function remove(task) {
  if (!confirm(`"${task.title}" silinsin?`)) return;
  try {
    await api.delete(`/tasks/${task.id}`);
    tasks.value = tasks.value.filter((t) => t.id !== task.id);
  } catch (e) {
    toast.error('Silinmədi', errMsg(e));
  }
}
</script>

<template>
  <div v-if="project">
    <RouterLink to="/projects" class="back">‹ Proyektlər</RouterLink>
    <section class="page-head">
      <div>
        <h1><span class="dot lg" :style="{ background: project.color }"></span> {{ project.name }}</h1>
        <p class="muted">{{ project.description }}</p>
      </div>
      <div class="status-counts">
        <span v-for="s in STATUSES" :key="s.value" class="pill" :style="{ '--s': s.color }">
          {{ s.label }}: <b>{{ counts[s.value] }}</b>
        </span>
      </div>
    </section>

    <section class="card">
      <form class="add-task" @submit.prevent="addTask">
        <input v-model="newTitle" placeholder="Yeni task əlavə et və Enter bas..." maxlength="500" />
        <button class="btn primary" :disabled="!newTitle.trim()">Əlavə et</button>
      </form>

      <div class="tabs inline">
        <button v-for="f in FILTERS" :key="f.value" :class="{ active: filter === f.value }" @click="filter = f.value">
          {{ f.label }}
        </button>
      </div>

      <ul class="task-list big">
        <TransitionGroup name="list">
          <li v-for="t in visible" :key="t.id" :class="{ done: t.status === 'done' }">
            <input
              type="checkbox"
              :checked="t.status === 'done'"
              @change="setStatus(t, $event.target.checked ? 'done' : 'todo')"
            />
            <input
              v-if="editingId === t.id"
              v-model="editTitle"
              class="inline-edit"
              @keyup.enter="saveEdit(t)"
              @keyup.esc="editingId = null"
              @blur="saveEdit(t)"
              v-focus
            />
            <span v-else class="task-title" title="Redaktə üçün iki dəfə klikləyin" @dblclick="startEdit(t)">{{ t.title }}</span>
            <TaskStatusSelect :model-value="t.status" @update:model-value="setStatus(t, $event)" />
            <button class="icon-btn danger" title="Sil" @click="remove(t)">🗑</button>
          </li>
        </TransitionGroup>
        <li v-if="!visible.length" class="muted">Bu filtrdə task yoxdur.</li>
      </ul>
    </section>
  </div>
</template>