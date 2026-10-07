import { ref } from 'vue';

const prefersLight = window.matchMedia?.('(prefers-color-scheme: light)').matches;

export const theme = ref(localStorage.getItem('theme') || (prefersLight ? 'light' : 'dark'));
document.documentElement.dataset.theme = theme.value;

export function setTheme(value) {
  theme.value = value;
  localStorage.setItem('theme', value);
  document.documentElement.dataset.theme = value;
}

export const toggleTheme = () => setTheme(theme.value === 'dark' ? 'light' : 'dark');
