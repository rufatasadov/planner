<script setup>
import AppModal from './AppModal.vue';
import { fmtMin } from '../utils/time';

defineProps({
  show: Boolean,
  delta: Number, // minutes the plan's end moved
  following: { type: Array, default: () => [] },
});
const emit = defineEmits(['close', 'choose']);
</script>

<template>
  <AppModal :show="show" title="Sonrakı planlar nə olsun?" width="520px" @close="emit('close')">
    <p>
      Planın bitmə vaxtı <b>{{ delta > 0 ? '+' : '' }}{{ delta }} dəq</b> dəyişir. Ondan sonra
      <b>{{ following.length }}</b> plan var:
    </p>
    <ul class="mini-list">
      <li v-for="p in following" :key="p.id">
        <span class="dot" :style="{ background: p.project_color }"></span>
        {{ p.project_name }} — {{ fmtMin(p.start_min) }}-{{ fmtMin(p.end_min) }}
      </li>
    </ul>
    <div class="choice-list">
      <button class="choice" @click="emit('choose', 'all')">
        <b>Bütün sonrakı planları sürüşdür</b>
        <span>Hamısı {{ Math.abs(delta) }} dəq {{ delta > 0 ? 'irəli' : 'geri' }} çəkilir, müddətləri dəyişmir.</span>
      </button>
      <button class="choice" @click="emit('choose', 'next')">
        <b>Yalnız növbəti planı dəyiş</b>
        <span>Növbəti planın başlanğıcı bu planın yeni bitmə vaxtına uyğunlaşır, qalanlar yerində qalır.</span>
      </button>
      <button class="choice" @click="emit('choose', 'none')">
        <b>Heç birini dəyişmə</b>
        <span>Yalnız bu plan dəyişir (kəsişmə olarsa xəta veriləcək).</span>
      </button>
    </div>
  </AppModal>
</template>
