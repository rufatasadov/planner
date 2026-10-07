<script setup>
defineProps({
  show: Boolean,
  title: String,
  width: { type: String, default: '480px' },
});
const emit = defineEmits(['close']);
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="modal-backdrop" @mousedown.self="emit('close')">
        <div class="modal" :style="{ maxWidth: width }">
          <div class="modal-head">
            <h3>{{ title }}</h3>
            <button class="icon-btn" @click="emit('close')">✕</button>
          </div>
          <div class="modal-body"><slot /></div>
          <div v-if="$slots.footer" class="modal-foot"><slot name="footer" /></div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
