import { ref } from 'vue';

const now = ref(new Date());
let timer = null;

export function useNow() {
  if (!timer) timer = setInterval(() => (now.value = new Date()), 1000);
  return now;
}
