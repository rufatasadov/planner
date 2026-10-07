import { defineStore } from 'pinia';
import api from '../api';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('token'),
    user: JSON.parse(localStorage.getItem('user') || 'null'),
  }),
  actions: {
    setSession({ token, user }) {
      this.token = token;
      this.user = user;
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
    },
    async login(email, password) {
      const { data } = await api.post('/auth/login', { email, password });
      this.setSession(data);
    },
    async register(name, email, password) {
      const { data } = await api.post('/auth/register', { name, email, password });
      this.setSession(data);
    },
    async fetchMe() {
      const { data } = await api.get('/auth/me');
      this.user = data;
      localStorage.setItem('user', JSON.stringify(data));
    },
    logout() {
      this.token = null;
      this.user = null;
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    },
  },
});
