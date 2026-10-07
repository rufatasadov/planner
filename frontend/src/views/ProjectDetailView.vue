<script setup>
import { ref, computed, onMounted } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { STATUSES } from '../utils/status';
import { t } from '../i18n';
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
  { value: 'open', match: (task) => ['todo', 'in_progress'].includes(task.status) },
  { value: 'done', match: (task) => task.status === 'done' },
  { value: 'cancelled', match: (task) => task.status === 'cancelled' },
  { value: 'all', match: () => true },
];

const visible = computed(() => tasks.value.filter(FILTERS.find((f) => f.value === filter.value).match));
const counts = computed(() =>
  Object.fromEntries(STATUSES.map((s) => [s.value, tasks.value.filter((task) => task.status === s.value).length])),
);

async function load() {
  try {
    const [p, res] = await Promise.all([
      api.get(`/projects/${props.id}`),
      api.get('/tasks', { params: { project_id: props.id } }),
    ]);
    project.value = p.data;
    tasks.value = res.data;
  } catch (e) {
    toast.error(t('common.loadFailed'), errMsg(e));
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
    toast.error(t('tasks.addFailed'), errMsg(e));
  }
}

async function setStatus(task, status) {
  const prev = task.status;
  task.status = status;
  try {
    await api.patch(`/tasks/${task.id}/status`, { status });
  } catch (e) {
    task.status = prev;
    toast.error(t('tasks.statusFailed'), errMsg(e));
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
    toast.error(t('common.saveFailed'), errMsg(e));
  }
}

async function remove(task) {
  if (!confirm(t('tasks.confirmDelete', { title: task.title }))) return;
  try {
    await api.delete(`/tasks/${task.id}`);
    tasks.value = tasks.value.filter((x) => x.id !== task.id);
  } catch (e) {
    toast.error(t('common.deleteFailed'), errMsg(e));
  }
}
</script>

<template>
  <div v-if="project">
    <RouterLink to="/projects" class="back">‹ {{ t('projects.title') }}</RouterLink>
    <section class="page-head">
      <div>
        <h1><span class="dot lg" :style="{ background: project.color }"></span> {{ project.name }}</h1>
        <p class="muted">{{ project.description }}</p>
      </div>
      <div class="status-counts">
        <span v-for="s in STATUSES" :key="s.value" class="pill" :style="{ '--s': s.color }">
          {{ t(`status.${s.value}`) }}: <b>{{ counts[s.value] }}</b>
        </span>
      </div>
    </section>

    <section class="card">
      <form class="add-task" @submit.prevent="addTask">
        <input v-model="newTitle" :placeholder="t('tasks.addPlaceholder')" maxlength="500" />
        <button class="btn primary" :disabled="!newTitle.trim()">{{ t('tasks.add') }}</button>
      </form>

      <div class="tabs inline">
        <button v-for="f in FILTERS" :key="f.value" :class="{ active: filter === f.value }" @click="filter = f.value">
          {{ t(`tasks.filter.${f.value}`) }}
        </button>
      </div>

      <ul class="task-list big">
        <TransitionGroup name="list">
          <li v-for="task in visible" :key="task.id" :class="{ done: task.status === 'done' }">
            <input
              type="checkbox"
              :checked="task.status === 'done'"
              @change="setStatus(task, $event.target.checked ? 'done' : 'todo')"
            />
            <input
              v-if="editingId === task.id"
              v-model="editTitle"
              v-focus
              class="inline-edit"
              @keyup.enter="saveEdit(task)"
              @keyup.esc="editingId = null"
              @blur="saveEdit(task)"
            />
            <span v-else class="task-title" :title="t('tasks.dblClickToEdit')" @dblclick="startEdit(task)">{{ task.title }}</span>
            <TaskStatusSelect :model-value="task.status" @update:model-value="setStatus(task, $event)" />
            <button class="icon-btn danger" :title="t('common.delete')" @click="remove(task)">🗑</button>
          </li>
        </TransitionGroup>
        <li v-if="!visible.length" class="muted">{{ t('tasks.emptyFilter') }}</li>
      </ul>
    </section>
  </div>
</template>
