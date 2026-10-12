<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { renderMarkdown } from '../utils/markdown';
import { t } from '../i18n';

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: String,
  autofocus: Boolean,
  rows: { type: Number, default: 6 },
});
const emit = defineEmits(['update:modelValue', 'submit', 'cancel']);

const ta = ref(null);
const mode = ref('write');
const preview = computed(() => renderMarkdown(props.modelValue));

onMounted(() => props.autofocus && ta.value?.focus());
watch(
  () => props.modelValue,
  (v) => !v && (mode.value = 'write'),
);

function apply(next, selStart, selEnd) {
  emit('update:modelValue', next);
  nextTick(() => {
    ta.value.focus();
    ta.value.setSelectionRange(selStart, selEnd);
  });
}

function wrap(before, after = before, placeholder = '') {
  const { selectionStart: s, selectionEnd: e, value } = ta.value;
  const sel = value.slice(s, e) || placeholder;
  apply(value.slice(0, s) + before + sel + after + value.slice(e), s + before.length, s + before.length + sel.length);
}

function prefixLines(prefix) {
  const { selectionStart: s, selectionEnd: e, value } = ta.value;
  const start = value.lastIndexOf('\n', s - 1) + 1;
  const lines = value.slice(start, e).split('\n');
  const block = lines.map((line, i) => (typeof prefix === 'function' ? prefix(i) : prefix) + line).join('\n');
  apply(value.slice(0, start) + block + value.slice(e), start + block.length, start + block.length);
}

function codeBlock() {
  const { selectionStart: s, value } = ta.value;
  const lead = s > 0 && value[s - 1] !== '\n' ? '\n' : '';
  wrap(`${lead}\`\`\`\n`, '\n```\n', 'code');
}

const TOOLS = [
  { key: 'bold', label: 'B', run: () => wrap('**', '**', 'text') },
  { key: 'italic', label: 'I', run: () => wrap('*', '*', 'text') },
  { key: 'strike', label: 'S', run: () => wrap('~~', '~~', 'text') },
  { key: 'heading', label: 'H', run: () => prefixLines('### ') },
  { key: 'list', label: '•', run: () => prefixLines('- ') },
  { key: 'numbered', label: '1.', run: () => prefixLines((i) => `${i + 1}. `) },
  { key: 'checklist', label: '☑', run: () => prefixLines('- [ ] ') },
  { key: 'quote', label: '❝', run: () => prefixLines('> ') },
  { key: 'code', label: '</>', run: () => wrap('`', '`', 'code') },
  { key: 'codeBlock', label: '{ }', run: codeBlock },
  { key: 'link', label: '🔗', run: () => wrap('[', '](https://)', 'link') },
];

// Enter inside a list continues it; Enter on an empty item ends the list.
function continueList(e) {
  const { selectionStart: s, selectionEnd: end, value } = ta.value;
  if (s !== end) return;
  const start = value.lastIndexOf('\n', s - 1) + 1;
  const line = value.slice(start, s);
  const m = line.match(/^(\s*)([-*] \[[ xX]\] |[-*] |(\d+)\. )/);
  if (!m) return;
  e.preventDefault();
  if (line.trim() === m[0].trim()) {
    apply(value.slice(0, start) + value.slice(s), start, start);
    return;
  }
  const marker = m[3] ? `${Number(m[3]) + 1}. ` : m[2].replace(/\[[xX]\]/, '[ ]');
  const insert = `\n${m[1]}${marker}`;
  apply(value.slice(0, s) + insert + value.slice(s), s + insert.length, s + insert.length);
}

function onKeydown(e) {
  const mod = e.metaKey || e.ctrlKey;
  if (mod && e.key === 'Enter') {
    e.preventDefault();
    emit('submit');
  } else if (e.key === 'Escape') {
    emit('cancel');
  } else if (mod && e.key.toLowerCase() === 'b') {
    e.preventDefault();
    TOOLS[0].run();
  } else if (mod && e.key.toLowerCase() === 'i') {
    e.preventDefault();
    TOOLS[1].run();
  } else if (e.key === 'Enter' && !e.shiftKey) {
    continueList(e);
  }
}
</script>

<template>
  <div class="md-editor">
    <div class="md-toolbar">
      <div class="tabs inline md-tabs">
        <button type="button" :class="{ active: mode === 'write' }" @click="mode = 'write'">{{ t('notes.write') }}</button>
        <button type="button" :class="{ active: mode === 'preview' }" @click="mode = 'preview'">{{ t('notes.preview') }}</button>
      </div>
      <div v-if="mode === 'write'" class="md-tools">
        <button
          v-for="tool in TOOLS"
          :key="tool.key"
          type="button"
          class="md-tool"
          :class="tool.key"
          :title="t(`notes.toolbar.${tool.key}`)"
          @mousedown.prevent
          @click="tool.run"
        >
          {{ tool.label }}
        </button>
      </div>
    </div>
    <textarea
      v-show="mode === 'write'"
      ref="ta"
      :value="modelValue"
      :rows="rows"
      :placeholder="placeholder"
      @input="emit('update:modelValue', $event.target.value)"
      @keydown="onKeydown"
    ></textarea>
    <div v-if="mode === 'preview'" class="md md-preview">
      <div v-if="modelValue.trim()" v-html="preview"></div>
      <p v-else class="muted">{{ t('notes.previewEmpty') }}</p>
    </div>
    <div class="md-hint muted small">{{ t('notes.hint') }}</div>
  </div>
</template>
