<script setup>
import { ref } from 'vue';
import { t } from '../i18n';
import TaskStatusSelect from './TaskStatusSelect.vue';

const props = defineProps({
  task: { type: Object, required: true },
  sub: Boolean,
  expanded: { type: Boolean, default: null }, // null: no subtasks
  progress: { type: Object, default: null }, // { done, total }
  reorderable: Boolean,
  muted: Boolean, // shown only because a subtask matches the filter
});
const emit = defineEmits(['toggle', 'status', 'rename', 'notes', 'add-sub', 'move', 'remove', 'grab']);

const editing = ref(false);
const title = ref('');
const vFocus = { mounted: (el) => el.focus() };

function startEdit() {
  title.value = props.task.title;
  editing.value = true;
}

function save() {
  if (!editing.value) return;
  editing.value = false;
  const v = title.value.trim();
  if (v && v !== props.task.title) emit('rename', v);
}
</script>

<template>
  <li class="task-row" :class="{ done: task.status === 'done', sub, muted }">
    <span v-if="reorderable" class="drag-handle" :title="t('tasks.dragToReorder')" @mousedown="emit('grab')">⋮⋮</span>
    <button
      v-if="!sub"
      class="expand-btn"
      :class="{ open: expanded, 'no-subs': expanded === null }"
      :disabled="expanded === null"
      :title="expanded ? t('tasks.collapse') : t('tasks.expand')"
      @click="emit('toggle')"
    >
      ▸
    </button>
    <input
      type="checkbox"
      :checked="task.status === 'done'"
      @change="emit('status', $event.target.checked ? 'done' : 'todo')"
    />
    <input
      v-if="editing"
      v-model="title"
      v-focus
      class="inline-edit"
      @keyup.enter="save"
      @keyup.esc="editing = false"
      @blur="save"
    />
    <span v-else class="task-title" :title="t('tasks.dblClickToEdit')" @dblclick="startEdit">
      <small v-if="task.parent_title && !sub" class="parent-crumb">{{ task.parent_title }} ›</small>
      {{ task.title }}
    </span>
    <span
      v-if="progress && progress.total"
      class="sub-progress"
      :class="{ complete: progress.done === progress.total }"
      :title="t('tasks.subtaskProgress', { done: progress.done, total: progress.total })"
    >
      <span class="sub-progress-bar"><span :style="{ width: (progress.done / progress.total) * 100 + '%' }"></span></span>
      {{ progress.done }}/{{ progress.total }}
    </span>
    <div class="row-actions">
      <button v-if="!sub" class="icon-btn" :title="t('tasks.addSubtask')" @click="emit('add-sub')">＋</button>
      <button class="icon-btn" :title="t('tasks.move')" @click="emit('move')">⇄</button>
      <button
        class="note-btn"
        :class="{ has: task.note_count }"
        :title="t('notes.open')"
        @click="emit('notes')"
      >
        📝<span v-if="task.note_count">{{ task.note_count }}</span>
      </button>
    </div>
    <TaskStatusSelect :model-value="task.status" @update:model-value="emit('status', $event)" />
    <button class="icon-btn danger" :title="t('common.delete')" @click="emit('remove')">🗑</button>
  </li>
</template>
