import axios from 'axios';
import { locale, t } from './i18n';

const api = axios.create({ baseURL: import.meta.env.VITE_API_URL || '/api/v1' });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  config.headers['Accept-Language'] = locale.value;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && !err.config.url.startsWith('/auth/')) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  },
);

export const errMsg = (e) => e?.response?.data?.error || e?.message || t('common.error');

export const notifyPlansChanged = () => window.dispatchEvent(new Event('plans-changed'));

export default api;
