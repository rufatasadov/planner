import { ref } from 'vue';
import az from './az';
import en from './en';
import ru from './ru';

const messages = { az, en, ru };

export const LOCALES = [
  { code: 'az', label: 'AZ', name: 'Azərbaycanca' },
  { code: 'en', label: 'EN', name: 'English' },
  { code: 'ru', label: 'RU', name: 'Русский' },
];

function detect() {
  const saved = localStorage.getItem('locale');
  if (messages[saved]) return saved;
  const nav = (navigator.language || '').slice(0, 2);
  return messages[nav] ? nav : 'az';
}

export const locale = ref(detect());
document.documentElement.lang = locale.value;

export function setLocale(code) {
  if (!messages[code]) return;
  locale.value = code;
  localStorage.setItem('locale', code);
  document.documentElement.lang = code;
}

const lookup = (dict, key) => key.split('.').reduce((o, k) => o?.[k], dict);

/** Raw message value (strings, arrays, ...) for the current locale. */
export function tm(key) {
  return lookup(messages[locale.value], key) ?? lookup(messages.az, key);
}

export function t(key, params = {}) {
  const value = tm(key);
  if (typeof value !== 'string') return key;
  return value.replace(/\{(\w+)\}/g, (_, k) => params[k] ?? '');
}
