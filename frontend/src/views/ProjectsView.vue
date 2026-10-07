<script setup>
import { ref, reactive, onMounted } from 'vue';
import api, { errMsg } from '../api';
import { useToast } from '../stores/toast';
import { PROJECT_COLORS } from '../utils/status';
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
    toast.error('Yüklənmədi', errMsg(e));
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
    toast.success(editing.value ? 'Proyekt yeniləndi' : 'Proyekt yaradıldı');
    modalOpen.value = false;
    await load();
  } catch (e) {
    toast.error('Yadda saxlanmadı', errMsg(e));
  }
}

async function remove(p) {
  if (!confirm(`"${p.name}" proyekti, onun taskları və planları silinsin?`)) return;
  try {
    await api.delete(`/projects/${p.id}`);
    toast.success('Proyekt silindi');
    await load();
  } catch (e) {
    toast.error('Silinmədi', errMsg(e));
  }
}

const pct = (p) => (p.task_count ? Math.round((p.done_task_count / p.task_count) * 100) : 0);
</script>

<template>
  <div>
    <section class="page-head">
      <h1>Proyektlər</h1>
      <button class="btn primary" @click="openForm()">+ Yeni proyekt</button>
    </section>

    <div v-if="!loading && !projects.length" class="empty card">
      <div class="big-emoji">📁</div>
      <p>Hələ proyekt yoxdur. İlk proyektinizi yaradın.</p>
      <button class="btn primary" @click="openForm()">Proyekt yarat</button>
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
            <button class="icon-btn" title="Redaktə" @click="openForm(p)">✎</button>
            <button class="icon-btn danger" title="Sil" @click="remove(p)">🗑</button>
          </div>
        </div>
        <p class="muted desc">{{ p.description || 'Təsvir yoxdur' }}</p>
        <div class="pc-stats">
          <span><b>{{ p.open_task_count }}</b> açıq</span>
          <span><b>{{ p.done_task_count }}</b> bitib</span>
          <span><b>{{ p.task_count }}</b> cəmi</span>
        </div>
        <div class="progress-line"><div :style="{ width: pct(p) + '%' }"></div></div>
        <small class="muted">{{ pct(p) }}% tamamlanıb</small>
      </RouterLink>
    </TransitionGroup>

    <AppModal :show="modalOpen" :title="editing ? 'Proyekti redaktə et' : 'Yeni proyekt'" @close="modalOpen = false">
      <form class="form" @submit.prevent="save">
        <label>Ad <input v-model="form.name" required maxlength="255" /></label>
        <label>Təsvir <textarea v-model="form.description" rows="3"></textarea></label>
        <label>
          Rəng
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
        <button class="btn ghost" @click="modalOpen = false">Ləğv et</button>
        <button class="btn primary" :disabled="!form.name.trim()" @click="save">Yadda saxla</button>
      </template>
    </AppModal>
  </div>
</template>
