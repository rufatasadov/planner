import { defineStore } from 'pinia';
import api from '../api';

export const useSettingsStore = defineStore('settings', {
  state: () => ({
    work_start_min: 540,
    work_end_min: 1440,
    notify_before_min: 10,
    loaded: false,
  }),
  actions: {
    async load(force = false) {
      if (this.loaded && !force) return;
      const { data } = await api.get('/settings');
      Object.assign(this, data, { loaded: true });
    },
    async save(values) {
      const { data } = await api.put('/settings', values);
      Object.assign(this, data);
    },
  },
});
