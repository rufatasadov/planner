import { defineStore } from 'pinia';

let seq = 0;

export const useToast = defineStore('toast', {
  state: () => ({ items: [] }),
  actions: {
    push({ type = 'info', title, body = '', timeout = 4000 }) {
      const id = ++seq;
      this.items.push({ id, type, title, body });
      if (timeout) setTimeout(() => this.remove(id), timeout);
    },
    success(title, body) {
      this.push({ type: 'success', title, body });
    },
    error(title, body) {
      this.push({ type: 'error', title, body, timeout: 6000 });
    },
    remove(id) {
      this.items = this.items.filter((t) => t.id !== id);
    },
  },
});
