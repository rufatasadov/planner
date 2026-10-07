<script setup>
import { computed } from 'vue';
import { fmtMin } from '../utils/time';

const props = defineProps({
  modelValue: Number,
  min: { type: Number, default: 0 },
  max: { type: Number, default: 1440 },
  step: { type: Number, default: 5 },
});
const emit = defineEmits(['update:modelValue']);

const options = computed(() => {
  const list = [];
  for (let m = props.min; m <= props.max; m += props.step) list.push(m);
  if (props.modelValue != null && !list.includes(props.modelValue)) list.push(props.modelValue);
  return list.sort((a, b) => a - b);
});
</script>

<template>
  <select :value="modelValue" @change="emit('update:modelValue', Number($event.target.value))">
    <option v-for="m in options" :key="m" :value="m">{{ fmtMin(m) }}</option>
  </select>
</template>
