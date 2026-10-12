<script setup>
import { computed, ref } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { renderMarkdown } from '../utils/markdown';
import { fmtDateLong, fmtMin, toDateStr } from '../utils/time';
import { t } from '../i18n';
import MarkdownEditor from './MarkdownEditor.vue';

const props = defineProps({
  note: { type: Object, required: true },
  showTask: Boolean,
  showDate: Boolean,
});
const emit = defineEmits(['updated', 'deleted']);
const toast = useToast();

const editing = ref(false);
const draft = ref('');
const saving = ref(false);

const html = computed(() => renderMarkdown(props.note.body));
const created = computed(() => new Date(props.note.created_at));
const time = computed(() => fmtMin(created.value.getHours() * 60 + created.value.getMinutes()));
const edited = computed(() => new Date(props.note.updated_at) - created.value > 1000);

function startEdit() {
  draft.value = props.note.body;
  editing.value = true;
}

async function save() {
  if (!draft.value.trim() || saving.value) return;
  saving.value = true;
  try {
    const { data } = await api.put(`/notes/${props.note.id}`, { body: draft.value });
    editing.value = false;
    emit('updated', data);
  } catch (e) {
    toast.error(t('notes.failed'), errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function remove() {
  if (!confirm(t('notes.confirmDelete'))) return;
  try {
    await api.delete(`/notes/${props.note.id}`);
    emit('deleted', props.note.id);
  } catch (e) {
    toast.error(t('common.deleteFailed'), errMsg(e));
  }
}
</script>

<template>
  <article class="note" :style="{ '--c': note.project_color }">
    <header class="note-head">
      <div class="note-meta">
        <span class="note-time">
          <template v-if="showDate">{{ fmtDateLong(toDateStr(created)) }}, </template>{{ time }}
        </span>
        <span v-if="note.plan_id" class="note-chip" :title="t('notes.plan')">
          📅 {{ fmtMin(note.plan_start_min) }}–{{ fmtMin(note.plan_end_min) }}
          <template v-if="note.plan_date !== toDateStr(created)"> · {{ note.plan_date }}</template>
        </span>
        <template v-if="showTask">
          <RouterLink :to="`/projects/${note.project_id}`" class="note-chip project">
            <span class="dot" :style="{ background: note.project_color }"></span>{{ note.project_name }}
          </RouterLink>
          <span class="note-task">{{ note.task_title }}</span>
        </template>
        <span v-if="edited" class="muted small">· {{ t('notes.edited') }}</span>
      </div>
      <div v-if="!editing" class="actions">
        <button class="icon-btn" :title="t('common.edit')" @click="startEdit">✎</button>
        <button class="icon-btn danger" :title="t('common.delete')" @click="remove">🗑</button>
      </div>
    </header>

    <template v-if="editing">
      <MarkdownEditor v-model="draft" autofocus :rows="5" @submit="save" @cancel="editing = false" />
      <div class="note-edit-actions">
        <button class="btn ghost sm" @click="editing = false">{{ t('common.cancel') }}</button>
        <button class="btn primary sm" :disabled="!draft.trim() || saving" @click="save">{{ t('common.save') }}</button>
      </div>
    </template>
    <div v-else class="md" v-html="html"></div>
  </article>
</template>
