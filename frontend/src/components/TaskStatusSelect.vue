<script setup>
import { computed } from 'vue';
import { STATUSES, statusMeta } from '../utils/status';
import { t } from '../i18n';

const props = defineProps({ modelValue: String });
const emit = defineEmits(['update:modelValue']);
const meta = computed(() => statusMeta(props.modelValue));
</script>

<template>
  <select
    class="status-select"
    :style="{ '--s': meta.color }"
    :value="modelValue"
    @change="emit('update:modelValue', $event.target.value)"
  >
    <option v-for="s in STATUSES" :key="s.value" :value="s.value">{{ t(`status.${s.value}`) }}</option>
  </select>
</template>
