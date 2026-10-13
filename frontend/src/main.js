import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router';
import './theme';
import './style.css';

const app = createApp(App).use(createPinia()).use(router);

// Error reporting is enabled only when the build has VITE_SENTRY_DSN; the SDK is loaded lazily.
if (import.meta.env.VITE_SENTRY_DSN) {
  import('@sentry/vue').then((Sentry) => {
    Sentry.init({
      app,
      dsn: import.meta.env.VITE_SENTRY_DSN,
      environment: import.meta.env.MODE,
      integrations: [Sentry.browserTracingIntegration({ router })],
      tracesSampleRate: 0.1,
      sendDefaultPii: false,
    });
  });
}

app.mount('#app');
