<script setup>
import { reactive, ref, onMounted } from 'vue';
import { useSettingsStore } from '../stores/settings';
import { useToast } from '../stores/toast';
import { errMsg, notifyPlansChanged } from '../api';
import { showNotification } from '../composables/useNotifier';
import { fmtDuration } from '../utils/time';
import TimeSelect from '../components/TimeSelect.vue';

const settings = useSettingsStore();
const toast = useToast();
const form = reactive({ work_start_min: 540, work_end_min: 1440, notify_before_min: 10 });
const permission = ref('Notification' in window ? Notification.permission : 'unsupported');

onMounted(async () => {
  await settings.load();
  Object.assign(form, {
    work_start_min: settings.work_start_min,
    work_end_min: settings.work_end_min,
    notify_before_min: settings.notify_before_min,
  });
});

async function save() {
  try {
    await settings.save({ ...form });
    notifyPlansChanged();
    toast.success('Ayarlar yadda saxlanıldı');
  } catch (e) {
    toast.error('Yadda saxlanmadı', errMsg(e));
  }
}

async function requestPermission() {
  permission.value = await Notification.requestPermission();
}

const PERMISSION_TEXT = {
  granted: 'İcazə verilib ✅',
  denied: 'Bloklanıb — brauzer ayarlarından icazə verin',
  default: 'Hələ icazə verilməyib',
  unsupported: 'Brauzer dəstəkləmir',
};
</script>

<template>
  <div class="settings-page">
    <section class="page-head"><h1>Ayarlar</h1></section>

    <form class="card form" @submit.prevent="save">
      <h3>İş saatları</h3>
      <p class="muted">Günlük plan yalnız bu aralıqda tərtib olunur.</p>
      <div class="row">
        <label>Başlama <TimeSelect v-model="form.work_start_min" :min="0" :max="1425" :step="15" /></label>
        <label>Bitmə <TimeSelect v-model="form.work_end_min" :min="15" :max="1440" :step="15" /></label>
      </div>
      <p v-if="form.work_end_min > form.work_start_min" class="hint">
        İş günü: {{ fmtDuration(form.work_end_min - form.work_start_min) }}
      </p>
      <p v-else class="error-text">Bitmə vaxtı başlamadan sonra olmalıdır</p>

      <h3>Bildirişlər</h3>
      <label>
        Planın bitməsinə neçə dəqiqə qalmış xəbərdarlıq edilsin
        <div class="range-row">
          <input v-model.number="form.notify_before_min" type="range" min="0" max="60" step="1" />
          <b>{{ form.notify_before_min }} dəq</b>
        </div>
      </label>
      <div class="perm">
        <span>Brauzer bildirişləri: <b>{{ PERMISSION_TEXT[permission] }}</b></span>
        <button v-if="permission === 'default'" type="button" class="btn ghost sm" @click="requestPermission">
          İcazə ver
        </button>
        <button
          type="button"
          class="btn ghost sm"
          @click="showNotification('Test bildirişi', `Plan bitməsinə ${form.notify_before_min} dəq qaldı`)"
        >
          Test et
        </button>
      </div>

      <div class="form-actions">
        <button class="btn primary" :disabled="form.work_end_min <= form.work_start_min">Yadda saxla</button>
      </div>
    </form>
  </div>
</template>
