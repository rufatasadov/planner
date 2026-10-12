<script setup>
import { ref, computed, onMounted } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { STATUSES } from '../utils/status';
import { buildTree, moveInList } from '../utils/tasks';
import { t } from '../i18n';
import TaskRow from '../components/TaskRow.vue';
import TaskNotesModal from '../components/TaskNotesModal.vue';
import AppModal from '../components/AppModal.vue';

const props = defineProps({ id: String });
const toast = useToast();

const project = ref(null);
const tasks = ref([]);
const filter = ref('open');
const newTitle = ref('');
const notesTask = ref(null);
const collapsed = ref(new Set());
const addingSubFor = ref(null);
const subTitle = ref('');
const moving = ref(null); // { task, parentId }
const vFocus = { mounted: (el) => el.focus() };

const FILTERS = [
  { value: 'open', match: (task) => ['todo', 'in_progress'].includes(task.status) },
  { value: 'done', match: (task) => task.status === 'done' },
  { value: 'cancelled', match: (task) => task.status === 'cancelled' },
  { value: 'all', match: () => true },
];

const tree = computed(() => buildTree(tasks.value));
const visible = computed(() => {
  const match = FILTERS.find((f) => f.value === filter.value).match;
  return tree.value
    .map((node) => ({ ...node, shown: node.children.filter(match), matches: match(node.task) }))
    .filter((node) => node.matches || node.shown.length || addingSubFor.value === node.task.id);
});
const counts = computed(() =>
  Object.fromEntries(STATUSES.map((s) => [s.value, tasks.value.filter((task) => task.status === s.value).length])),
);
const progressOf = (node) =>
  node.children.length
    ? { done: node.children.filter((c) => c.status === 'done').length, total: node.children.length }
    : null;
const parentOptions = computed(() =>
  moving.value ? tree.value.map((n) => n.task).filter((task) => task.id !== moving.value.task.id) : [],
);
const movingHasChildren = computed(
  () => !!moving.value && tasks.value.some((task) => task.parent_id === moving.value.task.id),
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

function applyParent(parent) {
  if (!parent) return;
  const task = tasks.value.find((x) => x.id === parent.id);
  if (task) task.status = parent.status;
  if (!parent.changed) return;
  if (parent.status === 'done') toast.success(t('tasks.parentDone', { title: parent.title }));
  else toast.push({ type: 'info', title: t('tasks.parentReopened', { title: parent.title }) });
}

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

function openAddSub(task) {
  addingSubFor.value = task.id;
  subTitle.value = '';
  const next = new Set(collapsed.value);
  next.delete(task.id);
  collapsed.value = next;
}

async function addSubtask(parent) {
  const title = subTitle.value.trim();
  if (!title) return;
  try {
    const { data } = await api.post('/tasks', { parent_id: parent.id, title });
    tasks.value.push(data);
    subTitle.value = '';
    applyParent(data.parent);
  } catch (e) {
    toast.error(t('tasks.addFailed'), errMsg(e));
  }
}

function toggle(task) {
  const next = new Set(collapsed.value);
  next.has(task.id) ? next.delete(task.id) : next.add(task.id);
  collapsed.value = next;
}

async function setStatus(task, status) {
  const prev = task.status;
  task.status = status;
  try {
    const { data } = await api.patch(`/tasks/${task.id}/status`, { status });
    applyParent(data.parent);
  } catch (e) {
    task.status = prev;
    toast.error(t('tasks.statusFailed'), errMsg(e));
  }
}

async function rename(task, title) {
  try {
    const { data } = await api.put(`/tasks/${task.id}`, { title });
    task.title = data.title;
  } catch (e) {
    toast.error(t('common.saveFailed'), errMsg(e));
  }
}

async function remove(task) {
  const subs = tasks.value.filter((x) => x.parent_id === task.id).length;
  const msg = subs
    ? t('tasks.confirmDeleteWithSubs', { title: task.title, n: subs })
    : t('tasks.confirmDelete', { title: task.title });
  if (!confirm(msg)) return;
  try {
    const { data } = await api.delete(`/tasks/${task.id}`);
    tasks.value = tasks.value.filter((x) => x.id !== task.id && x.parent_id !== task.id);
    applyParent(data?.parent);
  } catch (e) {
    toast.error(t('common.deleteFailed'), errMsg(e));
  }
}

function openMove(task) {
  moving.value = { task, parentId: task.parent_id ?? '' };
}

async function saveMove() {
  const { task, parentId } = moving.value;
  const target = parentId === '' ? null : Number(parentId);
  moving.value = null;
  if (target === (task.parent_id ?? null)) return;
  try {
    const { data } = await api.put(`/tasks/${task.id}`, { parent_id: target });
    await load();
    applyParent(data.old_parent);
    applyParent(data.parent);
    toast.success(target ? t('tasks.movedUnder', { title: data.parent_title }) : t('tasks.madeIndependent'));
  } catch (e) {
    toast.error(t('common.saveFailed'), errMsg(e));
  }
}

// Drag and drop reordering among siblings (top-level tasks, or subtasks of the same parent).
const armed = ref(null);
const dragging = ref(null);
const dropTarget = ref(null);

function siblingsOf(parentId) {
  return parentId ? tree.value.find((n) => n.task.id === parentId)?.children ?? [] : tree.value.map((n) => n.task);
}

function onDragStart(e, task) {
  dragging.value = { id: task.id, parentId: task.parent_id ?? null };
  e.dataTransfer.effectAllowed = 'move';
  e.dataTransfer.setData('text/plain', String(task.id));
}

function onDragOver(e, task) {
  const d = dragging.value;
  if (!d || d.id === task.id || (task.parent_id ?? null) !== d.parentId) return;
  e.preventDefault();
  const rect = e.currentTarget.getBoundingClientRect();
  dropTarget.value = { id: task.id, after: e.clientY > rect.top + rect.height / 2 };
}

function onDragEnd() {
  armed.value = null;
  dragging.value = null;
  dropTarget.value = null;
}

async function onDrop(task) {
  const d = dragging.value;
  const target = dropTarget.value;
  onDragEnd();
  if (!d || !target || target.id !== task.id) return;
  const ordered = moveInList(siblingsOf(d.parentId), d.id, target.id, target.after);
  ordered.forEach((x, i) => (x.position = i + 1));
  try {
    await api.put('/tasks/reorder', { ids: ordered.map((x) => x.id) });
  } catch (e) {
    toast.error(t('common.saveFailed'), errMsg(e));
    load();
  }
}

const dropClass = (task) =>
  dropTarget.value?.id === task.id ? (dropTarget.value.after ? 'drop-after' : 'drop-before') : '';

const rowEvents = (task) => ({
  draggable: armed.value === task.id,
  onDragstart: (e) => onDragStart(e, task),
  onDragover: (e) => onDragOver(e, task),
  onDrop: () => onDrop(task),
  onDragend: onDragEnd,
});
</script>

<template>
  <div v-if="project" @mouseup="armed = dragging ? armed : null">
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

      <ul class="task-list big task-tree">
        <template v-for="node in visible" :key="node.task.id">
          <TaskRow
            v-bind="rowEvents(node.task)"
            :class="dropClass(node.task)"
            :task="node.task"
            :expanded="node.children.length ? !collapsed.has(node.task.id) : null"
            :progress="progressOf(node)"
            :muted="!node.matches"
            reorderable
            @grab="armed = node.task.id"
            @toggle="toggle(node.task)"
            @status="setStatus(node.task, $event)"
            @rename="rename(node.task, $event)"
            @notes="notesTask = node.task"
            @add-sub="openAddSub(node.task)"
            @move="openMove(node.task)"
            @remove="remove(node.task)"
          />
          <template v-if="!collapsed.has(node.task.id)">
            <TaskRow
              v-for="child in node.shown"
              :key="child.id"
              v-bind="rowEvents(child)"
              :class="dropClass(child)"
              :task="child"
              sub
              reorderable
              @grab="armed = child.id"
              @status="setStatus(child, $event)"
              @rename="rename(child, $event)"
              @notes="notesTask = child"
              @move="openMove(child)"
              @remove="remove(child)"
            />
            <li v-if="addingSubFor === node.task.id" class="task-row sub add-sub-row">
              <form class="add-sub" @submit.prevent="addSubtask(node.task)">
                <input
                  v-model="subTitle"
                  v-focus
                  :placeholder="t('tasks.subtaskPlaceholder')"
                  maxlength="500"
                  @keyup.esc="addingSubFor = null"
                />
                <button class="btn primary sm" :disabled="!subTitle.trim()">{{ t('tasks.add') }}</button>
                <button type="button" class="btn ghost sm" @click="addingSubFor = null">{{ t('common.cancel') }}</button>
              </form>
            </li>
          </template>
        </template>
        <li v-if="!visible.length" class="muted">{{ t('tasks.emptyFilter') }}</li>
      </ul>
    </section>

    <TaskNotesModal :task="notesTask" @close="notesTask = null" @count="notesTask && (notesTask.note_count = $event)" />

    <AppModal :show="!!moving" :title="t('tasks.moveTitle', { title: moving?.task.title ?? '' })" @close="moving = null">
      <template v-if="moving">
        <p v-if="movingHasChildren" class="muted">{{ t('tasks.cannotNest') }}</p>
        <label class="move-label">
          {{ t('tasks.moveTo') }}
          <select v-model="moving.parentId">
            <option value="">{{ t('tasks.independent') }}</option>
            <option v-for="p in parentOptions" :key="p.id" :value="p.id" :disabled="movingHasChildren">
              {{ p.title }}
            </option>
          </select>
        </label>
      </template>
      <template #footer>
        <button class="btn ghost" @click="moving = null">{{ t('common.cancel') }}</button>
        <button class="btn primary" @click="saveMove">{{ t('common.save') }}</button>
      </template>
    </AppModal>
  </div>
</template>
