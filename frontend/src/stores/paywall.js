import { defineStore } from 'pinia';

// reason: 'projects' | 'history' | null (generic upgrade)
export const usePaywall = defineStore('paywall', {
  state: () => ({ open: false, reason: null }),
  actions: {
    show(reason = null) {
      this.reason = reason;
      this.open = true;
    },
    close() {
      this.open = false;
    },
  },
});
