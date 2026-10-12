<script setup>
import { ref, watch } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { t } from '../i18n';
import AppModal from './AppModal.vue';
import MarkdownEditor from './MarkdownEditor.vue';
import NoteItem from './NoteItem.vue';

const props = defineProps({
  task: { type: Object, default: null }, // { id, title }; modal is open when set
  planId: { type: Number, default: null }, // new notes are linked to this plan
});
const emit = defineEmits(['close', 'count']);
const toast = useToast();

const notes = ref([]);
const loading = ref(false);
const draft = ref('');
const saving = ref(false);

watch(
  () => props.task?.id,
  async (id) => {
    notes.value = [];
    draft.value = '';
    if (!id) return;
    loading.value = true;
    try {
      notes.value = (await api.get('/notes', { params: { task_id: id } })).data;
      emit('count', notes.value.length);
    } catch (e) {
      toast.error(t('common.loadFailed'), errMsg(e));
    } finally {
      loading.value = false;
    }
  },
  { immediate: true },
);

async function add() {
  if (!draft.value.trim() || saving.value) return;
  saving.value = true;
  try {
    const { data } = await api.post('/notes', { task_id: props.task.id, plan_id: props.planId, body: draft.value });
    notes.value.unshift(data);
    draft.value = '';
    emit('count', notes.value.length);
    toast.success(t('notes.saved'));
  } catch (e) {
    toast.error(t('notes.failed'), errMsg(e));
  } finally {
    saving.value = false;
  }
}

function onUpdated(note) {
  const i = notes.value.findIndex((n) => n.id === note.id);
  if (i >= 0) notes.value[i] = note;
}

function onDeleted(id) {
  notes.value = notes.value.filter((n) => n.id !== id);
  emit('count', notes.value.length);
}
</script>

<template>
  <AppModal :show="!!task" :title="t('notes.forTask', { title: task?.title ?? '' })" width="720px" @close="emit('close')">
    <div class="notes-modal">
      <form class="note-new" @submit.prevent="add">
        <MarkdownEditor v-model="draft" autofocus :placeholder="t('notes.placeholder')" @submit="add" />
        <div class="note-edit-actions">
          <span v-if="planId" class="muted small">📅 {{ t('notes.linkedToPlan') }}</span>
          <button class="btn primary sm" :disabled="!draft.trim() || saving">{{ t('notes.add') }}</button>
        </div>
      </form>

      <div class="notes-list">
        <div v-if="loading" class="muted">…</div>
        <p v-else-if="!notes.length" class="muted empty-notes">{{ t('notes.empty') }}</p>
        <TransitionGroup name="list">
          <NoteItem
            v-for="note in notes"
            :key="note.id"
            :note="note"
            show-date
            @updated="onUpdated"
            @deleted="onDeleted"
          />
        </TransitionGroup>
      </div>
    </div>
  </AppModal>
</template>
