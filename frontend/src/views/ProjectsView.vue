<script setup>
import { ref, reactive, onMounted } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { PROJECT_COLORS } from '../utils/status';
import { t } from '../i18n';
import AppModal from '../components/AppModal.vue';

const toast = useToast();
const projects = ref([]);
const loading = ref(true);
const modalOpen = ref(false);
const editing = ref(null);
const form = reactive({ name: '', description: '', color: PROJECT_COLORS[0] });

async function load() {
  try {
    projects.value = (await api.get('/projects')).data;
  } catch (e) {
    toast.error(t('common.loadFailed'), errMsg(e));
  } finally {
    loading.value = false;
  }
}
onMounted(load);

function openForm(p = null) {
  editing.value = p;
  Object.assign(form, {
    name: p?.name ?? '',
    description: p?.description ?? '',
    color: p?.color ?? PROJECT_COLORS[projects.value.length % PROJECT_COLORS.length],
  });
  modalOpen.value = true;
}

async function save() {
  try {
    if (editing.value) await api.put(`/projects/${editing.value.id}`, form);
    else await api.post('/projects', form);
    toast.success(editing.value ? t('projects.updated') : t('projects.created'));
    modalOpen.value = false;
    await load();
  } catch (e) {
    toast.error(t('common.saveFailed'), errMsg(e));
  }
}

async function remove(p) {
  if (!confirm(t('projects.confirmDelete', { name: p.name }))) return;
  try {
    await api.delete(`/projects/${p.id}`);
    toast.success(t('projects.deleted'));
    await load();
  } catch (e) {
    toast.error(t('common.deleteFailed'), errMsg(e));
  }
}

const pct = (p) => (p.task_count ? Math.round((p.done_task_count / p.task_count) * 100) : 0);
</script>

<template>
  <div>
    <section class="page-head">
      <h1>{{ t('projects.title') }}</h1>
      <button class="btn primary" @click="openForm()">+ {{ t('projects.new') }}</button>
    </section>

    <div v-if="!loading && !projects.length" class="empty card">
      <div class="big-emoji">📁</div>
      <p>{{ t('projects.empty') }}</p>
      <button class="btn primary" @click="openForm()">{{ t('projects.create') }}</button>
    </div>

    <TransitionGroup name="list" tag="div" class="project-grid">
      <RouterLink
        v-for="p in projects"
        :key="p.id"
        :to="`/projects/${p.id}`"
        class="project-card card"
        :style="{ '--c': p.color }"
      >
        <div class="pc-head">
          <h3>{{ p.name }}</h3>
          <div class="actions" @click.prevent>
            <button class="icon-btn" :title="t('common.edit')" @click="openForm(p)">✎</button>
            <button class="icon-btn danger" :title="t('common.delete')" @click="remove(p)">🗑</button>
          </div>
        </div>
        <p class="muted desc">{{ p.description || t('projects.noDescription') }}</p>
        <div class="pc-stats">
          <span><b>{{ p.open_task_count }}</b> {{ t('projects.open') }}</span>
          <span><b>{{ p.done_task_count }}</b> {{ t('projects.done') }}</span>
          <span><b>{{ p.task_count }}</b> {{ t('projects.total') }}</span>
        </div>
        <div class="progress-line"><div :style="{ width: pct(p) + '%' }"></div></div>
        <small class="muted">{{ t('projects.completed', { p: pct(p) }) }}</small>
      </RouterLink>
    </TransitionGroup>

    <AppModal :show="modalOpen" :title="editing ? t('projects.editTitle') : t('projects.newTitle')" @close="modalOpen = false">
      <form class="form" @submit.prevent="save">
        <label>{{ t('projects.name') }} <input v-model="form.name" required maxlength="255" /></label>
        <label>{{ t('projects.description') }} <textarea v-model="form.description" rows="3"></textarea></label>
        <label>
          {{ t('projects.color') }}
          <div class="color-pick">
            <button
              v-for="c in PROJECT_COLORS"
              :key="c"
              type="button"
              class="swatch"
              :class="{ active: form.color === c }"
              :style="{ background: c }"
              @click="form.color = c"
            ></button>
          </div>
        </label>
      </form>
      <template #footer>
        <button class="btn ghost" @click="modalOpen = false">{{ t('common.cancel') }}</button>
        <button class="btn primary" :disabled="!form.name.trim()" @click="save">{{ t('common.save') }}</button>
      </template>
    </AppModal>
  </div>
</template>
