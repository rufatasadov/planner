import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from './stores/auth';

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to, _from, saved) {
    if (saved) return saved;
    if (to.hash) return { el: to.hash, behavior: 'smooth', top: 72 };
    return { top: 0 };
  },
  routes: [
    { path: '/login', component: () => import('./views/LoginView.vue'), meta: { public: true } },
    { path: '/checkout', component: () => import('./views/CheckoutView.vue'), meta: { public: true, site: true } },
    { path: '/forgot-password', component: () => import('./views/ForgotPasswordView.vue'), meta: { public: true, site: true } },
    { path: '/reset-password', component: () => import('./views/ResetPasswordView.vue'), meta: { public: true, site: true } },
    { path: '/verify-email', component: () => import('./views/VerifyEmailView.vue'), meta: { public: true, site: true } },
    { path: '/pricing', component: () => import('./views/PricingView.vue'), meta: { public: true, site: true } },
    ...['terms', 'privacy', 'refund'].map((doc) => ({
      path: `/${doc}`,
      component: () => import('./views/LegalView.vue'),
      props: { doc },
      meta: { public: true, site: true },
    })),
    // Daily plan when signed in, landing page otherwise.
    { path: '/', component: () => import('./views/HomeView.vue'), meta: { public: true } },
    { path: '/projects', component: () => import('./views/ProjectsView.vue') },
    { path: '/projects/:id', component: () => import('./views/ProjectDetailView.vue'), props: true },
    { path: '/notes', component: () => import('./views/NotesView.vue') },
    { path: '/settings', component: () => import('./views/SettingsView.vue') },
    { path: '/admin', component: () => import('./views/AdminView.vue'), meta: { admin: true } },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
});

router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (!to.meta.public && !auth.token) return '/login';
  if (to.path === '/login' && auth.token) return '/';
  if (to.meta.admin) {
    // Sessions saved before the admin flag existed have no is_admin yet.
    if (auth.user?.is_admin === undefined) await auth.fetchMe().catch(() => {});
    if (!auth.user?.is_admin) return '/';
  }
});

export default router;
